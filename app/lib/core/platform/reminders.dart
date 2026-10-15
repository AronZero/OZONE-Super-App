import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/settings_repo.dart';
import '../domain/dates.dart';
import 'external_activity.dart';

/// The next month-end reminder after [now] (local time): the last day of the
/// month at [hour]:[minute], or next month's if that has passed (F2-03 §4).
DateTime nextMonthEnd(DateTime now, int hour, int minute) {
  DateTime at(int y, int m) => DateTime(y, m, LocalDate.daysInMonth(y, m), hour, minute);
  final thisMonth = at(now.year, now.month);
  if (thisMonth.isAfter(now)) return thisMonth;
  final next = DateTime(now.year, now.month + 1);
  return at(next.year, next.month);
}

/// "8:00 pm".
String formatTime(int hour, int minute) => '${hour % 12 == 0 ? 12 : hour % 12}:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'am' : 'pm'}';

/// "Update your savings balances for October" (never amounts, W3 board).
String reminderText(DateTime when) => 'Update your savings balances for ${LocalDate.fromDateTime(when).monthName}';

/// Talks to the phone's notifications. A seam so tests can fake it.
abstract class ReminderPlatform {
  Future<void> init(void Function() onOpen);
  Future<bool> launchedFromReminder();
  Future<bool> requestPermission();
  Future<bool> enabled();
  Future<void> schedule(DateTime whenLocal, String body);
  Future<void> cancel();
}

/// Month-end balance reminder (F2-03 §4): one pending notification at a time,
/// re-scheduled on every start and settings change, inexact (no exact-alarm permission).
class Reminders {
  Reminders(this._settings, this._platform);
  final SettingsRepo _settings;
  final ReminderPlatform _platform;

  /// Where a tap on the reminder goes (set by the app: Update balances).
  VoidCallback? onOpen;

  Future<void> start() async {
    await _platform.init(() => onOpen?.call());
    await reschedule();
  }

  Future<bool> launchedFromReminder() => _platform.launchedFromReminder();

  /// Never throws: a reminder that can't be scheduled must not break a screen.
  Future<void> reschedule() async {
    try {
      final s = await _settings.get(SettingKeys.monthEndReminder);
      await _platform.cancel();
      if (!s.on || !await _platform.enabled()) return;
      final when = nextMonthEnd(DateTime.now(), s.hour, s.minute);
      await _platform.schedule(when, reminderText(when));
    } on Object catch (e, st) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st, library: 'reminders'));
    }
  }

  /// Turns the reminder on, asking for notification permission at this moment
  /// (never on launch). Returns false when the phone said no.
  Future<bool> turnOn() async {
    final allowed = await _platform.requestPermission();
    final cur = await _settings.get(SettingKeys.monthEndReminder);
    await _settings.set(SettingKeys.monthEndReminder, cur.copyWith(on: true));
    await reschedule();
    return allowed;
  }

  Future<void> turnOff() async {
    final cur = await _settings.get(SettingKeys.monthEndReminder);
    await _settings.set(SettingKeys.monthEndReminder, cur.copyWith(on: false));
    await _platform.cancel();
  }

  Future<void> setTime(int hour, int minute) async {
    final cur = await _settings.get(SettingKeys.monthEndReminder);
    await _settings.set(SettingKeys.monthEndReminder, cur.copyWith(hour: hour, minute: minute));
    await reschedule();
  }

  Future<bool> notificationsEnabled() => _platform.enabled();
}

class LocalNotificationsPlatform implements ReminderPlatform {
  final _plugin = FlutterLocalNotificationsPlugin();
  static const _id = 1;
  static const _payload = 'month_end';

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> init(void Function() onOpen) async {
    // Only UTC is used (the time is an absolute moment), so no time-zone database is loaded.
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_ozone'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload == _payload) onOpen();
      },
    );
  }

  @override
  Future<bool> launchedFromReminder() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    return (d?.didNotificationLaunchApp ?? false) && d?.notificationResponse?.payload == _payload;
  }

  @override
  Future<bool> requestPermission() async => await ExternalActivity.run(() async => await _android?.requestNotificationsPermission() ?? true);

  @override
  Future<bool> enabled() async => await _android?.areNotificationsEnabled() ?? true;

  @override
  Future<void> schedule(DateTime whenLocal, String body) => _plugin.zonedSchedule(
        id: _id,
        // An absolute moment (UTC); re-scheduled on every start, so a time-zone change is picked up then.
        scheduledDate: tz.TZDateTime.from(whenLocal.toUtc(), tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'month_end',
            'Month-end reminder',
            channelDescription: 'Reminds you to update your savings balances on the last day of the month',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'OZONE',
        body: body,
        payload: _payload,
      );

  @override
  Future<void> cancel() => _plugin.cancel(id: _id);
}
