import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/data/database.dart';
import 'core/data/deletions_repo.dart';
import 'core/data/settings_repo.dart';
import 'core/security/app_lock_service.dart';
import 'core/security/biometric_key_store.dart';
import 'core/security/vault_service.dart';
import 'core/state/providers.dart';
import 'core/ui/amounts.dart';

/// Start-up order (docs/spec/F2-03 §6): open the database → app lock check → Home.
/// Later milestones add the trash purge and reminder scheduling here.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appLockServiceProvider.overrideWithValue(lock),
      vaultServiceProvider.overrideWithValue(vault),
      amountsVisibilityProvider.overrideWithValue(amounts),
    ],
    child: const OzoneApp(),
  ));
}
