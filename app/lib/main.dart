import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/data/database.dart';
import 'core/data/deletions_repo.dart';
import 'core/data/first_run.dart';
import 'core/data/settings_repo.dart';
import 'core/platform/error_log.dart';
import 'core/platform/reminders.dart';
import 'core/security/app_lock_service.dart';
import 'core/security/biometric_key_store.dart';
import 'core/security/vault_service.dart';
import 'core/state/providers.dart';
import 'core/ui/amounts.dart';
import 'core/workbook/backup_service.dart';

/// Start-up order (docs/spec/F2-03 §6): open the database → migrations → trash
/// purge (OzoneApp) → re-schedule the reminder → app lock → Home, or Welcome on first run.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Unexpected errors go to a local log only (F3-01 §5); screens show the States error pattern.
  final errors = ErrorLog(() async => File('${(await getApplicationSupportDirectory()).path}/errors.log'));
  FlutterError.onError = (d) {
    FlutterError.presentError(d);
    errors.record(d.exception, d.stack, where: d.library ?? 'flutter');
  };
  PlatformDispatcher.instance.onError = (e, st) {
    errors.record(e, st, where: 'async');
    return true;
  };

  // Draw behind the status and navigation bars; screens use SafeArea.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Manrope is bundled, so its SIL OFL licence is registered for Settings › About › Licences.
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/Manrope/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Manrope (font)'], ofl);
  });

  final db = AppDatabase.open();
  final lock = AppLockService(SettingsRepo(db), LocalAuthDeviceAuth());
  await lock.start(); // locks before the first frame if app lock is on
  // "Hide amounts when OZONE opens" (W3 · Security) starts each launch hidden.
  final amounts = AmountsVisibility(hidden: await SettingsRepo(db).get(SettingKeys.hideAmountsOnOpen));
  final vault = VaultService(db, SettingsRepo(db), DeletionsRepo(db), SecureStorageBiometricKeyStore())..start();
  final backup = BackupService(
    db,
    workDir: () async => Directory('${(await getTemporaryDirectory()).path}/exports'),
    safetyDir: () async => Directory('${(await getApplicationSupportDirectory()).path}/safety'),
  );
  final reminders = Reminders(SettingsRepo(db), LocalNotificationsPlatform());
  // The reminder must never stop OZONE from opening (Needs attention covers a missed one).
  try {
    await reminders.start();
  } on Object catch (e, st) {
    FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st, library: 'reminders'));
  }
  final welcome = await FirstRun.needsWelcome(db);
  final fromReminder = await reminders.launchedFromReminder().catchError((Object _) => false);

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appLockServiceProvider.overrideWithValue(lock),
      vaultServiceProvider.overrideWithValue(vault),
      amountsVisibilityProvider.overrideWithValue(amounts),
      backupServiceProvider.overrideWithValue(backup),
      remindersProvider.overrideWithValue(reminders),
      errorLogProvider.overrideWithValue(errors),
    ],
    child: OzoneApp(initialLocation: welcome ? '/welcome' : (fromReminder ? '/finance/savings/update' : '/home')),
  ));
}
