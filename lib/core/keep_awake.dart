import 'package:wakelock_plus/wakelock_plus.dart';

class KeepAwake {
  static Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Best-effort; queue still runs if the platform plugin fails.
    }
  }

  static Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }
}
