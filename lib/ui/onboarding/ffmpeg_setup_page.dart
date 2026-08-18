import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/media/ffmpeg_installer.dart';
import '../theme.dart';

class FfmpegSetupPage extends ConsumerWidget {
  const FfmpegSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ffmpegInstallProvider);
    final failed = state.phase == FfmpegInstallPhase.failed;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'bulky',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: BulkyTheme.accent),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Checking for ffmpeg, then installing a full GPL build if it is missing.',
                  style: TextStyle(color: BulkyTheme.muted, fontSize: 15),
                ),
                const SizedBox(height: 28),
                LinearProgressIndicator(
                  value: failed || state.progress <= 0 ? null : state.progress,
                  color: BulkyTheme.accent,
                  backgroundColor: BulkyTheme.panelAlt,
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(color: BulkyTheme.text, fontSize: 15),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(state.error!, style: const TextStyle(color: BulkyTheme.danger)),
                ],
                if (failed) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref.read(ffmpegInstallProvider.notifier).ensure(),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
