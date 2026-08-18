import 'dart:io';

import 'package:path/path.dart' as p;

class AppPaths {
  AppPaths(this.supportDir);

  factory AppPaths.test(Directory dir) => AppPaths(dir);

  final Directory supportDir;

  static Future<AppPaths> create(Directory support) async {
    await support.create(recursive: true);
    await Directory(p.join(support.path, 'stitch-cache')).create(recursive: true);
    await Directory(p.join(support.path, 'prepare')).create(recursive: true);
    await Directory(p.join(support.path, 'logs')).create(recursive: true);
    await Directory(p.join(support.path, 'ffmpeg')).create(recursive: true);
    return AppPaths(support);
  }

  Directory get stitchCache => Directory(p.join(supportDir.path, 'stitch-cache'));
  Directory get prepareDir => Directory(p.join(supportDir.path, 'prepare'));
  Directory get ffmpegDir => Directory(p.join(supportDir.path, 'ffmpeg'));
  File get databaseFile => File(p.join(supportDir.path, 'queue.sqlite'));
}
