import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'logger.dart';

/// Live API. Debug can override via project-root `.env`.
/// Release builds always use this unless `--dart-define=NUKE_BASE_URL=...`.
class AppEnv {
  static const String defaultNukeBaseUrl = 'https://api.nukemarketing.in';

  static Map<String, String> _file = {};

  static Future<void> load() async {
    _file = {};
    if (kReleaseMode) {
      appLog.info('Nuke API: $nukeBaseUrl (release; production default)');
      return;
    }

    final file = await _findEnvFile();
    if (file != null) {
      try {
        _file = parseEnv(await file.readAsString());
      } catch (e) {
        appLog.warning('Could not read ${file.path}: $e');
      }
    }
    appLog.info(
      'Nuke API: $nukeBaseUrl'
      '${file == null ? ' (no .env file, cwd=${Directory.current.path})' : ' (from ${file.path})'}',
    );
  }

  static String get nukeBaseUrl {
    return resolveNukeBaseUrl(
      releaseMode: kReleaseMode,
      fromDefine: const String.fromEnvironment('NUKE_BASE_URL'),
      fromProcessEnv: Platform.environment['NUKE_BASE_URL'],
      fromFile: _file['NUKE_BASE_URL'],
    );
  }

  /// Release ignores disk `.env` and process env so GitHub/zips cannot
  /// accidentally ship localhost.
  static String resolveNukeBaseUrl({
    required bool releaseMode,
    String fromDefine = '',
    String? fromProcessEnv,
    String? fromFile,
  }) {
    final defined = normalizeBaseUrl(fromDefine);
    if (defined != null) return defined;
    if (releaseMode) return defaultNukeBaseUrl;
    return normalizeBaseUrl(fromProcessEnv) ??
        normalizeBaseUrl(fromFile) ??
        defaultNukeBaseUrl;
  }

  static Map<String, String> parseEnv(String source) {
    final out = <String, String>{};
    for (final raw in source.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final eq = line.indexOf('=');
      if (eq <= 0) continue;
      final key = line.substring(0, eq).trim();
      var value = line.substring(eq + 1).trim();
      if (value.length >= 2) {
        final a = value[0];
        final b = value[value.length - 1];
        if ((a == '"' && b == '"') || (a == "'" && b == "'")) {
          value = value.substring(1, value.length - 1);
        }
      }
      out[key] = value;
    }
    return out;
  }

  static String? normalizeBaseUrl(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s.isEmpty ? null : s;
  }

  static Future<File?> _findEnvFile() async {
    final starts = <Directory>[
      Directory.current,
      File(Platform.resolvedExecutable).parent,
    ];
    for (final start in starts) {
      var dir = start;
      for (var i = 0; i < 16; i++) {
        final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
        final env = File(p.join(dir.path, '.env'));
        if (await pubspec.exists() && await env.exists()) return env;
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    }
    return null;
  }
}
