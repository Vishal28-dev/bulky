import 'dart:io';

import 'env.dart';

class AppConfig {
  static const String appName = 'bulky';

  // Live gateway. Debug may override via .env / NUKE_BASE_URL.
  // Release always uses https://api.framefloww.me unless dart-define.
  static const String defaultNukeBaseUrl = AppEnv.defaultNukeBaseUrl;
  static String get nukeBaseUrl => AppEnv.nukeBaseUrl;

  /// Nuke website (not the API). Local API → local dashboard.
  static String get nukeWebBaseUrl {
    final api = nukeBaseUrl.toLowerCase();
    if (api.contains('localhost') || api.contains('127.0.0.1')) {
      return 'http://localhost:5010';
    }
    return 'https://nuke.framefloww.me';
  }

  static String get nukeBillingUrl => '$nukeWebBaseUrl/settings/billing';

  // Auth service routes (via gateway /auth/*)
  static const String authLoginPath = '/auth/login';
  static const String authRefreshPath = '/auth/refresh';
  static const String authLogoutPath = '/auth/logout';

  // Nuke backend API prefix (via gateway /nuke/*)
  static const String nukeApiPrefix = '/nuke/api';

  // Upload limits
  static const int maxMediaBytes = 5 * 1024 * 1024 * 1024; // 5 GB
  static const Duration putTimeout = Duration(minutes: 55);
  static const Duration oauthTimeout = Duration(minutes: 5);
  static const Duration postPollInterval = Duration(seconds: 4);
  static const Duration postPollTimeout = Duration(minutes: 45);

  // Media processing
  static const int stillImageSeconds = 8;
  static const int maxTransientAttempts = 3;
  static const String stitchSettingsId = 'ffmpeg-v360-dfisheye-fov190-v1';
  static const int stitchFovDegrees = 190;

  // Fixed schedule: 15 videos/day, 15 minutes apart. First slot is 15
  // minutes after the folder is added. Day 2 starts exactly 24 hours after
  // that first slot. Nothing is published immediately.
  static const int dailyCap = 15;
  static const Duration scheduleSlotInterval = Duration(minutes: 15);
  static const Duration scheduleFirstLead = Duration(minutes: 15);
  static const Duration scheduleSweepInterval = Duration(minutes: 5);
  /// Nuke rejects scheduled times closer than ~5 minutes; stay above that.
  static const Duration scheduleMinLead = Duration(minutes: 5, seconds: 30);

  // Token refresh buffer — refresh if token expires within this window
  static const Duration tokenRefreshBuffer = Duration(seconds: 60);

  static const Set<String> videoExtensions = {
    '.mp4',
    '.mov',
    '.avi',
    '.wmv',
    '.flv',
    '.webm',
    '.3gp',
    '.m4v',
    '.mpeg',
    '.mpg',
  };

  static const Set<String> imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.bmp',
    '.heic',
    '.heif',
  };

  static const Set<String> skipExtensions = {
    '.lrv',
    '.thm',
    '.dng',
    '.lrprev',
    '.off',
    '.xml',
    '.nrt',
  };

  // YouTube category IDs
  static const Map<String, String> ytCategories = {
    '1': 'Film & Animation',
    '2': 'Autos & Vehicles',
    '10': 'Music',
    '15': 'Pets & Animals',
    '17': 'Sports',
    '19': 'Travel & Events',
    '20': 'Gaming',
    '22': 'People & Blogs',
    '23': 'Comedy',
    '24': 'Entertainment',
    '25': 'News & Politics',
    '26': 'Howto & Style',
    '27': 'Education',
    '28': 'Science & Technology',
    '29': 'Nonprofits & Activism',
  };

  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
}
