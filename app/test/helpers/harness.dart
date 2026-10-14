import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/app.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/security/app_lock_service.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/state/providers.dart';
import 'package:ozone/core/state/today.dart';

/// A fake phone screen lock for tests.
class FakeDeviceAuth implements DeviceAuth {
  bool screenLock = true;
  AuthOutcome next = AuthOutcome.success;
  int prompts = 0;

  @override
  Future<bool> hasScreenLock() async => screenLock;

  @override
  Future<AuthOutcome> authenticate(String reason) async {
    prompts++;
    return next;
  }
}

AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Pumps the whole app on an in-memory database.
/// [today] defaults to 13 Oct 2026, the date on the W1 boards.
Future<(AppDatabase, AppLockService)> pumpApp(WidgetTester tester, {AppDatabase? db, LocalDate? today}) async {
  final d = db ?? memoryDb();
  final lock = AppLockService(SettingsRepo(d), FakeDeviceAuth());
  await tester.runAsync(lock.start);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(d),
      appLockServiceProvider.overrideWithValue(lock),
      todayProvider.overrideWith(() => FixedToday(today ?? LocalDate(2026, 10, 13))),
    ],
    child: const OzoneApp(),
  ));
  await settle(tester);
  return (d, lock);
}

/// Lets drift streams deliver (they run on real async) and then settles frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Unmounts the app and closes the database inside the test clock, so drift's
/// clean-up timers run and nothing is left pending.
Future<void> closeApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  final done = db.close();
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await done;
}

