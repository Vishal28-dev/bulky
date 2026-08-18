import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../theme.dart';

class YoutubeConnectPage extends ConsumerWidget {
  const YoutubeConnectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
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
                // Icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0x22FF4444),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x44FF4444)),
                    ),
                    child: const Icon(Icons.play_circle_fill, color: Color(0xFFFF4444), size: 32),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Connect YouTube',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'A browser window will open. Finish signing in there — bulky continues on its own once the channel is connected.\n'
                  'Workspace: ${session.activeWorkspaceName ?? ""}',
                  style: const TextStyle(color: BulkyTheme.muted, fontSize: 14, height: 1.55),
                  textAlign: TextAlign.center,
                ),

                if (session.error != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: BulkyTheme.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BulkyTheme.danger.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: BulkyTheme.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            session.error!,
                            style: const TextStyle(color: BulkyTheme.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: session.loading
                        ? null
                        : () async {
                            try {
                              await ref.read(sessionProvider.notifier).connectYouTube();
                            } catch (_) {}
                          },
                    icon: const Icon(Icons.play_circle_fill, color: Colors.black),
                    label: session.loading
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                              ),
                              SizedBox(width: 10),
                              Text('Waiting for YouTube…'),
                            ],
                          )
                        : const Text(
                            'Connect YouTube',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BulkyTheme.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                TextButton(
                  onPressed: session.loading ? null : () => ref.read(sessionProvider.notifier).signOut(),
                  child: const Text(
                    'Sign out and use a different account',
                    style: TextStyle(color: BulkyTheme.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
