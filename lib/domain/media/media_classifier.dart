import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../core/config.dart';
import '../../data/db/queue_database.dart';

class ClassifiedMedia {
  ClassifiedMedia({
    required this.primaryPath,
    this.pairedPath,
    required this.kind,
    required this.size,
    required this.mtime,
    required this.title,
    required this.idempotencyKey,
    this.skipReason,
  });

  final String primaryPath;
  final String? pairedPath;
  final String kind;
  final int size;
  final DateTime mtime;
  final String title;
  final String idempotencyKey;
  final String? skipReason;

  bool get skipped => skipReason != null;
}

class MediaClassifier {
  static String normalizePath(String path) => p.normalize(path);

  static String idempotencyKeyFor({
    required String path,
    required int size,
    required DateTime mtime,
  }) {
    final raw = '${normalizePath(path)}|$size|${mtime.millisecondsSinceEpoch}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  static String titleFromPath(String path) {
    final name = p.basenameWithoutExtension(path);
    if (name.length <= 100) return name;
    return name.substring(0, 100);
  }

  static String? kindForExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    if (ext == '.lrv') return null;
    if (AppConfig.skipExtensions.contains(ext) && ext != '.lrv') return null;
    if (ext == '.insv') return MediaKind.insv;
    if (ext == '.insp') return MediaKind.insp;
    if (AppConfig.imageExtensions.contains(ext)) return MediaKind.image;
    if (AppConfig.videoExtensions.contains(ext)) return MediaKind.video;
    return null;
  }

  static bool isLrv(String path) => p.extension(path).toLowerCase() == '.lrv';

  static bool isSecondLensFile(String path) {
    return _lensToken(p.basename(path)) == '10';
  }

  static String? pairForPrimary(String primaryPath, List<String> allPaths) {
    final name = p.basename(primaryPath);
    final token = _lensToken(name);
    if (token != '00') return null;
    final expected = name.replaceFirst('_00_', '_10_').replaceFirst('_00.', '_10.');
    for (final candidate in allPaths) {
      if (p.basename(candidate) == expected) return candidate;
    }
    return null;
  }

  static String? _lensToken(String basename) {
    final match = RegExp(r'_(00|10)(?:_|\.)').firstMatch(basename);
    return match?.group(1);
  }

  static List<ClassifiedMedia> classifyFiles(List<FileSystemEntity> entities) {
    final files = entities.whereType<File>().map((f) => normalizePath(f.path)).toList()..sort();
    final byName = {for (final f in files) p.basename(f): f};
    final used = <String>{};
    final out = <ClassifiedMedia>[];

    for (final path in files) {
      if (used.contains(path)) continue;
      if (isLrv(path)) {
        out.add(_skipped(path, 'LRV proxy files are skipped.'));
        used.add(path);
        continue;
      }
      final kind = kindForExtension(path);
      if (kind == null) continue;

      if (kind == MediaKind.insv && isSecondLensFile(path)) {
        final primaryName = p.basename(path).replaceFirst('_10_', '_00_').replaceFirst('_10.', '_00.');
        if (byName.containsKey(primaryName)) {
          continue;
        }
        out.add(_skipped(path, 'Orphan Insta360 _10_ lens file without matching _00_.'));
        used.add(path);
        continue;
      }

      final file = File(path);
      final stat = file.statSync();
      String? paired;
      if (kind == MediaKind.insv) {
        paired = pairForPrimary(path, files);
        if (paired != null) used.add(paired);
      }
      used.add(path);
      out.add(
        ClassifiedMedia(
          primaryPath: path,
          pairedPath: paired,
          kind: kind,
          size: stat.size,
          mtime: stat.modified.toUtc(),
          title: titleFromPath(path),
          idempotencyKey: idempotencyKeyFor(path: path, size: stat.size, mtime: stat.modified.toUtc()),
        ),
      );
    }
    return out;
  }

  static ClassifiedMedia _skipped(String path, String reason) {
    final file = File(path);
    final stat = file.existsSync() ? file.statSync() : null;
    final size = stat?.size ?? 0;
    final mtime = stat?.modified.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return ClassifiedMedia(
      primaryPath: path,
      kind: MediaKind.insv,
      size: size,
      mtime: mtime,
      title: titleFromPath(path),
      idempotencyKey: idempotencyKeyFor(path: path, size: size, mtime: mtime),
      skipReason: reason,
    );
  }
}
