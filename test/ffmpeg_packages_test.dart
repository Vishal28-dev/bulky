import 'package:bulky/domain/media/ffmpeg_packages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows x64 uses BtbN GPL zip with ffmpeg and ffprobe together', () {
    final pkg = FfmpegPackages.forOsArch(os: 'windows', arch: 'x64');
    expect(pkg.archives, hasLength(1));
    expect(pkg.archives.single.toString(), contains('win64-gpl.zip'));
  });

  test('Windows arm64 uses BtbN winarm64 GPL zip', () {
    final pkg = FfmpegPackages.forOsArch(os: 'windows', arch: 'arm64');
    expect(pkg.archives.single.toString(), contains('winarm64-gpl.zip'));
  });

  test('macOS arm64 uses Martin Riedl release ffmpeg and ffprobe zips', () {
    final pkg = FfmpegPackages.forOsArch(os: 'macos', arch: 'arm64');
    expect(pkg.archives, hasLength(2));
    expect(pkg.archives[0].toString(), contains('/macos/arm64/release/ffmpeg.zip'));
    expect(pkg.archives[1].toString(), contains('/macos/arm64/release/ffprobe.zip'));
  });

  test('macOS intel uses amd64 release zips', () {
    final pkg = FfmpegPackages.forOsArch(os: 'macos', arch: 'x64');
    expect(pkg.archives[0].toString(), contains('/macos/amd64/release/ffmpeg.zip'));
  });
}
