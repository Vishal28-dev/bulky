import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config.dart';
import '../../core/logger.dart';
import '../secure_cookie_storage.dart';
import 'nuke_models.dart';

/// Handles Nuke auth-service login / token-refresh / logout.
///
/// Key design decisions:
///  - Access token is in-memory ONLY — never written to disk.
///  - The httpOnly refresh_token cookie is persisted via [PersistCookieJar]
///    backed by [SecureCookieStorage] (OS keychain / credential locker), not
///    a plaintext file.
///  - On app restart we call refresh() first; if it fails the user re-logs in.
///  - JWT exp claim is parsed client-side (no signature verify) to decide when
///    to proactively refresh before the 401 happens.
class NukeAuthClient {
  NukeAuthClient._({required Dio dio, required PersistCookieJar cookieJar})
      : _dio = dio,
        _cookieJar = cookieJar;

  final Dio _dio;
  final PersistCookieJar _cookieJar;

  String? _accessToken;
  int? _tokenExpiresAt; // Unix epoch seconds, nullable if JWT has no exp

  static Future<NukeAuthClient> create({String? appSupportPath}) async {
    String cookieDir;
    if (appSupportPath != null) {
      cookieDir = p.join(appSupportPath, 'cookies');
    } else {
      final support = await getApplicationSupportDirectory();
      cookieDir = p.join(support.path, 'bulky', 'cookies');
    }

    // One-time cleanup: older builds stored the refresh_token cookie as a
    // plaintext JSON file here. Delete it now that cookies live in the OS
    // keychain instead — costs a signed-in user one re-login, once, in
    // exchange for not leaving a live session credential sitting unencrypted
    // on disk next to the new keychain-backed storage.
    final legacyCookieDir = Directory(cookieDir);
    if (await legacyCookieDir.exists()) {
      await legacyCookieDir.delete(recursive: true);
    }

    final cookieJar = PersistCookieJar(storage: SecureCookieStorage());
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.nukeBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'bulky/1.0 Flutter',
        },
      ),
    );
    dio.interceptors.add(CookieManager(cookieJar));

    return NukeAuthClient._(dio: dio, cookieJar: cookieJar);
  }

  // ─── Public API ─────────────────────────────────────────────────────────

  String? get accessToken => _accessToken;

  /// Returns true when the access token is non-null and has not expired
  /// (minus a safety buffer).  If exp is unavailable, assumes valid.
  bool get isTokenValid {
    if (_accessToken == null) return false;
    // If we couldn't parse the exp claim, optimistically assume valid.
    if (_tokenExpiresAt == null) return true;
    final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSecs < (_tokenExpiresAt! - AppConfig.tokenRefreshBuffer.inSeconds);
  }

  /// Login with Nuke credentials.  Stores the new access token in memory.
  /// The httpOnly refresh_token cookie is automatically persisted by the jar.
  Future<NukeLoginResult> login(String email, String password) async {
    try {
      final response = await _dio.post<dynamic>(
        AppConfig.authLoginPath,
        data: {'email': email.trim(), 'password': password},
      );
      final json = _toMap(response.data);
      final result = NukeLoginResult.fromJson(json);
      _storeToken(result.accessToken);
      appLog.info('Nuke login OK — ${result.user.email}');
      return result;
    } on DioException catch (e) {
      throw _wrap(e, 'Login failed');
    }
  }

  /// Exchange a one-time login code (from OAuth) for a session.
  Future<NukeLoginResult> exchangeSession(String code) async {
    try {
      final response = await _dio.post<dynamic>(
        '/auth/session/exchange',
        data: {'code': code},
      );
      final json = _toMap(response.data);
      final result = NukeLoginResult.fromJson(json);
      _storeToken(result.accessToken);
      appLog.info('Nuke OAuth login OK — ${result.user.email}');
      return result;
    } on DioException catch (e) {
      throw _wrap(e, 'Google login failed');
    }
  }

  /// Silently refresh the access token using the persisted cookie.
  /// Returns false when the session is fully expired (user must re-login).
  Future<bool> refresh() async {
    try {
      final response = await _dio.post<dynamic>(AppConfig.authRefreshPath);
      final json = _toMap(response.data);
      final token = json['accessToken']?.toString();
      if (token == null || token.isEmpty) {
        appLog.info('Nuke refresh: empty token — treating as expired');
        _clearToken();
        return false;
      }
      _storeToken(token);
      appLog.fine('Nuke token refreshed');
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        appLog.info('Nuke refresh token expired (HTTP $status)');
        _clearToken();
        return false;
      }
      // Network error or 5xx — rethrow so caller can show a better message.
      throw _wrap(e, 'Token refresh failed');
    }
  }

  /// Returns a fresh access token, refreshing if necessary.
  /// Throws [NukeException] with statusCode=401 if fully expired.
  Future<String> ensureFreshToken() async {
    if (isTokenValid && _accessToken != null) return _accessToken!;
    final ok = await refresh();
    if (!ok || _accessToken == null) {
      throw NukeException(
        message: 'Session expired. Please sign in again.',
        statusCode: 401,
        code: 'session_expired',
      );
    }
    return _accessToken!;
  }

  /// Whether the cookie jar likely has a valid refresh_token for the domain.
  /// Used on startup to skip the login screen.
  Future<bool> hasPersistentSession() async {
    try {
      final cookies = await _cookieJar.loadForRequest(Uri.parse(AppConfig.nukeBaseUrl));
      // The refresh token cookie may be named 'refresh_token' or similar.
      // If any non-expired cookie exists for our domain, assume a session exists.
      return cookies.any((c) {
        if (c.expires != null && c.expires!.isBefore(DateTime.now())) return false;
        return c.name.contains('refresh') || c.name.contains('session') || c.name.contains('token');
      });
    } catch (_) {
      return false;
    }
  }

  /// Logout: clear in-memory token, call server to invalidate cookie, clear jar.
  Future<void> logout() async {
    _clearToken();
    try {
      await _dio.post<dynamic>(AppConfig.authLogoutPath);
    } catch (e) {
      appLog.fine('Logout request failed (best-effort): $e');
    }
    try {
      await _cookieJar.deleteAll();
    } catch (_) {}
    appLog.info('Nuke signed out');
  }

  // ─── Private helpers ────────────────────────────────────────────────────

  void _storeToken(String token) {
    _accessToken = token;
    _tokenExpiresAt = _jwtExp(token); // null if no exp claim
  }

  void _clearToken() {
    _accessToken = null;
    _tokenExpiresAt = null;
  }

  /// Decode the JWT payload to extract the `exp` claim (no sig verification).
  static int? _jwtExp(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      // Pad to valid base64 length
      var encoded = parts[1];
      switch (encoded.length % 4) {
        case 2:
          encoded += '==';
        case 3:
          encoded += '=';
      }
      final decoded = utf8.decode(base64Url.decode(encoded));
      final payload = jsonDecode(decoded);
      if (payload is Map) {
        final exp = payload['exp'];
        if (exp is int) return exp;
        if (exp is double) return exp.toInt();
        if (exp is String) return int.tryParse(exp);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        final d = jsonDecode(data);
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return {};
  }

  NukeException _wrap(DioException e, String fallback) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    Map<String, dynamic> json = {};
    if (data is Map) json = Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final d = jsonDecode(data);
        if (d is Map) json = Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    Duration? retryAfter;
    final retryHeader = e.response?.headers.value('retry-after');
    if (retryHeader != null) {
      final s = int.tryParse(retryHeader);
      if (s != null) retryAfter = Duration(seconds: s);
    }
    // auth-service wraps as { error: { message: "…" } } or { message: "…" };
    // some upstreams (proxied Zernio/edge errors) may use { error: "…" } or
    // { errors: [...] } instead — handle those shapes too rather than falling
    // through to Dio's own internal diagnostic text, which is developer-facing
    // only and must never reach the UI.
    final errObj = json['error'];
    final userError = json['userError'];
    final errorsList = json['errors'];
    final message = (userError is Map ? userError['message']?.toString() : null) ??
        (errObj is Map ? errObj['message']?.toString() : null) ??
        (errObj is String && errObj.isNotEmpty ? errObj : null) ??
        json['message']?.toString() ??
        (errorsList is List && errorsList.isNotEmpty
            ? errorsList.first.toString()
            : null) ??
        (e.type == DioExceptionType.connectionTimeout
            ? 'Connection timed out. Check your internet connection.'
            : e.type == DioExceptionType.receiveTimeout
                ? 'Server took too long to respond.'
                : null) ??
        // Only claim an HTTP failure when the status actually looks like one —
        // a DioException can carry a 2xx response (e.g. a cancellation or a
        // response-transform error unrelated to the HTTP call itself), and
        // "(HTTP 200)" next to "failed" is actively misleading.
        (status != null && status >= 400 ? '$fallback (HTTP $status). Please try again.' : fallback);
    final bodyPreview = '${e.response?.data}';
    appLog.warning(
      'Nuke auth HTTP $status: $message; dioType=${e.type} error=${e.error?.runtimeType}:${e.error}; '
      'raw=${e.message}; body=${bodyPreview.length > 500 ? '${bodyPreview.substring(0, 500)}…' : bodyPreview}',
    );
    return NukeException(
      message: message,
      statusCode: status,
      retryAfter: retryAfter,
    );
  }
}
