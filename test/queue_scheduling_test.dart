import 'package:bulky/core/config.dart';
import 'package:bulky/domain/queue/queue_worker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('folder added at 2:00 → first slot 2:15, then every 15 min, day 2 = first slot + 24h', () {
    final origin = DateTime(2026, 8, 18, 14, 15); // 2:00 + 15 min
    expect(packedScheduleSlot(index: 0, origin: origin, cap: AppConfig.dailyCap), DateTime(2026, 8, 18, 14, 15));
    expect(packedScheduleSlot(index: 1, origin: origin, cap: AppConfig.dailyCap), DateTime(2026, 8, 18, 14, 30));
    expect(packedScheduleSlot(index: 14, origin: origin, cap: AppConfig.dailyCap), DateTime(2026, 8, 18, 17, 45));
    expect(packedScheduleSlot(index: 15, origin: origin, cap: AppConfig.dailyCap), DateTime(2026, 8, 19, 14, 15));
    expect(packedScheduleSlot(index: 16, origin: origin, cap: AppConfig.dailyCap), DateTime(2026, 8, 19, 14, 30));
    expect(
      packedScheduleSlot(index: 99, origin: origin, cap: AppConfig.dailyCap),
      DateTime(2026, 8, 24, 16, 30),
    );
  });

  test('daily cap and first lead are fixed at 15', () {
    expect(AppConfig.dailyCap, 15);
    expect(AppConfig.scheduleSlotInterval, const Duration(minutes: 15));
    expect(AppConfig.scheduleFirstLead, const Duration(minutes: 15));
  });

  test('100 videos fill 6 full days plus 10 on day 7', () {
    expect(100 ~/ AppConfig.dailyCap, 6);
    expect(100 % AppConfig.dailyCap, 10);
    final origin = DateTime.utc(2026, 8, 18, 9, 15);
    final last = packedScheduleSlot(index: 99, origin: origin, cap: AppConfig.dailyCap);
    expect(last, origin.add(const Duration(hours: 24 * 6, minutes: 15 * 9)));
  });
}