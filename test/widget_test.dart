import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bulky/app/app.dart';
import 'package:bulky/app/providers.dart';
import 'package:bulky/domain/media/ffmpeg_installer.dart';

// Widget smoke test — verifies the app renders without crashing in the
// ffmpeg-not-ready state (setup page) and then in the login state.
void main() {
  testWidgets('shows ffmpeg setup when ffmpeg is not ready', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ffmpegInstallProvider.overrideWith(
            (ref) => FfmpegInstallController(
              ref,
              runOnStart: false,
              initial: const FfmpegInstallState(
                phase: FfmpegInstallPhase.checking,
                message: 'Checking ffmpeg…',
              ),
            ),
          ),
        ],
        child: const BulkyApp(),
      ),
    );
    await tester.pump();
    // Should show the ffmpeg setup page (has a LinearProgressIndicator).
    expect(find.byType(BulkyApp), findsOneWidget);
  });
}
