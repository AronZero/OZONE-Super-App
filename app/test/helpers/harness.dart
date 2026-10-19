import 'dart:io';

import 'package:cryptography/dart.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/app.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/photo_store.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/platform/reminders.dart';
import 'package:ozone/core/security/app_lock_service.dart';
import 'package:ozone/core/security/biometric_key_store.dart';
import 'package:ozone/core/security/vault_crypto.dart';
import 'package:ozone/core/security/vault_service.dart';
import 'package:ozone/core/state/providers.dart';
import 'package:ozone/core/state/today.dart';
import 'package:ozone/core/workbook/backup_service.dart';

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

/// A fake fingerprint store: [next] decides what the next read does.
class FakeBiometricKeyStore implements BiometricKeyStore {
  bool isAvailable = true;
  Uint8List? stored;
  BiometricRead next = BiometricRead.ok;

  @override
  Future<bool> available() async => isAvailable;

  @override
  Future<bool> save(Uint8List dk) async {
    stored = Uint8List.fromList(dk);
    return true;
  }

  @override
  Future<(BiometricRead, Uint8List?)> read() async {
    if (next != BiometricRead.ok) return (next, null);
    final s = stored;
    return s == null ? (BiometricRead.invalidated, null) : (BiometricRead.ok, Uint8List.fromList(s));
  }

  @override
  Future<void> delete() async => stored = null;
}

/// A fake phone notification system that records what was scheduled.
class FakeReminderPlatform implements ReminderPlatform {
  bool allowed = true;
  bool asked = false;
  DateTime? scheduled;
  String? body;

  @override
  Future<void> init(void Function() onOpen) async {}
  @override
  Future<bool> launchedFromReminder() async => false;
  @override
  Future<bool> requestPermission() async {
    asked = true;
    return allowed;
  }

  @override
  Future<bool> enabled() async => allowed && asked;
  @override
  Future<void> schedule(DateTime whenLocal, String body) async {
    scheduled = whenLocal;
    this.body = body;
  }

  @override
  Future<void> cancel() async => scheduled = null;
}

/// A photo store in a temporary folder whose converter just copies.
PhotoStore testPhotos() {
  final root = Directory.systemTemp.createTempSync('ozone_photos');
  addTearDown(() => root.deleteSync(recursive: true));
  return PhotoStore(() async => Directory(root.path), (from, to, {required maxSide, required quality}) async => File(from).copySync(to));
}

/// A backup service writing to a temporary folder, encoding in place.
BackupService testBackup(AppDatabase db, {PhotoStore? photos}) {
  final root = Directory.systemTemp.createTempSync('ozone_backup');
  addTearDown(() => root.deleteSync(recursive: true));
  return BackupService(
    db,
    workDir: () async => Directory('${root.path}/exports'),
    safetyDir: () async => Directory('${root.path}/safety'),
    photos: photos,
    heavy: <R>(R Function() work) async => work(),
  );
}

/// SHA-256(secret ‖ salt): a stand-in for Argon2id in widget tests, whose fake
/// clock times out cryptography's Argon2 helper isolates. The real KDF is
/// covered by test/core/security/vault_test.dart.
Future<Uint8List> fakeDerive(List<int> secret, List<int> salt, KdfParams p) async =>
    Uint8List.fromList(const DartSha256().hashSync([...secret, ...salt]).bytes);

/// A vault for tests: OWASP-minimum Argon2id derived in place, or [fakeDerive] with [fastKdf].
VaultService testVault(AppDatabase db, {BiometricKeyStore? bio, int Function()? clock, bool fastKdf = false}) => VaultService(
      db,
      SettingsRepo(db),
      DeletionsRepo(db),
      bio ?? FakeBiometricKeyStore(),
      clock: clock,
      calibrateKdf: () async => KdfParams.minimum,
      derive: fastKdf ? fakeDerive : deriveKeySync,
    );

AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Pumps the whole app on an in-memory database.
/// [today] defaults to 13 Oct 2026, the date on the W1 boards.
Future<(AppDatabase, AppLockService)> pumpApp(
  WidgetTester tester, {
  AppDatabase? db,
  LocalDate? today,
  VaultService? vault,
  FakeReminderPlatform? reminders,
  String initialLocation = '/home',
  List<Override> overrides = const [],
}) async {
  final d = db ?? memoryDb();
  final v = vault ?? testVault(d, fastKdf: true);
  final lock = AppLockService(SettingsRepo(d), FakeDeviceAuth());
  await tester.runAsync(lock.start);
  final photos = testPhotos();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(d),
      appLockServiceProvider.overrideWithValue(lock),
      vaultServiceProvider.overrideWithValue(v),
      backupServiceProvider.overrideWithValue(testBackup(d, photos: photos)),
      photoStoreProvider.overrideWithValue(photos),
      ...overrides,
      remindersProvider.overrideWithValue(Reminders(SettingsRepo(d), reminders ?? FakeReminderPlatform())),
      todayProvider.overrideWith(() => FixedToday(today ?? LocalDate(2026, 10, 13))),
    ],
    child: OzoneApp(initialLocation: initialLocation),
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

