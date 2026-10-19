import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/search/search_repo.dart';
import 'package:ozone/core/security/biometric_key_store.dart';
import 'package:ozone/core/security/vault_service.dart';
import 'package:ozone/core/ui/components/components.dart';
import 'package:ozone/core/workbook/ozone_export.dart';
import 'package:ozone/core/workbook/ozone_import.dart';
import 'package:ozone/core/workbook/workbook.dart';
import 'package:ozone/main.dart' as app;
import 'package:path_provider/path_provider.dart';

import 'large_sample.dart';

/// Performance budgets (F2-03 §8) with the large sample (10,000 rows, 500
/// notes, 1,000 recipes with 300 photos), run on a phone or emulator in profile mode:
///   flutter drive --profile --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
/// Only for the temporary performance emulator: it writes the sample into the
/// app's real database.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final results = <String, Object?>{};

  int ms(Stopwatch sw) => sw.elapsedMilliseconds;

  testWidgets('data work: seed, search, export, import, vault', (tester) async {
    await tester.runAsync(() async {
      final db = AppDatabase.open();
      final rows = (await db.customSelect('SELECT (SELECT COUNT(*) FROM expenses) + (SELECT COUNT(*) FROM books) + '
              '(SELECT COUNT(*) FROM balance_updates) + (SELECT COUNT(*) FROM gold_items) + (SELECT COUNT(*) FROM karat_prices) AS n')
          .getSingle())
          .read<int>('n');
      if (rows < 10000) {
        final sw = Stopwatch()..start();
        final photos = await seedLargeSample(db);
        results['seed_ms'] = ms(sw);
        await writeSamplePhotos(Directory('${(await getApplicationSupportDirectory()).path}/recipe_photos'), photos);
      }

      // Search: under 100 ms per query.
      final search = SearchRepo(db, SettingsRepo(db));
      final times = <String, int>{};
      for (final q in ['gro', 'groceries 12', 'mercury', 'book title 5', 'author 7', 'trip', 'paragraph 3 budget', '4,500', 'ring', 'adobo 5', 'tamarind', 'kare']) {
        await search.search(q); // warm the statement cache once per query shape
        final sw = Stopwatch()..start();
        await search.search(q);
        times[q] = ms(sw);
      }
      results['search_ms'] = times;
      results['search_worst_ms'] = times.values.reduce((a, b) => a > b ? a : b);

      // Export: under 10 s.
      var sw = Stopwatch()..start();
      final book = await buildWorkbook(db, appVersion: 'perf');
      final bytes = XlsxCodec.encode(book);
      results['export_ms'] = ms(sw);
      results['export_kb'] = bytes.length ~/ 1024;

      // Import of the same file onto an empty phone: under 8 s.
      final fresh = AppDatabase(NativeDatabase.memory());
      sw = Stopwatch()..start();
      final plan = await planImport(fresh, XlsxCodec.decode(bytes), fileName: 'perf.xlsx', today: LocalDate(2026, 10, 15), restore: true);
      final written = await applyImport(fresh, plan);
      results['import_ms'] = ms(sw);
      results['import_rows'] = written.values.fold<int>(0, (a, b) => a + b);
      await fresh.close();

      // Vault unlock with the real Argon2id: about 1 s, never over 2 s.
      final vdb = AppDatabase(NativeDatabase.memory());
      final vault = VaultService(vdb, SettingsRepo(vdb), DeletionsRepo(vdb), _NoBiometrics());
      await vault.create(password: 'correct horse battery', recoveryCode: 'K7QF2M9DXR4T8BWJ');
      await vault.lock();
      sw = Stopwatch()..start();
      await vault.unlock('correct horse battery');
      results['vault_unlock_ms'] = ms(sw);
      await vdb.close();
      await db.close();
    });
    binding.reportData = {...?binding.reportData, ...results};
  }, timeout: const Timeout(Duration(minutes: 10)));

  testWidgets('screens: open each main screen, then scroll the long lists', (tester) async {
    // main() installs the error log hooks; the test framework needs its own back.
    final onError = FlutterError.onError;
    await app.main();
    FlutterError.onError = onError;

    /// Pumps frames until [landmark] shows; returns the wall-clock time.
    Future<int> open(Future<void> Function() go, Finder landmark) async {
      final sw = Stopwatch()..start();
      await go();
      while (landmark.evaluate().isEmpty) {
        if (sw.elapsed > const Duration(seconds: 10)) throw TestFailure('$landmark never appeared');
        await tester.pump(const Duration(milliseconds: 4));
      }
      return ms(sw);
    }

    await open(() async {}, find.byKey(const ValueKey('bar-Finance')));
    await tester.pumpAndSettle(); // the splash (UR4-1) plays over Home first
    final opens = <String, int>{
      // Finance's tab pill: Home has a "Total savings" widget of its own.
      'savings': await open(() => tester.tap(find.byKey(const ValueKey('bar-Finance'))), find.byKey(SegmentTabs.pillKey)),
      'gold': await open(() => tester.tap(find.text('Gold').first), find.text('Estimated value')),
      'expenses': await open(() => tester.tap(find.text('Expenses').first), find.text('Spent so far this year')),
      'library': await open(() => tester.tap(find.byKey(const ValueKey('bar-Library'))), find.textContaining('All books')),
      'notes': await open(() => tester.tap(find.byKey(const ValueKey('bar-Notes'))), find.text('Pinned')),
      'home': await open(() => tester.tap(find.byKey(const ValueKey('bar-Home'))), find.byKey(const ValueKey('bar-Home'))),
    };
    // Recipes isn't in the bar by default: open it from Tools.
    await tester.tap(find.byKey(const ValueKey('bar-Tools')));
    await tester.pumpAndSettle();
    opens['recipes'] = await open(() => tester.tap(find.text('Recipes').last), find.textContaining('ready with what you have'));
    opens['recipe'] = await open(() => tester.tap(find.text('Tinola 1000')), find.text('Ingredients · 8'));
    tester.state<NavigatorState>(find.byType(Navigator).first).pop(); // detail screens open on the root navigator
    await tester.pumpAndSettle();
    opens['cook'] = await open(() => tester.tap(find.textContaining('ready with what you have')), find.text('bell pepper'));
    tester.state<NavigatorState>(find.byType(Navigator).first).pop(); // detail screens open on the root navigator
    await tester.pumpAndSettle();
    results['open_ms'] = opens;
    results['open_worst_ms'] = opens.values.reduce((a, b) => a > b ? a : b);

    Future<void> scroll(String key, Future<void> Function() go) async {
      await go();
      await tester.pumpAndSettle();
      // Frame timings straight from the engine (no VM service needed).
      final frames = <FrameTiming>[];
      void collect(List<FrameTiming> t) => frames.addAll(t);
      SchedulerBinding.instance.addTimingsCallback(collect);
      for (var i = 0; i < 4; i++) {
        await tester.fling(find.byType(Scrollable).first, const Offset(0, -1500), 4000);
        await tester.pumpAndSettle();
      }
      await tester.pump(const Duration(milliseconds: 200));
      SchedulerBinding.instance.removeTimingsCallback(collect);
      // Scrolling down hid the bar; scrolling up brings it back for the next list.
      await tester.fling(find.byType(Scrollable).first, const Offset(0, 600), 2000);
      await tester.pumpAndSettle();
      int worst(Duration Function(FrameTiming) f) => frames.map((t) => f(t).inMicroseconds).fold(0, (a, b) => a > b ? a : b);
      results['scroll_$key'] = {
        'frames': frames.length,
        'worst_build_ms': worst((t) => t.buildDuration) / 1000,
        'worst_raster_ms': worst((t) => t.rasterDuration) / 1000,
        'over_16ms': frames.where((t) => t.totalSpan.inMilliseconds > 16).length,
        'over_32ms': frames.where((t) => t.totalSpan.inMilliseconds > 32).length,
      };
    }

    await scroll('expenses', () async {
      await tester.tap(find.byKey(const ValueKey('bar-Finance')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expenses').first);
    });
    await scroll('library', () => tester.tap(find.byKey(const ValueKey('bar-Library'))));
    await scroll('notes', () => tester.tap(find.byKey(const ValueKey('bar-Notes'))));
    await scroll('recipes', () async {
      await tester.tap(find.byKey(const ValueKey('bar-Tools')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recipes').last);
    });
    binding.reportData = {...?binding.reportData, ...results};
  }, timeout: const Timeout(Duration(minutes: 10)));
}

class _NoBiometrics implements BiometricKeyStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<bool>.value(false);
}
