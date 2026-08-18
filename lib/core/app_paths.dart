import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPaths {
  AppPaths._(this.supportDir);

  @visibleForTesting
  factory AppPaths.test(Directory dir) => AppPaths._(dir);

  final Directory supportDir;

  static Future<AppPaths> load() async {
    final dir = await getApplicationSupportDirectory();
    final support = Directory(p.join(dir.path, 'bulky'));
    await support.create(recursive: true);
    await Directory(p.join(support.path, 'stitch-cache')).create(recursive: true);
    await Directory(p.join(support.path, 'prepare')).create(recursive: true);
    await Directory(p.join(support.path, 'logs')).create(recursive: true);
    await Directory(p.join(support.path, 'ffmpeg')).create(recursive: true);
    return AppPaths._(support);
  }

  Directory get stitchCache => Directory(p.join(supportDir.path, 'stitch-cache'));
  Directory get prepareDir => Directory(p.join(supportDir.path, 'prepare'));
  Directory get ffmpegDir => Directory(p.join(supportDir.path, 'ffmpeg'));
  File get databaseFile => File(p.join(supportDir.path, 'queue.sqlite'));
}
