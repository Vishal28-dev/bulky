import 'dart:io';
import 'dart:typed_data';

import 'package:bulky/domain/media/media_classifier.dart';
import 'package:bulky/domain/media/spherical.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaClassifier', () {
    test('pairs _00 and _10 insv as one job', () {
      final dir = Directory.systemTemp.createTempSync('bulky-class-');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/VID_20240528_113402_00_032.insv').writeAsBytesSync(const [1]);
      File('${dir.path}/VID_20240528_113402_10_032.insv').writeAsBytesSync(const [2]);
      File('${dir.path}/clip.lrv').writeAsBytesSync(const [3]);
      File('${dir.path}/photo.jpg').writeAsBytesSync(const [4, 5, 6]);
      final result = MediaClassifier.classifyFiles(dir.listSync());
      final insv = result.where((c) => c.kind == 'insv' && !c.skipped).toList();
      expect(insv, hasLength(1));
      expect(insv.first.pairedPath, isNotNull);
      expect(insv.first.pairedPath, contains('_10_'));
      expect(result.where((c) => c.skipReason != null && c.primaryPath.endsWith('.lrv')), isNotEmpty);
      expect(result.where((c) => c.kind == 'image' && !c.skipped), hasLength(1));
    });

    test('does not treat orphan _10 as a primary upload', () {
      final dir = Directory.systemTemp.createTempSync('bulky-orphan-');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/VID_20240528_113402_10_032.insv').writeAsBytesSync(const [2]);
      final result = MediaClassifier.classifyFiles(dir.listSync());
      expect(result.where((c) => !c.skipped), isEmpty);
      expect(result.where((c) => c.skipped), isNotEmpty);
    });

    test('idempotency key is stable for path size mtime', () {
      final a = MediaClassifier.idempotencyKeyFor(
        path: '/Videos/clip.mp4',
        size: 100,
        mtime: DateTime.utc(2026, 1, 2, 3, 4, 5),
      );
      final b = MediaClassifier.idempotencyKeyFor(
        path: '/Videos/clip.mp4',
        size: 100,
        mtime: DateTime.utc(2026, 1, 2, 3, 4, 5),
      );
      final c = MediaClassifier.idempotencyKeyFor(
        path: '/Videos/clip.mp4',
        size: 101,
        mtime: DateTime.utc(2026, 1, 2, 3, 4, 5),
      );
      expect(a, a);
      expect(a, b);
      expect(a, isNot(c));
      expect(a.length, 64);
    });

    test('title is filename truncated to 100', () {
      final long = 'x' * 140;
      expect(MediaClassifier.titleFromPath('/tmp/$long.mp4').length, 100);
      expect(MediaClassifier.titleFromPath('/tmp/hello.mp4'), 'hello');
    });
  });

  group('SphericalMetadata', () {
    test('detects and injects spherical uuid without loading mdat', () async {
      final dir = Directory.systemTemp.createTempSync('bulky-mp4-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final input = '${dir.path}/plain.mp4';
      final output = '${dir.path}/out.mp4';
      File(input).writeAsBytesSync(_minimalMp4(mdatBytes: 4096));
      expect(await SphericalMetadata.hasSpherical(input), isFalse);
      await SphericalMetadata.inject(inputPath: input, outputPath: output);
      expect(await SphericalMetadata.hasSpherical(output), isTrue);
      expect(File(output).lengthSync(), greaterThan(File(input).lengthSync()));
    });
  });
}

Uint8List _minimalMp4({required int mdatBytes}) {
  final ftyp = _box('ftyp', [
    ..._fourcc('isom'),
    ..._u32(0),
    ..._fourcc('isom'),
  ]);
  final moov = _box('moov', [
    ..._box('mvhd', List<int>.filled(24, 0)),
  ]);
  final mdat = _box('mdat', List<int>.filled(mdatBytes, 7));
  return Uint8List.fromList([...ftyp, ...moov, ...mdat]);
}

List<int> _box(String type, List<int> payload) {
  final size = 8 + payload.length;
  return [..._u32(size), ..._fourcc(type), ...payload];
}

List<int> _fourcc(String type) => type.codeUnits;
List<int> _u32(int value) => [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
