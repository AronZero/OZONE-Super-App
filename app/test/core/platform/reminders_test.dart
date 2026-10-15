import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/platform/reminders.dart';

import '../../helpers/harness.dart';

void main() {
  group('next month-end (F2-03 §4)', () {
    test('the last day of this month at the time, or next month once it has passed', () {
      expect(nextMonthEnd(DateTime(2026, 10, 13, 9), 20, 0), DateTime(2026, 10, 31, 20));
      expect(nextMonthEnd(DateTime(2026, 10, 31, 19, 59), 20, 0), DateTime(2026, 10, 31, 20));
      expect(nextMonthEnd(DateTime(2026, 10, 31, 20, 0), 20, 0), DateTime(2026, 11, 30, 20));
      expect(nextMonthEnd(DateTime(2026, 12, 31, 21), 20, 0), DateTime(2027, 1, 31, 20));
      expect(nextMonthEnd(DateTime(2028, 2, 3), 8, 30), DateTime(2028, 2, 29, 8, 30));
    });

    test('the text never has amounts', () {
      expect(reminderText(DateTime(2026, 10, 31, 20)), 'Update your savings balances for October');
      expect(formatTime(20, 0), '8:00 pm');
      expect(formatTime(0, 5), '12:05 am');
    });
  });

  group('scheduling', () {
    test('one pending reminder; off or no permission means none', () async {
      final db = memoryDb();
      final platform = FakeReminderPlatform();
      final r = Reminders(SettingsRepo(db), platform);
      await r.start();
      expect(platform.scheduled, isNull, reason: 'permission not asked yet: nothing on launch');
      expect(await r.turnOn(), isTrue);
      expect(platform.scheduled!.day, isNot(0));
      expect(platform.scheduled!.hour, 20);
      await r.setTime(7, 15);
      expect((platform.scheduled!.hour, platform.scheduled!.minute), (7, 15));
      expect((await SettingsRepo(db).get(SettingKeys.monthEndReminder)).time, '07:15');
      await r.turnOff();
      expect(platform.scheduled, isNull);
      platform.allowed = false;
      expect(await r.turnOn(), isFalse);
      expect(platform.scheduled, isNull);
      await db.close();
    });
  });
}
