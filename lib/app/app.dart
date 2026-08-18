import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'providers.dart';
import '../core/config.dart';
import '../ui/onboarding/login_page.dart';
import '../ui/onboarding/workspace_picker_page.dart';
import '../ui/onboarding/youtube_connect_page.dart';
import '../ui/onboarding/ffmpeg_setup_page.dart';
import '../ui/theme.dart';
import '../ui/workspace/bulky_page.dart';

class BulkyApp extends ConsumerWidget {
  const BulkyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ffmpeg = ref.watch(ffmpegInstallProvider);
    final session = ref.watch(sessionProvider);

    // ffmpeg must be ready before anything else.
    if (!ffmpeg.isReady) {
      return MaterialApp(
        title: 'bulky',
        debugShowCheckedModeBanner: false,
        theme: BulkyTheme.data(),
        home: const FfmpegSetupPage(),
      );
    }

    Widget home;
    switch (session.screen) {
      case SessionScreen.loading:
        home = const _LoadingScreen();
      case SessionScreen.login:
        home = const LoginPage();
      case SessionScreen.planBlocked:
        home = const _PlanBlockedScreen();
      case SessionScreen.workspacePicker:
        home = const WorkspacePickerPage();
      case SessionScreen.youtubeConnect:
        home = const YoutubeConnectPage();
      case SessionScreen.ready:
        home = const BulkyPage();
    }

    return MaterialApp(
      title: 'bulky',
      debugShowCheckedModeBanner: false,
      theme: BulkyTheme.data(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(session.screen),
          child: home,
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: BulkyTheme.accent),
            SizedBox(height: 20),
            Text('Loading…', style: TextStyle(color: BulkyTheme.muted)),
          ],
        ),
      ),
    );
  }
}

class _PlanBlockedScreen extends ConsumerWidget {
  const _PlanBlockedScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: BulkyTheme.accent),
                const SizedBox(height: 24),
                const Text(
                  'Active plan required',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'bulky requires an active Nuke plan and a YouTube channel connected on the website.\nStart a trial or subscribe, then connect YouTube at Nuke. Come back here and sign in again.',
                  style: TextStyle(color: BulkyTheme.muted, fontSize: 15, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(AppConfig.nukeBillingUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Go to Nuke to subscribe'),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => ref.read(sessionProvider.notifier).signOut(),
                  child: const Text('Sign in with a different account', style: TextStyle(color: BulkyTheme.muted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
