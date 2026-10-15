import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' as drift show Table, TableInfo;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/state/providers.dart';
import 'package:ozone/main.dart' as app;
import 'package:ozone/shell/ui/home/home_screen.dart';
import 'package:ozone/tools/finance/state/savings_providers.dart';
import 'package:path_provider/path_provider.dart';

/// The main flow on a real phone or emulator (F3-03 §1 Integration): first run →
/// add an account → export → wipe the data → import the file → the same totals.
/// The system "Save to" and file picker screens can't be driven by a test, so the
/// export goes through the same service the Export screen uses, and the file is
/// handed to the Import screen directly.
///
/// It deletes the app's database first: run it only on a spare emulator.
///   `flutter drive --profile -d DEVICE --driver=test_driver/perf_driver.dart --target=integration_test/main_flow_test.dart`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first run → account → export → wipe → import → same totals', (tester) async {
    // A fresh install: no database.
    final support = await getApplicationSupportDirectory();
    for (final suffix in ['', '-wal', '-shm']) {
      final f = File('${support.path}/ozone.db$suffix');
      if (f.existsSync()) f.deleteSync();
    }
    final onError = FlutterError.onError;
    await app.main();
    FlutterError.onError = onError;

    Future<void> settle() => tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 20));
    await settle();

    // First run: Welcome → Start fresh → reminder ask → Not now → Home.
    expect(find.text('Start fresh'), findsOneWidget);
    await tester.tap(find.text('Start fresh'));
    await settle();
    await tester.tap(find.text('Not now'));
    await settle();
    expect(find.byType(HomeScreen), findsOneWidget);

    // An account with its starting balance. Typing into the form is covered by the
    // widget tests (savings_flow_test); on a device the keyboard makes multi-field
    // typing unreliable, so the record goes in through the app's own repository.
    final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
    await container.read(savingsRepoProvider).addAccount(name: 'Emergency Fund', startBalance: 41400000, asOf: LocalDate(2026, 10, 1));
    await tester.tap(find.byKey(const ValueKey('bar-Finance')));
    await settle();
    expect(find.text('₱414,000.00'), findsWidgets);

    // Export through the backup service.
    final built = await container.read(backupServiceProvider).build();
    final file = await built.file.copy('${support.path}/flow-export.xlsx');
    expect(built.counts['Accounts'], 1);

    // Wipe the records, as on a new phone.
    final db = container.read(databaseProvider);
    await db.transaction(() async {
      // drift deletes, so the open screens hear about it.
      for (final drift.TableInfo<drift.Table, dynamic> t in [db.noteTags, db.noteDrafts, db.notes, db.tags, db.folders, db.balanceUpdates, db.savingsAccounts, db.goldItems, db.karatPrices, db.expenses, db.books, db.deletions]) {
        await db.delete(t).go();
      }
    });
    await settle();
    expect(find.text('₱414,000.00'), findsNothing);

    // Import the file through the Import screen.
    unawaited(GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/settings/data/import', extra: file));
    await settle();
    final importButton = find.textContaining(RegExp(r'^Import \d+ rows?$'));
    expect(importButton, findsOneWidget);
    await tester.tap(importButton);
    await settle();
    await tester.tap(find.text('Done').first);
    await settle();

    // The same totals as before.
    await tester.tap(find.byKey(const ValueKey('bar-Finance')));
    await settle();
    expect(find.text('₱414,000.00'), findsWidgets);
    expect(find.text('Emergency Fund'), findsWidgets);
    file.deleteSync();
  }, timeout: const Timeout(Duration(minutes: 5)));
}
