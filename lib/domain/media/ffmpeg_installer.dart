import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/app_paths.dart';
import '../../core/disk_space.dart';
import '../../core/logger.dart';
import 'ffmpeg_packages.dart';
import 'ffmpeg_service.dart';

enum FfmpegInstallPhase {
  checking,
  downloading,
  extracting,
  verifying,
  ready,
  failed,
}

class FfmpegInstallState {
  const FfmpegInstallState({
    required this.phase,
    this.progress = 0,
    this.message = '',
    this.error,
  });

  final FfmpegInstallPhase phase;
  final double progress;
  final String message;
  final String? error;

  bool get isReady => phase == FfmpegInstallPhase.ready;
  bool get isFailed => phase == FfmpegInstallPhase.failed;
}

class FfmpegInstaller {
  FfmpegInstaller({
    required this.paths,
    required this.ffmpeg,
  });

  final AppPaths paths;
  final FfmpegService ffmpeg;

  Future<FfmpegInstallState> ensure({
    void Function(FfmpegInstallState state)? onUpdate,
  }) async {
    void emit(FfmpegInstallState state) => onUpdate?.call(state);

    emit(const FfmpegInstallState(
      phase: FfmpegInstallPhase.checking,
      message: 'Checking ffmpeg…',
    ));
    if (await ffmpeg.hasV360()) {
      emit(const FfmpegInstallState(
        phase: FfmpegInstallPhase.ready,
        progress: 1,
        message: 'ffmpeg is ready.',
      ));
      return const FfmpegInstallState(phase: FfmpegInstallPhase.ready, progress: 1, message: 'ffmpeg is ready.');
    }

    try {
      await DiskSpace.ensureFree(
        path: paths.ffmpegDir.path,
        requiredBytes: 400 * 1024 * 1024,
      );
      final pkg = FfmpegPackages.current();
      final downloadDir = Directory(p.join(paths.ffmpegDir.path, 'download'));
      if (downloadDir.existsSync()) {
        await downloadDir.delete(recursive: true);
      }
      await downloadDir.create(recursive: true);

      final zips = <File>[];
      for (var i = 0; i < pkg.archives.length; i++) {
        final url = pkg.archives[i];
        final dest = File(p.join(downloadDir.path, 'part-$i.zip'));
        emit(FfmpegInstallState(
          phase: FfmpegInstallPhase.downloading,
          progress: i / pkg.archives.length,
          message: 'Downloading ${pkg.label} (${i + 1}/${pkg.archives.length})…',
        ));
        await _downloadWithRetry(url, dest, (received, total) {
          final base = i / pkg.archives.length;
          final slice = 1 / pkg.archives.length;
          final part = total <= 0 ? 0.0 : received / total;
          emit(FfmpegInstallState(
            phase: FfmpegInstallPhase.downloading,
            progress: (base + part * slice).clamp(0, 0.85),
            message: 'Downloading ${pkg.label}… ${_mb(received)}${total > 0 ? ' / ${_mb(total)}' : ''}',
          ));
        });
        zips.add(dest);
      }

      emit(const FfmpegInstallState(
        phase: FfmpegInstallPhase.extracting,
        progress: 0.88,
        message: 'Extracting ffmpeg…',
      ));
      final extractDir = Directory(p.join(downloadDir.path, 'extracted'));
      await extractDir.create(recursive: true);
      for (final zip in zips) {
        await _unzip(zip, extractDir);
      }

      final ffmpegSrc = await _findBinary(extractDir, FfmpegService.binName('ffmpeg'));
      final probeSrc = await _findBinary(extractDir, FfmpegService.binName('ffprobe'));
      if (ffmpegSrc == null) {
        throw StateError('Downloaded archive did not contain ffmpeg.');
      }
      if (probeSrc == null) {
        throw StateError('Downloaded archive did not contain ffprobe.');
      }

      final ffmpegDest = File(p.join(paths.ffmpegDir.path, FfmpegService.binName('ffmpeg')));
      final probeDest = File(p.join(paths.ffmpegDir.path, FfmpegService.binName('ffprobe')));
      await _installBinary(ffmpegSrc, ffmpegDest);
      await _installBinary(probeSrc, probeDest);
      if (!Platform.isWindows) {
        await Process.run('chmod', ['755', ffmpegDest.path, probeDest.path]);
        await Process.run('xattr', ['-dr', 'com.apple.quarantine', ffmpegDest.path, probeDest.path]);
      } else {
        await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          'Unblock-File -LiteralPath "${ffmpegDest.path}"; Unblock-File -LiteralPath "${probeDest.path}"',
        ]);
      }

      emit(const FfmpegInstallState(
        phase: FfmpegInstallPhase.verifying,
        progress: 0.95,
        message: 'Verifying v360 filter…',
      ));
      ffmpeg.clearResolved();
      if (!await ffmpeg.hasV360()) {
        throw StateError('Installed ffmpeg, but the v360 filter is missing.');
      }

      try {
        await downloadDir.delete(recursive: true);
      } catch (_) {}

      const ready = FfmpegInstallState(
        phase: FfmpegInstallPhase.ready,
        progress: 1,
        message: 'ffmpeg installed.',
      );
      emit(ready);
      return ready;
    } catch (e, st) {
      appLog.warning('ffmpeg install failed', e, st);
      final failed = FfmpegInstallState(
        phase: FfmpegInstallPhase.failed,
        message: 'Could not install ffmpeg.',
        error: e.toString(),
      );
      emit(failed);
      return failed;
    }
  }

  Future<void> _downloadWithRetry(
    Uri url,
    File dest,
    void Function(int received, int total) onProgress,
  ) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        if (dest.existsSync()) await dest.delete();
        await _download(url, dest, onProgress);
        return;
      } catch (e) {
        lastError = e;
        appLog.warning('ffmpeg download attempt $attempt failed: $e');
        if (dest.existsSync()) {
          try {
            await dest.delete();
          } catch (_) {}
        }
        if (attempt < 3) {
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }
    throw lastError ?? StateError('Download failed for $url');
  }

  Future<void> _download(
    Uri url,
    File dest,
    void Function(int received, int total) onProgress,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(minutes: 2);
    client.userAgent = 'bulky/1.0 (ffmpeg installer)';
    client.maxConnectionsPerHost = 2;
    try {
      final request = await client.getUrl(url);
      request.followRedirects = true;
      request.maxRedirects = 8;
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Download failed (${response.statusCode}) for $url');
      }
      final total = response.contentLength;
      var received = 0;
      final sink = dest.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          onProgress(received, total);
        }
      } finally {
        await sink.close();
      }
      if (dest.lengthSync() < 1024 * 1024) {
        throw StateError('Downloaded file is too small: ${dest.path}');
      }
      final header = dest.openSync();
      try {
        final magic = header.readSync(4);
        final isZip = magic.length == 4 && magic[0] == 0x50 && magic[1] == 0x4b;
        if (!isZip) {
          throw StateError('Downloaded file is not a zip: $url');
        }
      } finally {
        header.closeSync();
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _installBinary(File src, File dest) async {
    if (dest.existsSync()) await dest.delete();
    await src.copy(dest.path);
  }

  Future<void> _unzip(File zip, Directory dest) async {
    if (Platform.isWindows) {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        "Expand-Archive -LiteralPath '${zip.path.replaceAll("'", "''")}' -DestinationPath '${dest.path.replaceAll("'", "''")}' -Force",
      ]);
      if (result.exitCode != 0) {
        throw StateError('Could not extract ffmpeg zip: ${result.stderr}');
      }
      return;
    }
    final result = await Process.run('unzip', ['-o', zip.path, '-d', dest.path]);
    if (result.exitCode != 0) {
      throw StateError('Could not extract ffmpeg zip: ${result.stderr}');
    }
  }

  Future<File?> _findBinary(Directory root, String name) async {
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && p.basename(entity.path).toLowerCase() == name.toLowerCase()) {
        return entity;
      }
    }
    return null;
  }

  static String _mb(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }
}
