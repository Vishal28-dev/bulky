import 'dart:io';

import 'package:path/path.dart' as p;

import 'media_classifier.dart';

class ScanRequest {
  ScanRequest(this.rootPath);
  final String rootPath;
}

List<ClassifiedMedia> scanFolder(ScanRequest request) {
  final root = Directory(request.rootPath);
  if (!root.existsSync()) {
    throw FileSystemException('Folder does not exist', request.rootPath);
  }
  final entities = <FileSystemEntity>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final ext = p.extension(entity.path).toLowerCase();
    if (ext.isEmpty) continue;
    entities.add(entity);
  }
  return MediaClassifier.classifyFiles(entities);
}
