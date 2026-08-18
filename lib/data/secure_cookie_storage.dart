import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/logger.dart';

/// Persists cookies — specifically the long-lived refresh_token cookie — in
/// the OS keychain / credential locker instead of a plaintext file.
/// cookie_jar's default FileStorage writes the raw Set-Cookie string straight
/// to a JSON file on disk with no OS-level gate: anyone with local file
/// access (another user on a shared machine, malware, a backup dump) could
/// read a live ~30-day session credential straight off disk.
///
/// Every method swallows and logs its own errors instead of throwing. This
/// storage backend sits inside dio_cookie_manager's response interceptor —
/// if a keychain write ever throws through that interceptor (missing
/// entitlement, first-run access prompt, transient OS error), it surfaces as
/// a mystifying failure on whatever HTTP call happened to trigger it (e.g.
/// login reporting "failed" on a 200 response). Persistence is a nice-to-have
/// (session just won't survive a restart if it fails); breaking the request
/// that's actually in flight is not an acceptable trade for that.
class SecureCookieStorage implements Storage {
  SecureCookieStorage({FlutterSecureStorage? backend}) : _backend = backend ?? const FlutterSecureStorage();

  final FlutterSecureStorage _backend;
  static const _prefix = 'bulky_cookie_';

  String _key(String key) => '$_prefix${key.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}';

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) async {
    try {
      return await _backend.read(key: _key(key));
    } catch (e) {
      appLog.warning('SecureCookieStorage read failed for $key: $e');
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _backend.write(key: _key(key), value: value);
    } catch (e) {
      appLog.warning('SecureCookieStorage write failed for $key: $e');
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _backend.delete(key: _key(key));
    } catch (e) {
      appLog.warning('SecureCookieStorage delete failed for $key: $e');
    }
  }

  /// cookie_jar calls this to wipe everything on logout. Nothing else in
  /// bulky uses flutter_secure_storage, so a full wipe is safe and matches
  /// FileStorage's own behavior (which deletes its whole directory, not just
  /// the passed-in keys).
  @override
  Future<void> deleteAll(List<String> keys) async {
    try {
      await _backend.deleteAll();
    } catch (e) {
      appLog.warning('SecureCookieStorage deleteAll failed: $e');
    }
  }
}
