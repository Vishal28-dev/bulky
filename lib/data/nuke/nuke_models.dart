/// Models for Nuke gateway responses.
library;

// ─── Auth ─────────────────────────────────────────────────────────────────

class NukeUser {
  NukeUser({required this.id, required this.email, this.name, this.avatarUrl});

  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;

  factory NukeUser.fromJson(Map<String, dynamic> json) {
    return NukeUser(
      id: (json['id'] ?? json['sub'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: json['name']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class NukeLoginResult {
  NukeLoginResult({required this.user, required this.accessToken});

  final NukeUser user;
  final String accessToken;

  factory NukeLoginResult.fromJson(Map<String, dynamic> json) {
    return NukeLoginResult(
      user: NukeUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      accessToken: json['accessToken'].toString(),
    );
  }
}

// ─── Workspace ────────────────────────────────────────────────────────────

class NukeWorkspace {
  NukeWorkspace({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final String role;

  factory NukeWorkspace.fromJson(Map<String, dynamic> json) {
    return NukeWorkspace(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? 'member').toString(),
    );
  }
}

// ─── Billing ──────────────────────────────────────────────────────────────

class NukeEntitlement {
  NukeEntitlement({required this.isBlocked, required this.plan, required this.inFreePeriod});

  final bool isBlocked;
  final String? plan;
  final bool inFreePeriod;

  bool get hasAccess => !isBlocked;

  factory NukeEntitlement.fromJson(Map<String, dynamic> json) {
    return NukeEntitlement(
      isBlocked: json['isBlocked'] == true,
      plan: json['plan']?.toString(),
      inFreePeriod: json['inFreePeriod'] == true,
    );
  }
}

// ─── Accounts ─────────────────────────────────────────────────────────────

class NukeAccount {
  NukeAccount({
    required this.id,
    required this.platform,
    required this.username,
    required this.displayName,
    required this.isActive,
    this.profilePicture,
  });

  final String id;
  final String platform;
  final String username;
  final String displayName;
  final bool isActive;
  final String? profilePicture;

  bool get isYouTube => platform.toLowerCase() == 'youtube';

  factory NukeAccount.fromJson(Map<String, dynamic> json) {
    return NukeAccount(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      username: (json['username'] ?? json['handle'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['name'] ?? json['username'] ?? '').toString(),
      isActive: json['isActive'] != false,
      profilePicture: json['profilePicture']?.toString(),
    );
  }
}

class NukeAccountHealth {
  NukeAccountHealth({
    required this.accountId,
    required this.canPost,
    required this.status,
    this.errorMessage,
  });

  final String accountId;
  final bool canPost;
  final String status;
  final String? errorMessage;

  factory NukeAccountHealth.fromJson(Map<String, dynamic> json) {
    final isHealthy = json['isHealthy'] == true || json['canPost'] == true;
    return NukeAccountHealth(
      accountId: (json['accountId'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      canPost: isHealthy,
      status: (json['status'] ?? '').toString(),
      errorMessage: json['error']?.toString() ?? json['errorMessage']?.toString(),
    );
  }
}

// ─── Media / Posts ─────────────────────────────────────────────────────────

class NukePresignResult {
  NukePresignResult({required this.uploadUrl, required this.publicUrl});

  final String uploadUrl;
  final String publicUrl;

  factory NukePresignResult.fromJson(Map<String, dynamic> json) {
    return NukePresignResult(
      uploadUrl: (json['uploadUrl'] ?? json['upload_url'] ?? '').toString(),
      publicUrl: (json['publicUrl'] ?? json['public_url'] ?? '').toString(),
    );
  }
}

class NukePost {
  NukePost({
    required this.id,
    required this.status,
    this.platformStatus,
    this.platformPostUrl,
    this.errorMessage,
    this.errorCategory,
    this.existingPost = false,
    this.publishedAt,
    this.mediaUrls = const [],
  });

  final String id;
  final String status;
  final String? platformStatus;
  final String? platformPostUrl;
  final String? errorMessage;
  final String? errorCategory;
  final bool existingPost;
  /// The platform-reported publish time, when Zernio supplies one — prefer
  /// this over a locally-guessed "when we happened to notice" timestamp.
  final DateTime? publishedAt;
  final List<String> mediaUrls;

  bool get isPublished => status == 'published';
  bool get isFailed => status == 'failed' || status == 'partial';
  bool get isPublishing => status == 'publishing' || status == 'scheduled' || status == 'draft';
  bool get isTransientFailure =>
      errorCategory == 'platform_error' || errorCategory == 'system_error';

  factory NukePost.fromJson(Map<String, dynamic> json, {bool existingPost = false}) {
    final Map<String, dynamic> post = json['post'] is Map
        ? Map<String, dynamic>.from(json['post'] as Map)
        : json['existingPost'] is Map
            ? Map<String, dynamic>.from(json['existingPost'] as Map)
            : json;

    String? platformStatus;
    String? platformUrl;
    String? errorMessage;
    String? errorCategory;
    final mediaUrls = <String>[];
    final mediaItems = post['mediaItems'];
    if (mediaItems is List) {
      for (final item in mediaItems) {
        if (item is Map && item['url'] != null) {
          final url = item['url'].toString();
          if (url.isNotEmpty) mediaUrls.add(url);
        }
      }
    }
    final platforms = post['platforms'];
    if (platforms is List && platforms.isNotEmpty && platforms.first is Map) {
      final first = Map<String, dynamic>.from(platforms.first as Map);
      platformStatus = first['status']?.toString();
      platformUrl = (first['platformPostUrl'] ?? first['url'])?.toString();
      errorMessage = first['error']?.toString() ?? first['errorMessage']?.toString();
      errorCategory = first['errorCategory']?.toString();
    }
    return NukePost(
      id: (post['_id'] ?? post['id']).toString(),
      status: (post['status'] ?? '').toString(),
      platformStatus: platformStatus,
      platformPostUrl: platformUrl,
      errorMessage: errorMessage ?? post['error']?.toString(),
      errorCategory: errorCategory ?? post['errorCategory']?.toString() ?? json['errorCategory']?.toString(),
      existingPost: existingPost || json['existingPost'] != null,
      publishedAt: DateTime.tryParse((post['publishedAt'] ?? '').toString()),
      mediaUrls: mediaUrls,
    );
  }
}

class NukeConnectUrl {
  NukeConnectUrl({required this.authUrl});
  final String authUrl;

  factory NukeConnectUrl.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    return NukeConnectUrl(authUrl: (data['authUrl'] ?? data['url'] ?? '').toString());
  }
}

// ─── Exceptions ────────────────────────────────────────────────────────────

class NukeException implements Exception {
  NukeException({
    required this.message,
    this.statusCode,
    this.code,
    this.retryAfter,
    this.retryable = false,
    this.postId,
    this.existingPostId,
    this.errorCategory,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Duration? retryAfter;

  /// Explicit opt-in for transient, status-code-less failures (e.g. a
  /// stalled connection that timed out) that withBackoff should still treat
  /// as worth retrying — deliberately not inferred from statusCode == null
  /// in general, since most null-status exceptions are local/client errors
  /// that retrying would never fix.
  final bool retryable;

  /// The post that was created then immediately failed (daily cap, etc.).
  /// Present so the caller can PATCH it into a scheduled slot instead of
  /// creating a second post for the same video.
  final String? postId;

  /// Zernio 409 content-hash dedup of the same video within 24h.
  final String? existingPostId;

  /// Zernio platform class — `user_abuse` is how YouTube upload caps arrive.
  final String? errorCategory;

  bool get isUnauthorized => statusCode == 401;
  bool get isRateLimited => statusCode == 429;
  bool get isForbidden => statusCode == 403;
  bool get isPaymentRequired => statusCode == 402;
  bool get isDuplicate =>
      statusCode == 409 ||
      (existingPostId != null && existingPostId!.isNotEmpty) ||
      code == 'duplicate' ||
      message.toLowerCase().contains('duplicate');

  @override
  String toString() => message;
}
