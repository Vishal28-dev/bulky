import 'dart:io';

import 'package:bulky/core/app_paths.dart';
import 'package:bulky/core/logger.dart';
import 'package:bulky/domain/media/ffmpeg_installer.dart';
import 'package:bulky/domain/media/ffmpeg_service.dart';
import 'package:bulky/domain/media/insv_layout.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  initLogging();
  final outDir = Directory(p.join(Directory.current.path, 'dist', 'live-test'));
  await outDir.create(recursive: true);

  final paths = await AppPaths.create(Directory(p.join(outDir.path, 'ffmpeg-install')));
  final ffmpeg = FfmpegService(paths: paths, allowSystem: false);
  final installer = FfmpegInstaller(paths: paths, ffmpeg: ffmpeg);

  stdout.writeln('1) Installing ffmpeg into a clean folder (no Homebrew)...');
  final installed = await installer.ensure(onUpdate: (s) {
    stdout.writeln('   ${s.message}');
  });
  if (!installed.isReady) {
    stderr.writeln('INSTALL FAILED: ${installed.error}');
    exit(1);
  }
  final bin = await ffmpeg.resolveBinary();
  stdout.writeln('   using $bin');
  if (!await ffmpeg.hasV360()) {
    stderr.writeln('v360 filter missing after install');
    exit(1);
  }
  stdout.writeln('   v360 filter: yes');

  stdout.writeln('2) Making a still image and downloading a sample video...');
  final imagePath = p.join(outDir.path, 'source.png');
  final videoPath = p.join(outDir.path, 'source.mp4');
  final stillMake = await Process.run(bin, [
    '-y',
    '-f',
    'lavfi',
    '-i',
    'color=c=0x1e90ff:s=1280x720:d=1',
    '-frames:v',
    '1',
    imagePath,
  ]);
  if (stillMake.exitCode != 0) {
    stderr.writeln('Could not create still: ${stillMake.stderr}');
    exit(1);
  }
  stdout.writeln('   ${p.basename(imagePath)} ${File(imagePath).lengthSync()} bytes');
  final curl = await Process.run('curl', [
    '-L',
    '--fail',
    '-A',
    'Mozilla/5.0',
    '-o',
    videoPath,
    'https://www.w3schools.com/html/mov_bbb.mp4',
  ]);
  if (curl.exitCode != 0 || !File(videoPath).existsSync()) {
    stderr.writeln('Could not download sample video: ${curl.stderr}');
    exit(1);
  }
  stdout.writeln('   ${p.basename(videoPath)} ${File(videoPath).lengthSync()} bytes');

  stdout.writeln('3) Rendering still image with FfmpegService.stillImageToMp4...');
  final stillOut = p.join(outDir.path, 'rendered-from-image.mp4');
  await ffmpeg.stillImageToMp4(inputPath: imagePath, outputPath: stillOut, seconds: 8);
  final stillDur = await ffmpeg.probeDuration(stillOut);
  final stillStreams = await ffmpeg.probeVideoStreams(stillOut);
  stdout.writeln(
    '   $stillOut  ${File(stillOut).lengthSync()} bytes  '
    'duration=${stillDur?.inSeconds}s  ${stillStreams.first.width}x${stillStreams.first.height}',
  );

  stdout.writeln('4) Building a dual-fisheye .insv then stitching with v360...');
  final insvPath = p.join(outDir.path, 'VID_TEST_00.insv');
  final stitchOut = p.join(outDir.path, 'rendered-from-insv.mp4');
  final make = await Process.run(bin, [
    '-y',
    '-f',
    'lavfi',
    '-i',
    'testsrc=size=640x640:rate=24:duration=2',
    '-f',
    'lavfi',
    '-i',
    'testsrc2=size=640x640:rate=24:duration=2',
    '-filter_complex',
    '[0:v][1:v]hstack=inputs=2:shortest=1[v]',
    '-map',
    '[v]',
    '-c:v',
    'libx264',
    '-pix_fmt',
    'yuv420p',
    '-f',
    'mp4',
    insvPath,
  ]);
  if (make.exitCode != 0 || !File(insvPath).existsSync()) {
    stderr.writeln('Could not create test .insv: ${make.stderr}');
    exit(1);
  }
  final insvStreams = await ffmpeg.probeVideoStreams(insvPath);
  final layout = InsvLayout.decide(primary: insvStreams);
  stdout.writeln(
    '   layout=${layout.kind.name} ${layout.outWidth}x${layout.outHeight} '
    'from ${insvStreams.first.width}x${insvStreams.first.height}',
  );
  if (!layout.supported) {
    stderr.writeln('Layout unsupported — stitch would be skipped in the app.');
    exit(1);
  }
  await ffmpeg.stitchEquirect(
    inputs: [insvPath],
    outputPath: stitchOut,
    layout: layout,
    fov: 190,
    image: false,
    duration: await ffmpeg.probeDuration(insvPath),
    onProgress: (pct) {
      if (pct == 1 || pct % 25 == 0 || pct >= 99) {
        stdout.writeln('   stitch $pct%');
      }
    },
  );
  final stitchedStreams = await ffmpeg.probeVideoStreams(stitchOut);
  stdout.writeln(
    '   $stitchOut  ${File(stitchOut).lengthSync()} bytes  '
    '${stitchedStreams.first.width}x${stitchedStreams.first.height}',
  );
  stdout.writeln('5) Downloaded sample video (app uploads this as-is): $videoPath '
      '${File(videoPath).lengthSync()} bytes');
  stdout.writeln('DONE');
}
