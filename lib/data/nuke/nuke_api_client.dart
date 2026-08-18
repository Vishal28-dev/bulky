import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../core/config.dart';
import '../../core/logger.dart';
import 'nuke_auth_client.dart';
import 'nuke_models.dart';

/// API client for the Nuke gateway's /nuke/api/* endpoints.
///
/// Every call:
///  1. Ensures the access token is fresh via [NukeAuthClient.ensureFreshToken]
///  2. Sends Authorization: Bearer <token> + x-workspace-id headers
///  3. Proxies to Zernio transparently server-side — the Flutter app never
///     touches Zernio directly or holds a Zernio API key.
class NukeApiClient {
  NukeApiClient({
    required this.auth,
    required this.workspaceId,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.nukeBaseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 60),
                headers: {'Accept': 'application/json'},
              ),
            );

  final NukeAuthClient auth;
  final String workspaceId;
  final Dio _dio;

  String get _prefix => AppConfig.nukeApiPrefix;

  // ─── Accounts ──────────────────────────────────────────────────────────

  Future<List<NukeAccount>> listAccounts() async {
    final resp = await _get('/zernio/accounts');
    final raw = resp['accounts'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => NukeAccount.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<NukeAccount?> youtubeAccount() async {
    final accounts = await listAccounts();
    final yt = accounts.where((a) => a.isYouTube && a.isActive);
    return yt.isEmpty ? null : yt.first;
  }

  /// GET /nuke/api/zernio/accounts/health
  /// Returns health for the specific accountId by filtering the all-accounts list.
  Future<NukeAccountHealth> accountHealth(String accountId) async {
    final resp = await _get('/zernio/accounts/health');
    final raw = resp['accounts'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final h = NukeAccountHealth.fromJson(Map<String, dynamic>.from(item));
          if (h.accountId == accountId) return h;
        }
      }
    }
    // If not found in list, assume healthy (Zernio may not return it if fine)
    return NukeAccountHealth(accountId: accountId, canPost: true, status: 'ok');
  }

  // ─── Connect (OAuth) ───────────────────────────────────────────────────

  Future<NukeConnectUrl> getYouTubeConnectUrl({required String redirectUrl}) async {
    final resp = await _get('/zernio/connect/url', query: {
      'platform': 'youtube',
      'redirect_url': redirectUrl,
    });
    return NukeConnectUrl.fromJson(resp);
  }

  // ─── Media ─────────────────────────────────────────────────────────────

  Future<NukePresignResult> presign({
    required String filename,
    required String contentType,
    required int size,
  }) async {
    if (size > AppConfig.maxMediaBytes) {
      throw NukeException(
        message: 'File exceeds 5 GB limit (${_gb(size)}). Skipping.',
      );
    }
    final resp = await _post('/zernio/media/presign', body: {
      'filename': filename,
      'contentType': contentType,
      'size': size,
    });
    return NukePresignResult.fromJson(resp);
  }

  // ─── Posts ─────────────────────────────────────────────────────────────

  Future<NukePost> createYouTubePost({
    required String accountId,
    required String title,
    required String publicUrl,
    required String visibility,
    required String requestId,
    required DateTime scheduledFor,
    String? categoryId,
    String? playlistId,
    bool madeForKids = false,
    bool containsSyntheticMedia = false,
    String? firstComment,
  }) async {
    final clipped = _sanitizeTitle(title);
    final platformSpecific = <String, dynamic>{
      'title': clipped,
      'visibility': visibility,
      'madeForKids': madeForKids,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (playlistId != null && playlistId.isNotEmpty) 'playlistId': playlistId,
      if (containsSyntheticMedia) 'containsSyntheticMedia': true,
      if (firstComment != null && firstComment.isNotEmpty) 'firstComment': firstComment,
    };
    final resp = await _post(
      '/zernio/posts',
      body: {
        'content': clipped,
        'mediaItems': [
          {'type': 'video', 'url': publicUrl},
        ],
        'platforms': [
          {
            'platform': 'youtube',
            'accountId': accountId,
            'platformSpecificData': platformSpecific,
          },
        ],
        'publishNow': false,
        'scheduledFor': scheduledFor.toUtc().toIso8601String(),
      },
      extraHeaders: {'x-request-id': requestId},
    );
    return NukePost.fromJson(resp, existingPost: resp['existingPost'] != null);
  }

  /// Convert an existing (usually failed) post into a scheduled publish at
  /// [scheduledFor] instead of creating a second post for the same video —
  /// Zernio rejects the same media URL within 24h as a duplicate.
  Future<NukePost> reschedulePost({
    required String postId,
    required DateTime scheduledFor,
  }) async {
    final resp = await _patch('/zernio/posts/$postId', body: {
      'publishNow': false,
      'scheduledFor': scheduledFor.toUtc().toIso8601String(),
    });
    return NukePost.fromJson(resp);
  }

  Future<NukePost> getPost(String postId) async {
    final resp = await _get('/zernio/posts/$postId');
    final inner = resp['post'] is Map
        ? Map<String, dynamic>.from(resp['post'] as Map)
        : resp;
    return NukePost.fromJson(inner);
  }

  Future<NukePost> retryPost(String postId) async {
    final resp = await _post('/zernio/posts/$postId/retry', body: {});
    return NukePost.fromJson(resp);
  }

  /// Live API does not return the failed post id on a 400, so bulky looks the
  /// post up itself. Always send [status] — without it, the same path is the
  /// Instagram picker, not a post list.
  Future<List<NukePost>> listPosts({
    required String status,
    String? platform,
    int limit = 50,
  }) async {
    final resp = await _get('/zernio/posts', query: {
      'status': status,
      if (platform != null && platform.isNotEmpty) 'platform': platform,
      'limit': limit,
      'sortBy': 'created-desc',
    });
    final raw = resp['posts'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => NukePost.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Finds an already-created post for this video so we can PATCH it instead
  /// of creating a second one (same media URL within 24h is a duplicate).
  Future<NukePost?> findPostByMediaUrl(String publicUrl) async {
    if (publicUrl.isEmpty) return null;
    for (final status in const ['failed', 'partial', 'publishing', 'scheduled']) {
      final posts = await listPosts(status: status, platform: 'youtube');
      for (final post in posts) {
        if (post.mediaUrls.contains(publicUrl)) return post;
      }
    }
    return null;
  }

  // ─── Billing ───────────────────────────────────────────────────────────

  Future<NukeEntitlement> getEntitlement() async {
    final resp = await _get('/billing/entitlement');
    return NukeEntitlement.fromJson(resp);
  }

  // ─── Workspaces ────────────────────────────────────────────────────────

  Future<List<NukeWorkspace>> listWorkspaces() async {
    final resp = await _getNoWorkspace('/workspaces');
    // nuke-backend /workspaces returns an array directly (or wrapped)
    if (resp['workspaces'] is List) {
      return (resp['workspaces'] as List)
          .whereType<Map>()
          .map((e) => NukeWorkspace.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  // ─── HTTP helpers ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final token = await auth.ensureFreshToken();
    try {
      final resp = await _dio.get<dynamic>(
        '$_prefix$path',
        queryParameters: query,
        options: Options(headers: _headers(token)),
      );
      return _decode(resp.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  /// Same as _get but without x-workspace-id (for /workspaces which is workspace-scoping itself).
  Future<Map<String, dynamic>> _getNoWorkspace(String path) async {
    final token = await auth.ensureFreshToken();
    try {
      final resp = await _dio.get<dynamic>(
        '$_prefix$path',
        options: Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'}),
      );
      return _decode(resp.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? extraHeaders,
  }) async {
    final token = await auth.ensureFreshToken();
    try {
      final resp = await _dio.post<dynamic>(
        '$_prefix$path',
        data: body,
        options: Options(
          headers: {
            ..._headers(token),
            'Content-Type': 'application/json',
            ...?extraHeaders,
          },
        ),
      );
      return _decode(resp.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final token = await auth.ensureFreshToken();
    try {
      final resp = await _dio.patch<dynamic>(
        '$_prefix$path',
        data: body,
        options: Options(
          headers: {
            ..._headers(token),
            'Content-Type': 'application/json',
          },
        ),
      );
      return _decode(resp.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'x-workspace-id': workspaceId,
        'Accept': 'application/json',
      };

  Map<String, dynamic> _decode(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      final d = jsonDecode(data);
      if (d is Map) return Map<String, dynamic>.from(d);
    }
    return {};
  }

  NukeException _wrap(DioException e) {
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
    final header = e.response?.headers.value('retry-after');
    if (header != null) {
      final s = int.tryParse(header);
      if (s != null) retryAfter = Duration(seconds: s);
    }
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
        (status != null && status >= 400
            ? 'Nuke request failed (HTTP $status). Please try again.'
            : 'Nuke request failed');
    final postMap = json['post'] is Map ? Map<String, dynamic>.from(json['post'] as Map) : null;
    final existingMap = json['existingPost'] is Map
        ? Map<String, dynamic>.from(json['existingPost'] as Map)
        : null;
    final postId = json['postId']?.toString() ??
        postMap?['_id']?.toString() ??
        postMap?['id']?.toString();
    final existingPostId = json['existingPostId']?.toString() ??
        existingMap?['_id']?.toString() ??
        existingMap?['id']?.toString();
    final errorCategory = json['errorCategory']?.toString() ??
        (postMap?['errorCategory']?.toString());
    final bodyPreview = '${e.response?.data}';
    appLog.warning(
      'Nuke API HTTP $status: $message; dioType=${e.type} error=${e.error?.runtimeType}:${e.error}; '
      'raw=${e.message}; body=${bodyPreview.length > 500 ? '${bodyPreview.substring(0, 500)}…' : bodyPreview}; '
      'url=${e.requestOptions.method} ${e.requestOptions.path}',
    );
    return NukeException(
      message: message.toString(),
      statusCode: status,
      retryAfter: retryAfter,
      postId: postId != null && postId.isNotEmpty ? postId : null,
      existingPostId: existingPostId != null && existingPostId.isNotEmpty ? existingPostId : null,
      errorCategory: errorCategory != null && errorCategory.isNotEmpty ? errorCategory : null,
    );
  }

  static String _gb(int bytes) {
    final gb = bytes / (1024 * 1024 * 1024);
    return '${(gb * 100).round() / 100} GB';
  }

  /// Sanitize a video title for YouTube API compliance.
  /// - Strips < > characters (rejected by the API)
  /// - Trims leading/trailing whitespace
  /// - Clips to 100 characters (YouTube hard limit)
  /// - Falls back to 'Untitled Video' if empty after sanitization
  static String _sanitizeTitle(String raw) {
    var t = raw
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('\n', ' ')
        .trim();
    if (t.length > 100) t = t.substring(0, 100).trim();
    return t.isEmpty ? 'Untitled Video' : t;
  }
}

/// Direct-to-S3 streaming uploader. Unchanged from the original — the presigned
/// URL comes from Nuke now but the upload itself is still direct-to-S3.
class StreamUploader {
  static Future<void> putFile({
    required String uploadUrl,
    required File file,
    required String contentType,
    required void Function(int sent, int total) onProgress,
  }) async {
    final length = await file.length();
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    // Scale the "wait for the server's response" timeout to file size
    // instead of applying one flat ceiling to everything. AppConfig.putTimeout
    // (55 min) is sized for the largest allowed file (5 GB) — applying that
    // same ceiling to a 2 MB stitched-photo video meant a stalled connection
    // on a small file gave zero feedback, and no failure, for up to 55
    // minutes. Assume a conservative 256 KB/s floor, with a 90s minimum.
    final scaledSeconds = (length / (256 * 1024)).ceil();
    final responseTimeout = Duration(
      seconds: scaledSeconds.clamp(90, AppConfig.putTimeout.inSeconds),
    );
    try {
      final request = await client.putUrl(Uri.parse(uploadUrl));
      request.contentLength = length;
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      var sent = 0;
      await for (final chunk in file.openRead()) {
        request.add(chunk);
        sent += chunk.length;
        onProgress(sent, length);
      }
      final response = await request.close().timeout(
        responseTimeout,
        onTimeout: () => throw NukeException(
          message: 'Upload stalled — no response from the server after ${responseTimeout.inSeconds}s.',
          retryable: true,
        ),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NukeException(
          message: 'S3 upload failed (${response.statusCode}): $body',
          statusCode: response.statusCode,
        );
      }
    } finally {
      client.close(force: true);
    }
  }
}

/// Backoff helper — used by queue_worker to retry rate-limited/5xx calls.
/// Bounded to [AppConfig.maxTransientAttempts] on BOTH branches — a server
/// stuck permanently returning 429 (misconfig, ban, abuse block) must not
/// make this loop forever; hammering it indefinitely would itself be
/// abusive. [onRetry] is optional caller-visible feedback (e.g. updating a
/// queue job's status line) for the wait, since a silent multi-second delay
/// otherwise just looks like a hang.
Future<T> withBackoff<T>(
  Future<T> Function() action, {
  void Function(String message, Duration wait)? onRetry,
}) async {
  var attempt = 0;
  while (true) {
    try {
      return await action();
    } on NukeException catch (e) {
      attempt++;
      final rateLimited = e.isRateLimited;
      final transientServerError = e.statusCode != null && e.statusCode! >= 500;
      final transient = rateLimited || transientServerError || e.retryable;
      if (!transient || attempt >= AppConfig.maxTransientAttempts) {
        rethrow;
      }
      final wait = e.retryAfter ?? Duration(seconds: min(32, pow(2, attempt).toInt()));
      onRetry?.call(
        rateLimited
            ? 'Rate limited — retrying in ${wait.inSeconds}s'
            : e.retryable && !transientServerError
                ? 'Connection stalled — retrying in ${wait.inSeconds}s'
                : 'Server error — retrying in ${wait.inSeconds}s',
        wait,
      );
      await Future<void>.delayed(wait);
    }
  }
}
