import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/platform/external_activity.dart';
import 'package:ozone/core/security/app_lock_service.dart';

import '../../helpers/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late FakeDeviceAuth device;
  late SettingsRepo settings;

  Future<AppLockService> start({bool on = true, int relock = 60}) async {
    await settings.set(SettingKeys.appLock, AppLockSetting(on: on, relockAfterS: relock));
    final s = AppLockService(settings, device, clock: () => now);
    await s.start();
    return s;
  }

  setUp(() {
    now = DateTime(2026, 10, 14, 9);
    device = FakeDeviceAuth();
    settings = SettingsRepo(memoryDb());
  });

  test('locks on cold start when on; stays open when off', () async {
    expect((await start()).locked.value, isTrue);
    expect((await start(on: false)).locked.value, isFalse);
  });

  test('relocks only after the chosen time in the background', () async {
    final s = await start();
    await s.unlock();
    expect(s.locked.value, isFalse);

    s.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 30));
    s.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(s.locked.value, isFalse, reason: '30 s is under 1 minute');

    s.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 61));
    s.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(s.locked.value, isTrue);
  });

  test('"Immediately" relocks on any return', () async {
    final s = await start(relock: 0);
    await s.unlock();
    s.didChangeAppLifecycleState(AppLifecycleState.paused);
    s.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(s.locked.value, isTrue);
  });

  test('Save to, the file picker or the share sheet opened by OZONE isn’t leaving', () async {
    final s = await start(relock: 0);
    await s.unlock();
    await ExternalActivity.run(() async {
      s.didChangeAppLifecycleState(AppLifecycleState.paused);
      s.didChangeAppLifecycleState(AppLifecycleState.resumed);
    });
    expect(s.locked.value, isFalse);
    // Really leaving still relocks.
    s.didChangeAppLifecycleState(AppLifecycleState.paused);
    s.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(s.locked.value, isTrue);
  });

  test('a cancelled prompt keeps the gate', () async {
    final s = await start();
    device.next = AuthOutcome.cancelled;
    expect(await s.unlock(), AuthOutcome.cancelled);
    expect(s.locked.value, isTrue);
  });

  test('turning on needs a phone screen lock and a confirmation', () async {
    final s = await start(on: false);
    device.screenLock = false;
    expect(await s.enable(), EnableResult.noScreenLock);
    device.screenLock = true;
    device.next = AuthOutcome.cancelled;
    expect(await s.enable(), EnableResult.cancelled);
    device.next = AuthOutcome.success;
    expect(await s.enable(), EnableResult.enabled);
    expect((await settings.get(SettingKeys.appLock)).on, isTrue);
  });
}
