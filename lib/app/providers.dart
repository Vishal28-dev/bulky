import 'dart:async';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_paths.dart';
import '../core/config.dart';
import '../core/logger.dart';
import '../data/db/queue_database.dart';
import '../data/nuke/nuke_api_client.dart';
import '../data/nuke/nuke_auth_client.dart';
import '../data/nuke/nuke_models.dart';
import '../data/secure_store.dart';
import '../domain/media/ffmpeg_installer.dart';
import '../domain/media/ffmpeg_service.dart';
import '../domain/media/media_preparer.dart';
import '../domain/media/stitch_service.dart';
import '../domain/queue/queue_worker.dart';

// ─── Infrastructure providers ──────────────────────────────────────────────

final appPathsProvider = Provider<AppPaths>((ref) {
  throw StateError('AppPaths not overridden');
});

final secureStoreProvider = Provider<SecureStore>((ref) {
  final paths = ref.watch(appPathsProvider);
  return SecureStore(supportPath: paths.supportDir.path);
});

final databaseProvider = Provider<QueueDatabase>((ref) {
  return QueueDatabase(paths: ref.watch(appPathsProvider));
});

final ffmpegProvider = Provider<FfmpegService>((ref) {
  return FfmpegService(paths: ref.watch(appPathsProvider));
});

final ffmpegInstallProvider =
    StateNotifierProvider<FfmpegInstallController, FfmpegInstallState>((ref) {
  return FfmpegInstallController(ref);
});

class FfmpegInstallController extends StateNotifier<FfmpegInstallState> {
  FfmpegInstallController(
    this.ref, {
    bool runOnStart = true,
    FfmpegInstallState? initial,
  }) : super(
          initial ??
              const FfmpegInstallState(
                phase: FfmpegInstallPhase.checking,
                message: 'Checking ffmpeg…',
              ),
        ) {
    if (runOnStart) {
      unawaited(ensure());
    }
  }

  final Ref ref;
  bool _startedWorker = false;
  bool _busy = false;

  Future<void> ensure() async {
    if (_busy) return;
    _busy = true;
    try {
      final installer = FfmpegInstaller(
        paths: ref.read(appPathsProvider),
        ffmpeg: ref.read(ffmpegProvider),
      );
      final result = await installer.ensure(onUpdate: (next) {
        if (mounted) state = next;
      });
      if (result.isReady) {
        await _startWorker();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _startWorker() async {
    if (_startedWorker) return;
    _startedWorker = true;
    await ref.read(queueWorkerProvider).start();
  }
}

final stitchServiceProvider = Provider<StitchService>((ref) {
  return StitchService(
    paths: ref.watch(appPathsProvider),
    ffmpeg: ref.watch(ffmpegProvider),
  );
});

final mediaPreparerProvider = Provider<MediaPreparer>((ref) {
  return MediaPreparer(
    paths: ref.watch(appPathsProvider),
    ffmpeg: ref.watch(ffmpegProvider),
    stitcher: ref.watch(stitchServiceProvider),
  );
});

// ─── Auth client (singleton, created once at startup) ─────────────────────

final nukeAuthClientProvider = Provider<NukeAuthClient>((ref) {
  throw StateError('NukeAuthClient not overridden — must be initialised in main()');
});

// ─── Session state ─────────────────────────────────────────────────────────

enum SessionScreen {
  loading,
  login,
  planBlocked,
  workspacePicker,
  youtubeConnect,
  ready,
}

/// What the Nuke website still needs before bulky will let the user in.
class SetupChecklist {
  const SetupChecklist({
    this.needsWorkspace = false,
    this.needsPlan = false,
    this.needsYouTube = false,
  });

  final bool needsWorkspace;
  final bool needsPlan;
  final bool needsYouTube;

  bool get isComplete => !needsWorkspace && !needsPlan && !needsYouTube;

  String get title {
    if (needsWorkspace) return 'Finish setup on the Nuke website first';
    if (needsPlan && needsYouTube) return 'Plan and YouTube are required';
    if (needsPlan) return 'An active Nuke plan is required';
    return 'YouTube must be connected first';
  }

  String get body {
    final steps = <String>[];
    var n = 1;
    steps.add('$n. Open Nuke in your browser (bulky will open it for you).');
    n++;
    if (needsWorkspace) {
      steps.add('$n. Create a workspace (or open the one you use).');
      n++;
    }
    if (needsPlan || needsWorkspace) {
      steps.add('$n. Start a free trial or subscribe — bulky will not run without an active plan.');
      n++;
    }
    if (needsYouTube || needsWorkspace) {
      steps.add('$n. Connect your YouTube channel in that workspace.');
      n++;
    }
    steps.add('$n. Come back to bulky and sign in again.');
    return 'You were signed out of bulky on purpose so a half-ready account cannot continue.\n\nDo this, then sign in here again:\n\n${steps.join('\n')}';
  }

  String get url {
    if (needsPlan && !needsWorkspace && !needsYouTube) return AppConfig.nukeBillingUrl;
    return AppConfig.nukeWebBaseUrl;
  }
}

class SessionState {
  SessionState({
    this.screen = SessionScreen.loading,
    this.user,
    this.workspaces = const [],
    this.activeWorkspaceId,
    this.activeWorkspaceName,
    this.youtubeAccountId,
    this.youtubeUsername,
    this.savedEmail,
    this.error,
    this.setupTitle,
    this.setupBody,
    this.setupUrl,
    this.loading = false,
  });

  final SessionScreen screen;
  final NukeUser? user;
  final List<NukeWorkspace> workspaces;
  final String? activeWorkspaceId;
  final String? activeWorkspaceName;
  final String? youtubeAccountId;
  final String? youtubeUsername;
  final String? savedEmail;
  final String? error;
  final String? setupTitle;
  final String? setupBody;
  final String? setupUrl;
  final bool loading;

  bool get isReady => screen == SessionScreen.ready;
  bool get hasWorkspace => activeWorkspaceId != null && activeWorkspaceId!.isNotEmpty;
  bool get hasYouTube => youtubeAccountId != null && youtubeAccountId!.isNotEmpty;
  bool get hasSetupInstructions => setupBody != null && setupBody!.isNotEmpty;

  SessionState copyWith({
    SessionScreen? screen,
    NukeUser? user,
    List<NukeWorkspace>? workspaces,
    String? activeWorkspaceId,
    String? activeWorkspaceName,
    String? youtubeAccountId,
    String? youtubeUsername,
    String? savedEmail,
    String? error,
    String? setupTitle,
    String? setupBody,
    String? setupUrl,
    bool? loading,
    bool clearError = false,
    bool clearYouTube = false,
    bool clearSetup = false,
  }) {
    return SessionState(
      screen: screen ?? this.screen,
      user: user ?? this.user,
      workspaces: workspaces ?? this.workspaces,
      activeWorkspaceId: activeWorkspaceId ?? this.activeWorkspaceId,
      activeWorkspaceName: activeWorkspaceName ?? this.activeWorkspaceName,
      youtubeAccountId: clearYouTube ? null : (youtubeAccountId ?? this.youtubeAccountId),
      youtubeUsername: clearYouTube ? null : (youtubeUsername ?? this.youtubeUsername),
      savedEmail: savedEmail ?? this.savedEmail,
      error: clearError ? null : (error ?? this.error),
      setupTitle: clearSetup ? null : (setupTitle ?? this.setupTitle),
      setupBody: clearSetup ? null : (setupBody ?? this.setupBody),
      setupUrl: clearSetup ? null : (setupUrl ?? this.setupUrl),
      loading: loading ?? this.loading,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(this.ref) : super(SessionState()) {
    unawaited(_restoreOnStart());
  }

  final Ref ref;

  NukeAuthClient get _auth => ref.read(nukeAuthClientProvider);

  NukeApiClient? _nukeApi;
  NukeApiClient? get nukeApi => _nukeApi;

  // A hidden, already-running Google-login popup, created ahead of time by
  // prewarmGoogleLogin() so loginWithGoogle() only has to reveal + navigate
  // it instead of paying the cost of spinning up a brand new native window
  // and browser engine from cold at the moment the user clicks the button.
  Webview? _prewarmedGoogleWebview;

  @override
  void dispose() {
    _prewarmedGoogleWebview?.close();
    _prewarmedGoogleWebview = null;
    super.dispose();
  }

  /// Turns any caught error into a short, user-safe message. NukeException's
  /// message already comes from the backend and is written to be shown; a
  /// StateError here is our own human-authored copy (e.g. "Google login was
  /// cancelled."). Anything else is an unexpected bug — the full detail goes
  /// to the log, never to the screen.
  String _friendlyError(Object e) {
    if (e is NukeException) {
      final retryAfter = e.retryAfter;
      if (e.isRateLimited && retryAfter != null && retryAfter.inSeconds > 0) {
        final mins = (retryAfter.inSeconds / 60).ceil();
        final wait = mins <= 1 ? '${retryAfter.inSeconds}s' : '${mins}m';
        return '${e.message} (try again in $wait)';
      }
      return e.message;
    }
    if (e is StateError) return e.message;
    appLog.severe('Unexpected session error', e);
    return 'Something went wrong. Please try again.';
  }

  // ─── Startup restore ───────────────────────────────────────────────────

  Future<void> _restoreOnStart() async {
    state = state.copyWith(screen: SessionScreen.loading, loading: true, clearError: true);
    // Read outside the try so the catch handler never needs to re-read a
    // provider that may itself be the thing that just threw.
    String? savedEmail;
    try {
      final store = ref.read(secureStoreProvider);
      savedEmail = await store.readEmail();
      final savedWorkspaceId = await store.readWorkspaceId();
      final savedWorkspaceName = await store.readWorkspaceName();

      // Try to silently refresh the token via the persisted cookie.
      final refreshed = await _auth.refresh();
      if (!refreshed) {
        // Cookie expired — must re-login.
        state = SessionState(
          screen: SessionScreen.login,
          savedEmail: savedEmail,
          loading: false,
        );
        return;
      }

      // Load workspaces first — /billing/entitlement is workspace-scoped and
      // 400s without a real workspace id, so it can't run before this.
      final tmpApi = NukeApiClient(auth: _auth, workspaceId: '');
      final workspaces = await tmpApi.listWorkspaces();
      if (workspaces.isEmpty) {
        await _bounceToWeb(const SetupChecklist(needsWorkspace: true, needsPlan: true, needsYouTube: true));
        return;
      }

      // Resolve workspace.
      String workspaceId;
      String workspaceName;
      if (savedWorkspaceId != null && workspaces.any((w) => w.id == savedWorkspaceId)) {
        workspaceId = savedWorkspaceId;
        workspaceName = savedWorkspaceName ?? workspaces.firstWhere((w) => w.id == savedWorkspaceId).name;
      } else if (workspaces.length == 1) {
        workspaceId = workspaces.first.id;
        workspaceName = workspaces.first.name;
        await store.writeWorkspaceId(workspaceId);
        await store.writeWorkspaceName(workspaceName);
      } else {
        // Multiple workspaces — let user pick.
        state = SessionState(
          screen: SessionScreen.workspacePicker,
          workspaces: workspaces,
          savedEmail: savedEmail,
          loading: false,
        );
        return;
      }

      await _continueAfterWorkspace(
        workspaceId: workspaceId,
        workspaceName: workspaceName,
        workspaces: workspaces,
        savedEmail: savedEmail,
      );
    } catch (e) {
      state = SessionState(
        screen: SessionScreen.login,
        savedEmail: savedEmail,
        error: _friendlyError(e),
        loading: false,
      );
    }
  }

  // ─── Login ─────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    // Signing in with email/password instead — the prewarmed Google popup
    // (if any) won't be used this session; don't leave it running hidden.
    _prewarmedGoogleWebview?.close();
    _prewarmedGoogleWebview = null;

    state = state.copyWith(loading: true, clearError: true, clearSetup: true);
    try {
      final result = await _auth.login(email, password);
      await _handleLoginResult(result, email);
    } catch (e) {
      state = state.copyWith(loading: false, error: _friendlyError(e));
    }
  }

  /// Spins up the Google-login popup ahead of time, hidden, so it's already
  /// running by the time the user actually clicks "Sign in with Google" —
  /// call this as soon as the login screen appears (e.g. LoginPage.initState).
  /// Best-effort: any failure here just means loginWithGoogle() falls back
  /// to creating its own webview on demand, exactly as it did before.
  ///
  /// Windows-only: desktop_webview_window's macOS side has no native handler
  /// for setWebviewWindowVisibility/bringToForeground at all (only its
  /// Windows plugin implements them) — calling them there doesn't just no-op,
  /// it throws, and by the time it does, WebviewWindow.create() has already
  /// made a real, empty popup visible on screen (macOS always shows it
  /// immediately; there's no native "create hidden" mode). Prewarming there
  /// would just flash a blank window at the user before they've clicked
  /// anything, which is worse than the original on-demand latency.
  Future<void> prewarmGoogleLogin() async {
    if (!Platform.isWindows) return;
    if (_prewarmedGoogleWebview != null) return;
    try {
      if (!await WebviewWindow.isWebviewAvailable()) return;
      final webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
          title: 'Sign in with Google',
          windowWidth: 500,
          windowHeight: 700,
          userDataFolderWindows: (await AppPaths.load()).supportDir.path,
        ),
      );
      await webview.setWebviewWindowVisibility(false);
      _prewarmedGoogleWebview = webview;
    } catch (e) {
      appLog.warning('Google login prewarm failed (non-fatal)', e);
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(loading: true, clearError: true, clearSetup: true);
    try {
      final authUrl = '${AppConfig.nukeBaseUrl}/auth/google';

      final prewarmed = _prewarmedGoogleWebview;
      Webview webview;
      if (prewarmed != null) {
        _prewarmedGoogleWebview = null;
        webview = prewarmed;
        await webview.setWebviewWindowVisibility(true);
        await webview.bringToForeground();
      } else {
        final hasWebview = await WebviewWindow.isWebviewAvailable();
        if (!hasWebview) {
          throw StateError('WebView runtime is not available on this system.');
        }
        webview = await WebviewWindow.create(
          configuration: CreateConfiguration(
            title: 'Sign in with Google',
            windowWidth: 500,
            windowHeight: 700,
            userDataFolderWindows: (await AppPaths.load()).supportDir.path,
          ),
        );
      }

      final completer = Completer<String?>();
      
      webview.setOnUrlRequestCallback((url) {
        final uri = Uri.parse(url);
        if (uri.path == '/auth/callback' && uri.queryParameters.containsKey('code')) {
          if (!completer.isCompleted) completer.complete(uri.queryParameters['code']);
          webview.close();
          return false;
        } else if (uri.path.contains('/sign-in') && uri.queryParameters.containsKey('error')) {
          if (!completer.isCompleted) completer.completeError(StateError('Google login failed: ${uri.queryParameters['error']}'));
          webview.close();
          return false;
        }
        return true;
      });
      
      webview.onClose.whenComplete(() {
        if (!completer.isCompleted) completer.complete(null);
      });

      webview.launch(authUrl);

      final code = await completer.future;
      if (code == null) {
        throw StateError('Google login was cancelled.');
      }

      final result = await _auth.exchangeSession(code);
      await _handleLoginResult(result, result.user.email);
    } catch (e) {
      state = state.copyWith(loading: false, error: _friendlyError(e));
    }
  }

  Future<void> _handleLoginResult(NukeLoginResult result, String email) async {
    final store = ref.read(secureStoreProvider);
    await store.writeEmail(email.trim());

    // Load workspaces — /billing/entitlement is workspace-scoped and 400s
    // without a real workspace id, so check it after resolving one instead.
    final tmpApi = NukeApiClient(auth: _auth, workspaceId: '');
    final workspaces = await tmpApi.listWorkspaces();
    if (workspaces.isEmpty) {
      await _bounceToWeb(const SetupChecklist(needsWorkspace: true, needsPlan: true, needsYouTube: true));
      return;
    }

    if (workspaces.length == 1) {
      final ws = workspaces.first;
      await store.writeWorkspaceId(ws.id);
      await store.writeWorkspaceName(ws.name);
      await _continueAfterWorkspace(
        workspaceId: ws.id,
        workspaceName: ws.name,
        workspaces: workspaces,
        savedEmail: email.trim(),
        user: result.user,
      );
    } else {
      state = state.copyWith(
        screen: SessionScreen.workspacePicker,
        user: result.user,
        workspaces: workspaces,
        savedEmail: email.trim(),
        loading: false,
      );
    }
  }

  // ─── Workspace selection ────────────────────────────────────────────────

  Future<void> selectWorkspace(NukeWorkspace workspace) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final store = ref.read(secureStoreProvider);
      await store.writeWorkspaceId(workspace.id);
      await store.writeWorkspaceName(workspace.name);
      await _continueAfterWorkspace(
        workspaceId: workspace.id,
        workspaceName: workspace.name,
        workspaces: state.workspaces,
        savedEmail: state.savedEmail,
        user: state.user,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _friendlyError(e));
    }
  }

  // ─── YouTube connect ────────────────────────────────────────────────────

  Future<void> connectYouTube() async {
    final api = _nukeApi;
    if (api == null) return;

    state = state.copyWith(loading: true, clearError: true);
    try {
      // The live connect-url API ignores any local redirect and always sends
      // the browser to nuke.framefloww.me/callback. Wait for the channel to
      // show up on the account list instead of listening on 127.0.0.1.
      final connectUrl = await api.getYouTubeConnectUrl(
        redirectUrl: 'https://nuke.framefloww.me/callback',
      );
      final launched = await launchUrl(
        Uri.parse(connectUrl.authUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Could not open browser for YouTube login.');
      }

      final deadline = DateTime.now().add(AppConfig.oauthTimeout);
      NukeAccount? account;
      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(seconds: 2));
        try {
          account = await api.youtubeAccount();
        } catch (e) {
          appLog.fine('YouTube connect poll: $e');
        }
        if (account != null) break;
      }
      if (account == null) {
        throw StateError(
          'YouTube login timed out. Finish signing in in the browser, then try again.',
        );
      }

      final db = ref.read(databaseProvider);
      final username = account.username.isEmpty ? account.displayName : account.username;
      await db.setSetting(SettingKeys.accountId, account.id);
      await db.setSetting(SettingKeys.accountUsername, username);

      state = state.copyWith(
        youtubeAccountId: account.id,
        youtubeUsername: username,
        screen: SessionScreen.ready,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _friendlyError(e));
      rethrow;
    }
  }

  // ─── Sign out ──────────────────────────────────────────────────────────

  Future<void> signOut() async {
    _nukeApi = null;
    await ref.read(secureStoreProvider).clearAll();
    await ref.read(databaseProvider).clearAccountSettings();
    await _auth.logout();
    state = SessionState(
      screen: SessionScreen.login,
      savedEmail: await ref.read(secureStoreProvider).readEmail(),
      loading: false,
    );
  }

  Future<void> openSetupWebsite() async {
    final url = state.setupUrl ?? AppConfig.nukeWebBaseUrl;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // ─── Reconnect YouTube ─────────────────────────────────────────────────

  Future<void> reconnectYouTube() async {
    await _bounceToWeb(const SetupChecklist(needsYouTube: true));
  }

  // ─── Internal helpers ──────────────────────────────────────────────────

  Future<void> _bounceToWeb(SetupChecklist missing) async {
    final email = state.savedEmail ?? await ref.read(secureStoreProvider).readEmail();
    _nukeApi = null;
    await ref.read(secureStoreProvider).clearWorkspace();
    await ref.read(databaseProvider).clearAccountSettings();
    try {
      await _auth.logout();
    } catch (e) {
      appLog.fine('Logout during setup bounce (best-effort): $e');
    }
    state = SessionState(
      screen: SessionScreen.login,
      savedEmail: email,
      setupTitle: missing.title,
      setupBody: missing.body,
      setupUrl: missing.url,
      loading: false,
    );
    try {
      await launchUrl(Uri.parse(missing.url), mode: LaunchMode.externalApplication);
    } catch (e) {
      appLog.warning('Could not open Nuke website: $e');
    }
  }

  Future<void> _continueAfterWorkspace({
    required String workspaceId,
    required String workspaceName,
    required List<NukeWorkspace> workspaces,
    required String? savedEmail,
    NukeUser? user,
  }) async {
    final api = NukeApiClient(auth: _auth, workspaceId: workspaceId);

    final entitlement = await api.getEntitlement();
    final account = await api.youtubeAccount();
    final planOk = entitlement.hasAccess;
    final youtubeOk = account != null && account.isActive && account.id.isNotEmpty;

    if (!planOk || !youtubeOk) {
      await _bounceToWeb(SetupChecklist(
        needsPlan: !planOk,
        needsYouTube: !youtubeOk,
      ));
      return;
    }

    _nukeApi = api;
    final worker = ref.read(queueWorkerProvider);
    worker.updateApiClient(api);

    final db = ref.read(databaseProvider);
    final connected = account;
    final username = connected.username.isEmpty ? connected.displayName : connected.username;
    await db.setSetting(SettingKeys.accountId, connected.id);
    await db.setSetting(SettingKeys.accountUsername, username);

    state = SessionState(
      screen: SessionScreen.ready,
      user: user,
      workspaces: workspaces,
      activeWorkspaceId: workspaceId,
      activeWorkspaceName: workspaceName,
      youtubeAccountId: connected.id,
      youtubeUsername: username,
      savedEmail: savedEmail,
      loading: false,
    );
  }
}

final sessionProvider = StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController(ref);
});

// ─── Queue worker ──────────────────────────────────────────────────────────

final queueWorkerProvider = Provider<QueueWorker>((ref) {
  final db = ref.watch(databaseProvider);
  return QueueWorker(
    db: db,
    preparer: ref.watch(mediaPreparerProvider),
    apiClientProvider: () => ref.read(sessionProvider.notifier).nukeApi,
    accountIdProvider: () async => ref.read(sessionProvider).youtubeAccountId,
  );
});

final jobsProvider = StreamProvider<List<QueueJob>>((ref) {
  return ref.watch(databaseProvider).watchJobs();
});

final stitchCapProvider =
    FutureProvider<StitchCapability>((ref) {
  return ref.watch(stitchServiceProvider).probe();
});
