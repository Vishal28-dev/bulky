import 'package:bulky/core/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty NUKE_BASE_URL falls back to live nuke', () {
    expect(AppEnv.normalizeBaseUrl(''), isNull);
    expect(AppEnv.normalizeBaseUrl('   '), isNull);
  });

  test('ngrok URL is trimmed and has no trailing slash', () {
    expect(
      AppEnv.normalizeBaseUrl(' https://abc.ngrok-free.app/ '),
      'https://abc.ngrok-free.app',
    );
  });

  test('.env parser ignores comments and quoted values', () {
    final parsed = AppEnv.parseEnv('''
# comment
NUKE_BASE_URL="https://abc.ngrok-free.app/"
OTHER=nope
''');
    expect(parsed['NUKE_BASE_URL'], 'https://abc.ngrok-free.app/');
    expect(AppEnv.normalizeBaseUrl(parsed['NUKE_BASE_URL']), 'https://abc.ngrok-free.app');
  });

  test('no dart-define uses production', () {
    expect(AppEnv.defaultNukeBaseUrl, 'https://api.nukemarketing.in');
    expect(
      AppEnv.resolveNukeBaseUrl(releaseMode: false),
      'https://api.nukemarketing.in',
    );
  });

  test('release ignores disk and process env', () {
    expect(
      AppEnv.resolveNukeBaseUrl(
        releaseMode: true,
        fromProcessEnv: 'http://localhost:8080',
        fromFile: 'http://127.0.0.1:8080',
      ),
      'https://api.nukemarketing.in',
    );
  });

  test('release still honors dart-define', () {
    expect(
      AppEnv.resolveNukeBaseUrl(
        releaseMode: true,
        fromDefine: 'https://example.test',
        fromFile: 'http://localhost:8080',
      ),
      'https://example.test',
    );
  });

  test('debug can use .env', () {
    expect(
      AppEnv.resolveNukeBaseUrl(
        releaseMode: false,
        fromFile: 'http://localhost:8080',
      ),
      'http://localhost:8080',
    );
  });
}
