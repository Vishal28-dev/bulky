import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/app_paths.dart';
import '../../core/logger.dart';
import 'insv_layout.dart';

class FfmpegService {
  FfmpegService({this.paths});

  final AppPaths? paths;
  String? _ffmpeg;
  String? _ffprobe;

  static String binName(String stem) => Platform.isWindows ? '$stem.exe' : stem;

  void clearResolved() {
    _ffmpeg = null;
    _ffprobe = null;
  }

  Future<String> resolveBinary() async {
    if (_ffmpeg != null) return _ffmpeg!;
    for (final candidate in [
      ..._managedCandidates('ffmpeg'),
      ...await _bundledCandidates('ffmpeg'),
      ..._pathCandidates('ffmpeg'),
    ]) {
      if (await File(candidate).exists()) {
        _ffmpeg = candidate;
        return candidate;
      }
    }
    final fromPath = await _which(binName('ffmpeg'));
    if (fromPath != null) {
      _ffmpeg = fromPath;
      return fromPath;
    }
    throw StateError(
      'ffmpeg was not found. bulky downloads a full GPL build automatically on launch.',
    );
  }

  Future<String> resolveFfprobe() async {
    if (_ffprobe != null) return _ffprobe!;
    final ffmpeg = await resolveBinary();
    final probeName = binName('ffprobe');
    final beside = p.join(p.dirname(ffmpeg), probeName);
    if (await File(beside).exists()) {
      _ffprobe = beside;
      return beside;
    }
    for (final candidate in [
      ..._managedCandidates('ffprobe'),
      ...await _bundledCandidates('ffprobe'),
      ..._pathCandidates('ffprobe'),
    ]) {
      if (await File(candidate).exists()) {
        _ffprobe = candidate;
        return candidate;
      }
    }
    final fromPath = await _which(probeName);
    if (fromPath != null) {
      _ffprobe = fromPath;
      return fromPath;
    }
    throw StateError('ffprobe was not found next to ffmpeg.');
  }

  Future<bool> hasV360() async {
    try {
      final ffmpeg = await resolveBinary();
      final result = await Process.run(ffmpeg, ['-hide_banner', '-h', 'filter=v360']);
      final text = '${result.stdout}${result.stderr}'.toLowerCase();
      return text.contains('v360');
    } catch (_) {
      return false;
    }
  }

  Future<List<VideoStreamInfo>> probeVideoStreams(String path) async {
    final probe = await resolveFfprobe();
    final result = await Process.run(probe, [
      '-v',
      'error',
      '-select_streams',
      'v',
      '-show_entries',
      'stream=index,width,height',
      '-of',
      'json',
      path,
    ]);
    if (result.exitCode != 0) {
      throw StateError('ffprobe failed: ${result.stderr}');
    }
    final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
    final streams = json['streams'];
    if (streams is! List) return const [];
    return streams.whereType<Map>().map((raw) {
      final map = Map<String, dynamic>.from(raw);
      return VideoStreamInfo(
        index: int.tryParse('${map['index']}') ?? 0,
        width: int.tryParse('${map['width']}') ?? 0,
        height: int.tryParse('${map['height']}') ?? 0,
      );
    }).toList();
  }

  Future<Duration?> probeDuration(String path) async {
    final probe = await resolveFfprobe();
    final result = await Process.run(probe, [
      '-v',
      'error',
      '-show_entries',
      'format=duration',
      '-of',
      'json',
      path,
    ]);
    if (result.exitCode != 0) return null;
    final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
    final format = json['format'];
    if (format is! Map) return null;
    final seconds = double.tryParse('${format['duration']}');
    if (seconds == null || seconds <= 0) return null;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  Future<void> stillImageToMp4({
    required String inputPath,
    required String outputPath,
    int seconds = 8,
  }) async {
    final ffmpeg = await resolveBinary();
    await Directory(p.dirname(outputPath)).create(recursive: true);
    final result = await Process.run(ffmpeg, [
      '-y',
      '-loop',
      '1',
      '-i',
      inputPath,
      '-t',
      '$seconds',
      '-c:v',
      'libx264',
      // Stitched Insta360 equirectangular stills can be 12K+ wide. Every
      // frame here is byte-identical (a looped still), so libx264's default
      // preset — built for real motion, with multi-frame lookahead buffers
      // sized to the frame resolution — was allocating those buffers at
      // full 12K for content with no motion to look ahead at, spiking to
      // 15-20GB+ RAM for a single 8-second clip. `stillimage` tune skips
      // that motion analysis entirely (correct for this input, not just
      // faster), `ultrafast` keeps the encoder's own working set minimal,
      // and the width cap is a hard ceiling in case a future stitch
      // resolution is even larger.
      '-preset',
      'ultrafast',
      '-tune',
      'stillimage',
      '-pix_fmt',
      'yuv420p',
      '-vf',
      "scale='min(iw,4096)':-2",
      '-movflags',
      '+faststart',
      outputPath,
    ]);
    if (result.exitCode != 0 || !File(outputPath).existsSync()) {
      final err = result.stderr.toString().trim();
      appLog.warning('ffmpeg still-video failed: $err');
      throw StateError('Could not convert image to video: $err');
    }
  }

  Future<void> stitchEquirect({
    required List<String> inputs,
    required String outputPath,
    required InsvLayout layout,
    required int fov,
    required bool image,
    required void Function(int progress) onProgress,
    Duration? duration,
  }) async {
    final ffmpeg = await resolveBinary();
    await Directory(p.dirname(outputPath)).create(recursive: true);
    final args = _stitchArgs(
      inputs: inputs,
      outputPath: outputPath,
      layout: layout,
      fov: fov,
      image: image,
    );
    appLog.info('ffmpeg stitch ${layout.kind.name} ${inputs.join(', ')} -> $outputPath');
    final process = await Process.start(ffmpeg, args);
    final stderrBuf = StringBuffer();
    process.stderr.transform(utf8.decoder).listen((chunk) {
      stderrBuf.write(chunk);
    });
    await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
      final pct = _progressPercent(line, duration);
      if (pct != null) onProgress(pct);
    }
    final code = await process.exitCode;
    if (code != 0 || !File(outputPath).existsSync() || File(outputPath).lengthSync() == 0) {
      final err = stderrBuf.toString().trim();
      appLog.warning('ffmpeg stitch failed: $err');
      if (File(outputPath).existsSync()) await File(outputPath).delete();
      throw StateError('ffmpeg 360 stitch failed (exit $code): $err');
    }
    onProgress(100);
  }

  List<String> _stitchArgs({
    required List<String> inputs,
    required String outputPath,
    required InsvLayout layout,
    required int fov,
    required bool image,
  }) {
    final v360 =
        'v360=dfisheye:e:ih_fov=$fov:iv_fov=$fov:w=${layout.outWidth}:h=${layout.outHeight}';
    final args = <String>['-y', '-hide_banner', '-nostats', '-progress', 'pipe:1'];
    for (final input in inputs) {
      args.addAll(['-i', input]);
    }
    switch (layout.kind) {
      case InsvLayoutKind.dualTrack:
        args.addAll([
          '-filter_complex',
          '[0:v:0][0:v:1]hstack=inputs=2:shortest=1,$v360[v]',
          '-map',
          '[v]',
          if (!image) ...['-map', '0:a?'],
        ]);
      case InsvLayoutKind.paired:
        args.addAll([
          '-filter_complex',
          '[0:v:0][1:v:0]hstack=inputs=2:shortest=1,$v360[v]',
          '-map',
          '[v]',
          if (!image) ...['-map', '0:a?'],
        ]);
      case InsvLayoutKind.sideBySide:
        args.addAll([
          '-vf',
          v360,
          if (!image) ...['-map', '0:v:0', '-map', '0:a?'],
        ]);
      case InsvLayoutKind.unsupported:
        throw StateError('Unsupported Insta360 layout.');
    }
    if (image) {
      args.addAll(['-frames:v', '1', outputPath]);
      return args;
    }
    final fourK = layout.outHeight >= 2160;
    if (fourK) {
      args.addAll(['-c:v', 'libx265', '-crf', '18', '-preset', 'medium', '-tag:v', 'hvc1']);
    } else {
      args.addAll(['-c:v', 'libx264', '-crf', '16', '-preset', 'medium']);
    }
    args.addAll([
      '-pix_fmt',
      'yuv420p',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      '-movflags',
      '+faststart',
      outputPath,
    ]);
    return args;
  }

  int? _progressPercent(String line, Duration? duration) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('out_time_ms=')) return null;
    final ms = int.tryParse(trimmed.substring('out_time_ms='.length));
    if (ms == null || duration == null || duration.inMilliseconds <= 0) return null;
    final pct = ((ms / duration.inMilliseconds) * 100).round();
    if (pct < 0) return 0;
    if (pct > 99) return 99;
    return pct;
  }

  List<String> _managedCandidates(String stem) {
    final dir = paths?.ffmpegDir.path;
    if (dir == null) return const [];
    return [p.join(dir, binName(stem))];
  }

  Future<List<String>> _bundledCandidates(String stem) async {
    final exe = File(Platform.resolvedExecutable);
    final dir = exe.parent;
    final name = binName(stem);
    return [
      p.join(dir.path, name),
      p.join(dir.path, 'resources', name),
      p.normalize(p.join(dir.path, '..', 'Resources', name)),
      p.normalize(p.join(dir.path, '..', 'Resources', stem)),
    ];
  }

  List<String> _pathCandidates(String stem) {
    final name = binName(stem);
    if (Platform.isMacOS) {
      return ['/opt/homebrew/bin/$stem', '/usr/local/bin/$stem'];
    }
    if (Platform.isWindows) {
      return [r'C:\ffmpeg\bin\' + name];
    }
    return ['/usr/bin/$stem'];
  }

  Future<String?> _which(String name) async {
    final command = Platform.isWindows ? 'where' : 'which';
    final result = await Process.run(command, [name]);
    if (result.exitCode != 0) return null;
    final line = result.stdout.toString().split('\n').first.trim();
    if (line.isEmpty) return null;
    return line;
  }
}
