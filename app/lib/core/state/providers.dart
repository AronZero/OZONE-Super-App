import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';
import '../data/deletions_repo.dart';
import '../data/photo_store.dart';
import '../data/settings_repo.dart';
import '../platform/error_log.dart';
import '../platform/files_channel.dart';
import '../platform/reminders.dart';
import '../search/search_repo.dart';
import '../security/app_lock_service.dart';
import '../security/vault_service.dart';
import '../ui/amounts.dart';
import '../workbook/backup_service.dart';
import 'undo.dart';

/// The open database. Overridden in `main()` (and with an in-memory database in tests).
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('databaseProvider must be overridden'));

final settingsRepoProvider = Provider<SettingsRepo>((ref) => SettingsRepo(ref.watch(databaseProvider)));
/// Recipe photos in app-private storage (F4-01 §3). Tests override it with a temporary folder.
final photoStoreProvider = Provider<PhotoStore>((ref) => PhotoStore(
      () async => Directory('${(await getApplicationSupportDirectory()).path}/recipe_photos'),
      FilesChannel.toJpeg,
    ));

final deletionsRepoProvider = Provider<DeletionsRepo>((ref) => DeletionsRepo(ref.watch(databaseProvider)));

final themeChoiceProvider = StreamProvider<ThemeChoice>(
    (ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.theme));

final monochromeProvider = StreamProvider<bool>(
    (ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.monochrome));

final barToolsProvider = StreamProvider<List<String>>(
    (ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.barTools));

final dashboardWidgetsProvider = StreamProvider<List<WidgetSetting>>(
    (ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.dashboardWidgets));

final appLockSettingProvider = StreamProvider<AppLockSetting>(
    (ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.appLock));

final hideAmountsOnOpenProvider = StreamProvider<bool>(
    (ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.hideAmountsOnOpen));

/// App lock (F2-01 §5). Overridden in `main()` with a started service.
final appLockServiceProvider = Provider<AppLockService>((ref) => throw UnimplementedError('appLockServiceProvider must be overridden'));

/// The app-wide Undo message (F2-02 §6).
final undoControllerProvider = Provider<UndoController>((ref) {
  final c = UndoController();
  ref.onDispose(c.dispose);
  return c;
});

/// The notes vault (F2-01 §2–4). Overridden in `main()` with a started service.
final vaultServiceProvider = Provider<VaultService>((ref) => throw UnimplementedError('vaultServiceProvider must be overridden'));

/// Whether a vault has been set up on this phone.
final vaultExistsProvider = StreamProvider<bool>((ref) => ref.watch(vaultServiceProvider).watchExists());

/// Global search (F2-02 §1).
final searchRepoProvider = Provider<SearchRepo>((ref) => SearchRepo(ref.watch(databaseProvider), ref.watch(settingsRepoProvider)));

/// Hide amounts (docs/04). `main()` overrides it with the "hide when OZONE opens" setting.
final amountsVisibilityProvider = Provider<AmountsVisibility>((ref) {
  final v = AmountsVisibility();
  ref.onDispose(v.dispose);
  return v;
});

/// Export, safety exports and import (F1-03). Overridden in `main()` with the phone's folders.
final backupServiceProvider = Provider<BackupService>((ref) => throw UnimplementedError('backupServiceProvider must be overridden'));

/// The newest manual export ("Last export"), or null.
final lastExportProvider = StreamProvider<ExportLogRow?>((ref) => ref.watch(backupServiceProvider).watchLastExport());

final backupReminderDaysProvider = StreamProvider<int>((ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.backupReminderDays));

final monthEndReminderProvider = StreamProvider<MonthEndReminder>((ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.monthEndReminder));

/// Month-end reminder (F2-03 §4). Overridden in `main()`.
final remindersProvider = Provider<Reminders>((ref) => throw UnimplementedError('remindersProvider must be overridden'));

/// Local error log (F3-01 §5). Overridden in `main()` with a file in app support.
final errorLogProvider = Provider<ErrorLog>((ref) => ErrorLog.disabled());

/// When OZONE was first opened (UTC ms), for "no export yet" in Needs attention.
final firstRunAtProvider = FutureProvider<int?>((ref) async {
  final db = ref.watch(databaseProvider);
  final row = await (db.select(db.appMeta)..where((m) => m.key.equals('first_run_at'))).getSingleOrNull();
  return int.tryParse(row?.value ?? '');
});
