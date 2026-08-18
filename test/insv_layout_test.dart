import 'package:bulky/domain/media/insv_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InsvLayout', () {
    test('two video streams in one file is dual-track', () {
      final layout = InsvLayout.decide(
        primary: const [
          VideoStreamInfo(index: 0, width: 2880, height: 2880),
          VideoStreamInfo(index: 1, width: 2880, height: 2880),
        ],
      );
      expect(layout.kind, InsvLayoutKind.dualTrack);
      expect(layout.outWidth, 5760);
      expect(layout.outHeight, 2880);
      expect(layout.supported, isTrue);
    });

    test('paired _00/_10 files use the paired recipe', () {
      final layout = InsvLayout.decide(
        primary: const [VideoStreamInfo(index: 0, width: 3840, height: 3840)],
        hasPairedFile: true,
      );
      expect(layout.kind, InsvLayoutKind.paired);
      expect(layout.outWidth, 7680);
      expect(layout.outHeight, 3840);
    });

    test('single 2:1 frame is side-by-side dual fisheye', () {
      final layout = InsvLayout.decide(
        primary: const [VideoStreamInfo(index: 0, width: 5760, height: 2880)],
      );
      expect(layout.kind, InsvLayoutKind.sideBySide);
      expect(layout.lensWidth, 2880);
      expect(layout.outWidth, 5760);
      expect(layout.outHeight, 2880);
    });

    test('single square stream without a pair is unsupported', () {
      final layout = InsvLayout.decide(
        primary: const [VideoStreamInfo(index: 0, width: 1920, height: 1920)],
      );
      expect(layout.kind, InsvLayoutKind.unsupported);
      expect(layout.supported, isFalse);
    });

    test('empty streams are unsupported', () {
      final layout = InsvLayout.decide(primary: const []);
      expect(layout.supported, isFalse);
    });

    test('output dimensions are even', () {
      final layout = InsvLayout.decide(
        primary: const [VideoStreamInfo(index: 0, width: 1921, height: 1921)],
        hasPairedFile: true,
      );
      expect(layout.outWidth.isEven, isTrue);
      expect(layout.outHeight.isEven, isTrue);
    });
  });
}
