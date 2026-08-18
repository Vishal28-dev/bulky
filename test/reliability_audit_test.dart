import 'package:bulky/core/config.dart';
import 'package:bulky/core/disk_space.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('5 GB limit is exact', () {
    expect(AppConfig.maxMediaBytes, 5 * 1024 * 1024 * 1024);
    expect(AppConfig.putTimeout, const Duration(minutes: 55));
  });

  test('stitch disk reserve is 2x input plus 2 GB', () {
    const input = 3 * 1024 * 1024 * 1024;
    expect(DiskSpace.stitchReserve(input), input * 2 + 2 * 1024 * 1024 * 1024);
  });

  test('workspace and youtube-only constants', () {
    // profileName removed — Nuke manages profiles server-side.
    expect(AppConfig.appName, 'bulky');
    expect(AppConfig.videoExtensions.contains('.insv'), isFalse);
    expect(AppConfig.skipExtensions.contains('.lrv'), isTrue);
    expect(AppConfig.stitchSettingsId, contains('ffmpeg-v360'));
    expect(AppConfig.stitchFovDegrees, 190);
  });

  test('Nuke base URL is configured', () {
    expect(AppConfig.defaultNukeBaseUrl, 'https://api.framefloww.me');
    expect(AppConfig.nukeBaseUrl, 'https://api.framefloww.me');
    expect(AppConfig.authLoginPath, '/auth/login');
    expect(AppConfig.nukeApiPrefix, '/nuke/api');
  });
}
