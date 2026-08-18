import 'dart:io';

class FfmpegPackage {
  const FfmpegPackage({
    required this.label,
    required this.archives,
  });

  final String label;
  final List<Uri> archives;
}

class FfmpegPackages {
  static final win64 = FfmpegPackage(
    label: 'BtbN FFmpeg GPL win64',
    archives: [
      Uri.parse(
        'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip',
      ),
    ],
  );

  static final winArm64 = FfmpegPackage(
    label: 'BtbN FFmpeg GPL winarm64',
    archives: [
      Uri.parse(
        'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-winarm64-gpl.zip',
      ),
    ],
  );

  static FfmpegPackage mac(String arch) {
    return FfmpegPackage(
      label: 'Martin Riedl FFmpeg macOS $arch',
      archives: [
        Uri.parse('https://ffmpeg.martin-riedl.de/redirect/latest/macos/$arch/release/ffmpeg.zip'),
        Uri.parse('https://ffmpeg.martin-riedl.de/redirect/latest/macos/$arch/release/ffprobe.zip'),
      ],
    );
  }

  static FfmpegPackage forOsArch({required String os, required String arch}) {
    if (os == 'windows') {
      return arch == 'arm64' ? winArm64 : win64;
    }
    if (os == 'macos') {
      return mac(arch == 'arm64' ? 'arm64' : 'amd64');
    }
    throw UnsupportedError('ffmpeg auto-install is only for Windows and macOS.');
  }

  static FfmpegPackage current() {
    final os = Platform.isWindows
        ? 'windows'
        : Platform.isMacOS
            ? 'macos'
            : Platform.operatingSystem;
    return forOsArch(os: os, arch: hostArch());
  }

  static String hostArch() {
    if (Platform.isWindows) {
      final arch = (Platform.environment['PROCESSOR_ARCHITECTURE'] ?? '').toUpperCase();
      return arch == 'ARM64' ? 'arm64' : 'x64';
    }
    final version = Platform.version.toLowerCase();
    if (version.contains('arm64') || version.contains('aarch64')) return 'arm64';
    try {
      final result = Process.runSync('uname', ['-m']);
      final machine = result.stdout.toString().trim();
      if (machine == 'arm64' || machine == 'aarch64') return 'arm64';
    } catch (_) {}
    return 'x64';
  }
}
