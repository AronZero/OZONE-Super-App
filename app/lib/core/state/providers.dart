import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/deletions_repo.dart';
import '../data/settings_repo.dart';
import '../security/app_lock_service.dart';
import 'undo.dart';

/// The open database. Overridden in `main()` (and with an in-memory database in tests).
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('databaseProvider must be overridden'));

final settingsRepoProvider = Provider<SettingsRepo>((ref) => SettingsRepo(ref.watch(databaseProvider)));
final deletionsRepoProvider = Provider<DeletionsRepo>((ref) => DeletionsRepo(ref.watch(databaseProvider)));

final themeChoiceProvider = StreamProvider<ThemeChoice>(
    (ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.theme));

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
