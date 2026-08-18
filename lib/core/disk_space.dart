import 'dart:io';
import 'dart:math';

class DiskSpace {
  static Future<int> freeBytesFor(String path) async {
    if (Platform.isWindows) {
      return _windowsFree(path);
    }
    return _posixFree(path);
  }

  static Future<void> ensureFree({
    required String path,
    required int requiredBytes,
  }) async {
    final free = await freeBytesFor(path);
    if (free < requiredBytes) {
      throw DiskSpaceException(
        'Not enough free disk space. Need ${_gb(requiredBytes)}, have ${_gb(free)}.',
      );
    }
  }

  static Future<int> _posixFree(String path) async {
    final result = await Process.run('df', ['-Pk', path]);
    if (result.exitCode != 0) {
      throw DiskSpaceException('Could not check disk space: ${result.stderr}');
    }
    final lines = result.stdout.toString().trim().split('\n');
    if (lines.length < 2) {
      throw DiskSpaceException('Unexpected df output.');
    }
    final parts = lines.last.trim().split(RegExp(r'\s+'));
    // Filesystem Size Used Avail Capacity Mounted
    final availKb = int.tryParse(parts.length >= 4 ? parts[3] : '');
    if (availKb == null) {
      throw DiskSpaceException('Could not parse free space.');
    }
    return availKb * 1024;
  }

  static Future<int> _windowsFree(String path) async {
    final drive = path.length >= 2 && path[1] == ':' ? path.substring(0, 2) : 'C:';
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      '(Get-PSDrive -Name "${drive[0]}").Free',
    ]);
    if (result.exitCode != 0) {
      throw DiskSpaceException('Could not check disk space: ${result.stderr}');
    }
    final parsed = int.tryParse(result.stdout.toString().trim());
    if (parsed == null) {
      throw DiskSpaceException('Could not parse free space.');
    }
    return parsed;
  }

  static String _gb(int bytes) {
    final gb = bytes / (1024 * 1024 * 1024);
    return '${(gb * 10).round() / 10} GB';
  }

  static int stitchReserve(int inputBytes) => (inputBytes * 2) + (2 * 1024 * 1024 * 1024);
}

class DiskSpaceException implements Exception {
  DiskSpaceException(this.message);
  final String message;
  @override
  String toString() => message;
}

int clampProgress(int value) => max(0, min(100, value));
