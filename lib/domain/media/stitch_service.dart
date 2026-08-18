import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../core/app_paths.dart';
import '../../core/config.dart';
import '../../core/disk_space.dart';
import '../../core/logger.dart';
import 'ffmpeg_service.dart';
import 'insv_layout.dart';
import 'spherical.dart';

class StitchCapability {
  StitchCapability({
    required this.available,
    required this.reason,
  });

  final bool available;
  final String reason;
}

class StitchService {
  StitchService({
    required this.paths,
    required this.ffmpeg,
  });

  final AppPaths paths;
  final FfmpegService ffmpeg;

  Future<StitchCapability> probe() async {
    try {
      await ffmpeg.resolveBinary();
    } catch (e) {
      return StitchCapability(available: false, reason: e.toString());
    }
    try {
      await ffmpeg.resolveFfprobe();
    } catch (e) {
      return StitchCapability(available: false, reason: e.toString());
    }
    final hasV360 = await ffmpeg.hasV360();
    if (!hasV360) {
      return StitchCapability(
        available: false,
        reason: 'This ffmpeg build has no v360 filter. Install a full ffmpeg (brew/gyan), not a slim binary.',
      );
    }
    return StitchCapability(
      available: true,
      reason:
          'ffmpeg 360 stitcher ready. Geometric dual-fisheye remap; seam can show and there is no FlowState gyro.',
    );
  }

  Future<String> stitch({
    required List<String> inputs,
    required void Function(int progress) onProgress,
    bool image = false,
  }) async {
    final cap = await probe();
    if (!cap.available) {
      throw StateError(cap.reason);
    }
    final inputFiles = inputs.map(File.new).toList();
    for (final file in inputFiles) {
      if (!file.existsSync()) {
        throw StateError('Missing Insta360 file: ${file.path}');
      }
    }
    final totalSize = inputFiles.fold<int>(0, (sum, f) => sum + f.lengthSync());
    await DiskSpace.ensureFree(
      path: paths.stitchCache.path,
      requiredBytes: DiskSpace.stitchReserve(totalSize),
    );
    final cacheName = _cacheKey(inputs, image: image);
    final ext = image ? 'jpg' : 'mp4';
    final cached = File(p.join(paths.stitchCache.path, '$cacheName.$ext'));
    if (await cached.exists() && await cached.length() > 0) {
      if (image || await SphericalMetadata.hasSpherical(cached.path)) {
        onProgress(100);
        return cached.path;
      }
    }
    final partial = File(p.join(paths.stitchCache.path, '$cacheName.partial.$ext'));
    if (await partial.exists()) {
      await partial.delete();
    }

    final streams = await ffmpeg.probeVideoStreams(inputs.first);
    final layout = InsvLayout.decide(
      primary: streams,
      hasPairedFile: inputs.length >= 2,
    );
    if (!layout.supported) {
      throw StateError(
        'Cannot stitch this Insta360 file automatically. Need dual video streams, a _00/_10 pair, or a side-by-side dual-fisheye frame.',
      );
    }
    appLog.info('Stitch layout=${layout.kind.name} ${layout.outWidth}x${layout.outHeight}');
    onProgress(1);
    final duration = image ? null : await ffmpeg.probeDuration(inputs.first);
    await ffmpeg.stitchEquirect(
      inputs: inputs,
      outputPath: partial.path,
      layout: layout,
      fov: AppConfig.stitchFovDegrees,
      image: image,
      duration: duration,
      onProgress: onProgress,
    );

    final injected = File(p.join(paths.stitchCache.path, '$cacheName.$ext'));
    if (image) {
      if (injected.existsSync()) await injected.delete();
      await partial.rename(injected.path);
      onProgress(100);
      return injected.path;
    }
    try {
      await SphericalMetadata.inject(inputPath: partial.path, outputPath: injected.path);
      await SphericalMetadata.verifyOrThrow(injected.path);
    } catch (e) {
      if (injected.existsSync()) await injected.delete();
      if (partial.existsSync()) await partial.delete();
      throw StateError('Stitched file failed 360 metadata injection: $e');
    }
    if (partial.existsSync()) await partial.delete();
    onProgress(100);
    return injected.path;
  }

  String _cacheKey(List<String> inputs, {required bool image}) {
    final parts = <String>[];
    for (final path in inputs) {
      final stat = File(path).statSync();
      parts.add('${p.normalize(path)}|${stat.size}|${stat.modified.millisecondsSinceEpoch}');
    }
    parts.add(AppConfig.stitchSettingsId);
    parts.add(image ? 'image' : 'video');
    return sha256.convert(utf8.encode(parts.join('||'))).toString();
  }
}
