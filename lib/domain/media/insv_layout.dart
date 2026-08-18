enum InsvLayoutKind {
  dualTrack,
  sideBySide,
  paired,
  unsupported,
}

class VideoStreamInfo {
  const VideoStreamInfo({
    required this.index,
    required this.width,
    required this.height,
  });

  final int index;
  final int width;
  final int height;

  bool get isWide => width >= (height * 1.8);
}

class InsvLayout {
  const InsvLayout({
    required this.kind,
    required this.lensWidth,
    required this.outWidth,
    required this.outHeight,
  });

  final InsvLayoutKind kind;
  final int lensWidth;
  final int outWidth;
  final int outHeight;

  bool get supported => kind != InsvLayoutKind.unsupported;

  static int even(int value) {
    if (value < 2) return 2;
    return value - (value % 2);
  }

  /// Picks a stitch recipe from ffprobe streams. Pure so tests do not need ffmpeg.
  static InsvLayout decide({
    required List<VideoStreamInfo> primary,
    bool hasPairedFile = false,
  }) {
    if (primary.isEmpty) {
      return const InsvLayout(
        kind: InsvLayoutKind.unsupported,
        lensWidth: 0,
        outWidth: 0,
        outHeight: 0,
      );
    }
    if (hasPairedFile) {
      return _fromLens(InsvLayoutKind.paired, primary.first.width > 0 ? primary.first.width : primary.first.height);
    }
    if (primary.length >= 2) {
      final lens = primary.first.width >= primary.first.height ? primary.first.width : primary.first.height;
      return _fromLens(InsvLayoutKind.dualTrack, lens);
    }
    final stream = primary.first;
    if (stream.isWide) {
      final lens = stream.height > 0 ? stream.height : stream.width ~/ 2;
      return _fromLens(InsvLayoutKind.sideBySide, lens);
    }
    return const InsvLayout(
      kind: InsvLayoutKind.unsupported,
      lensWidth: 0,
      outWidth: 0,
      outHeight: 0,
    );
  }

  static InsvLayout _fromLens(InsvLayoutKind kind, int lensWidth) {
    final lens = even(lensWidth);
    return InsvLayout(
      kind: kind,
      lensWidth: lens,
      outWidth: even(lens * 2),
      outHeight: lens,
    );
  }
}
