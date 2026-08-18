import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/app_paths.dart';
import '../../core/config.dart';
import '../../core/logger.dart';
import '../../data/db/queue_database.dart';
import 'ffmpeg_service.dart';
import 'spherical.dart';
import 'stitch_service.dart';

class PreparedMedia {
  PreparedMedia({
    required this.path,
    required this.contentType,
    required this.size,
    required this.spherical,
  });

  final String path;
  final String contentType;
  final int size;
  final bool spherical;
}

class MediaPreparer {
  MediaPreparer({
    required this.paths,
    required this.ffmpeg,
    required this.stitcher,
  });

  final AppPaths paths;
  final FfmpegService ffmpeg;
  final StitchService stitcher;

  Future<PreparedMedia> prepare({
    required QueueJob job,
    required void Function(int progress, String label) onProgress,
  }) async {
    switch (job.mediaKind) {
      case MediaKind.image:
        onProgress(10, 'Converting image to video');
        final out = p.join(paths.prepareDir.path, '${job.id}.mp4');
        await ffmpeg.stillImageToMp4(inputPath: job.sourcePath, outputPath: out);
        return _finish(out, spherical: false);
      case MediaKind.insp:
        onProgress(5, 'Stitching Insta360 photo');
        final stitched = await stitcher.stitch(
          inputs: [job.sourcePath],
          onProgress: (value) => onProgress(value, 'Stitching photo'),
          image: true,
        );
        // stitch() intentionally skips spherical injection for images — the
        // equirect frame here is still a plain JPG, and MP4 spherical boxes
        // don't apply until it's actually an MP4. That conversion happens
        // next, so injection has to happen after it, not before — this step
        // was previously missing entirely, so every Insta360-photo upload
        // silently went out as a flat video with no 360 metadata at all.
        onProgress(80, 'Converting stitched photo to video');
        final rawOut = p.join(paths.prepareDir.path, '${job.id}.raw.mp4');
        await ffmpeg.stillImageToMp4(inputPath: stitched, outputPath: rawOut);
        onProgress(95, 'Tagging 360 metadata');
        final out = p.join(paths.prepareDir.path, '${job.id}.mp4');
        try {
          await SphericalMetadata.inject(inputPath: rawOut, outputPath: out);
          await SphericalMetadata.verifyOrThrow(out);
        } finally {
          if (await File(rawOut).exists()) await File(rawOut).delete();
        }
        return _finish(out, spherical: true);
      case MediaKind.insv:
        onProgress(5, 'Stitching Insta360 video');
        final inputs = [job.sourcePath, if (job.pairedPath != null) job.pairedPath!];
        final stitched = await stitcher.stitch(
          inputs: inputs,
          onProgress: (value) => onProgress(value, 'Stitching'),
        );
        return _finish(stitched, spherical: true);
      default:
        onProgress(20, 'Checking video');
        final spherical = await SphericalMetadata.hasSpherical(job.sourcePath);
        return _finish(job.sourcePath, spherical: spherical);
    }
  }

  Future<PreparedMedia> _finish(String path, {required bool spherical}) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('Prepared media is missing: $path');
    }
    final size = await file.length();
    if (size > AppConfig.maxMediaBytes) {
      throw StateError(
        'Zernio media limit is 5 GB after prepare. This file is ${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB.',
      );
    }
    if (size == 0) {
      throw StateError('Prepared media is empty.');
    }
    final type = _contentType(path);
    appLog.info('Prepared $path size=$size spherical=$spherical');
    return PreparedMedia(path: path, contentType: type, size: size, spherical: spherical);
  }

  String _contentType(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.mov':
        return 'video/quicktime';
      case '.webm':
        return 'video/webm';
      case '.avi':
        return 'video/x-msvideo';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      default:
        return 'video/mp4';
    }
  }
}
