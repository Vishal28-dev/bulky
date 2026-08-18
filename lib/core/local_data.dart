import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;

import 'app_paths.dart';
import 'config.dart';
import 'logger.dart';

/// Drops saved login / queue when the Nuke URL changes (live ↔ ngrok)
/// so bulky never shows the previous server's email, cookies, or jobs.
class LocalData {
  static File _hostMarker(AppPaths paths) => File(p.join(paths.supportDir.path, 'nuke-host.txt'));

  static Future<void> syncNukeHost(AppPaths paths) async {
    final current = AppConfig.nukeBaseUrl;
    final marker = _hostMarker(paths);
    final previous = marker.existsSync() ? marker.readAsStringSync().trim() : '';
    if (previous == current) return;
    appLog.info('Nuke host changed ($previous → $current). Clearing local app data.');
    await wipeUserData(paths);
    marker.writeAsStringSync(current);
  }

  /// Email, session cookies, queue, caches. Keeps the ffmpeg install.
  static Future<void> wipeUserData(AppPaths paths) async {
    try {
      await const FlutterSecureStorage().deleteAll();
    } catch (e) {
      appLog.warning('Could not clear saved cookies: $e');
    }
    for (final name in ['store.json', 'queue.sqlite', 'queue.sqlite-wal', 'queue.sqlite-shm']) {
      final file = File(p.join(paths.supportDir.path, name));
      if (file.existsSync()) file.deleteSync();
    }
    for (final dir in [paths.prepareDir, paths.stitchCache, Directory(p.join(paths.supportDir.path, 'logs'))]) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
    }
  }
}
