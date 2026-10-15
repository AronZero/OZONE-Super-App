import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/workbook/ozone_export.dart';
import 'package:ozone/core/workbook/workbook.dart';
import 'package:ozone/shell/ui/backup/export_screen.dart';
import 'package:ozone/shell/ui/backup/import_screen.dart';
import 'package:ozone/tools/finance/data/expenses_repo.dart';
import 'package:ozone/tools/library/data/books_repo.dart';
import 'package:ozone/tools/library/domain/library.dart';

import '../helpers/harness.dart';

Future<AppDatabase> seeded(WidgetTester tester) async {
  final db = memoryDb();
  await tester.runAsync(() async {
    final d = DeletionsRepo(db);
    await ExpensesRepo(db, d).add(ExpenseInput(item: 'Rice cooker', vendor: 'Lazada', amount: 129900, date: LocalDate(2026, 9, 1)));
    await BooksRepo(db, d).add(const BookInput(title: 'Dune', status: BookStatus.reading, acquisition: Acquisition.free));
  });
  return db;
}

/// Lets file and database work finish (they run on real async), then settles.
/// Spinners animate forever, so this pumps frames until they're gone.
Future<void> work(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
    if (i >= 3 && find.byType(CircularProgressIndicator).evaluate().isEmpty && find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}

Future<void> openData(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await settle(tester);
  await tester.ensureVisible(find.text('Data & backup'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Data & backup'));
  await settle(tester);
}

void main() {
  testWidgets('export: progress, Save to, "Export saved", last export moves', (tester) async {
    final db = await seeded(tester);
    String? savedPath;
    await pumpApp(tester, db: db, overrides: [
      saveAsProvider.overrideWithValue((path, name) async {
        savedPath = path;
        return name;
      }),
    ]);
    await openData(tester);
    expect(find.text('No export yet'), findsOneWidget);
    await tester.tap(find.text('Export now'));
    await work(tester);
    expect(find.text('Export saved'), findsOneWidget);
    expect(find.text('OZONE-2026-10-13.xlsx'), findsNothing, reason: 'named by the real date, not the test date');
    expect(find.textContaining('This file isn’t encrypted.'), findsOneWidget);
    expect(File(savedPath!).existsSync(), isTrue);
    final book = await tester.runAsync(() async => XlsxCodec.decode(await File(savedPath!).readAsBytes()));
    expect(rowCounts(book!)['Expenses'], 1);
    await tester.tap(find.text('Done'));
    await work(tester);
    expect(find.textContaining('Last export:'), findsOneWidget);
    expect(find.textContaining('today'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('import: preview counts, Use file’s, safety export, summary', (tester) async {
    final db = await seeded(tester);
    // A workbook from this phone with one changed row and one new row.
    final bytes = await tester.runAsync(() async {
      final book = XlsxCodec.decode(XlsxCodec.encode(await buildWorkbook(db, appVersion: 't')));
      final e = book.sheet('Expenses')!;
      e.rows[0][e.column('Remarks')!] = 'Gift for Mom';
      e.rows.add([null, 'Coffee', 'Café Uno', 450.0, LocalDate(2026, 10, 1), 'No', null, null, null]);
      return XlsxCodec.encode(book);
    });
    await pumpApp(tester, db: db, overrides: [pickWorkbookProvider.overrideWithValue(() async => ('OZONE-2026-09-02.xlsx', bytes!))]);
    await openData(tester);
    await tester.tap(find.text('Choose a file…'));
    await work(tester);
    expect(find.text('Import preview'), findsOneWidget);
    expect(find.text('OZONE-2026-09-02.xlsx'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Expenses: 1 new, 1 changed, 0 same, 0 to check'), findsOneWidget);
    expect(find.text('Import 1 row'), findsOneWidget, reason: 'Changed defaults to Keep mine');
    expect(find.text('Yours: “—”'), findsOneWidget);
    expect(find.text('File: “Gift for Mom”'), findsOneWidget);
    await tester.ensureVisible(find.text('Use file’s'));
    await tester.tap(find.text('Use file’s'));
    await settle(tester);
    expect(find.text('Import 2 rows'), findsOneWidget);
    await tester.tap(find.text('Import 2 rows'));
    await work(tester);
    expect(find.text('Imported 2 rows'), findsOneWidget);
    expect(find.textContaining('To go back, import the safety export from'), findsOneWidget);
    final rows = await tester.runAsync(() => db.select(db.expenses).get());
    expect(rows!.length, 2);
    expect(rows.firstWhere((r) => r.item == 'Rice cooker').remarks, 'Gift for Mom');
    await closeApp(tester, db);
  });

  testWidgets('a file that isn’t OZONE’s is refused in words', (tester) async {
    final db = await seeded(tester);
    final bytes = XlsxCodec.encode(Workbook([WbSheet('Budget', ['A', 'B'], [['x', 'y']])]));
    await pumpApp(tester, db: db, overrides: [pickWorkbookProvider.overrideWithValue(() async => ('budget.xlsx', bytes))]);
    await openData(tester);
    await tester.tap(find.text('Choose a file…'));
    await work(tester);
    expect(find.text('This file can’t be imported'), findsOneWidget);
    expect(find.textContaining('This isn’t an OZONE workbook.'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('first run: Welcome → Restore → reminder ask → Home with the summary', (tester) async {
    final source = await seeded(tester);
    final bytes = await tester.runAsync(() async => XlsxCodec.encode(await buildWorkbook(source, appVersion: 't')));
    final db = memoryDb();
    final reminders = FakeReminderPlatform();
    await pumpApp(tester, db: db, initialLocation: '/welcome', reminders: reminders, overrides: [
      pickWorkbookProvider.overrideWithValue(() async => ('OZONE-2026-10-13.xlsx', bytes!)),
    ]);
    expect(find.text('Start fresh'), findsOneWidget);
    await tester.tap(find.text('Restore from a workbook'));
    await work(tester);
    expect(find.text('Restore 2 rows'), findsOneWidget);
    await tester.tap(find.text('Restore 2 rows'));
    await work(tester);
    expect(find.text('Get a month-end reminder?'), findsOneWidget);
    await tester.tap(find.text('Turn on'));
    await work(tester);
    expect(reminders.asked, isTrue);
    expect(reminders.scheduled, isNotNull);
    expect(reminders.body, startsWith('Update your savings balances for '));
    expect(find.text('Restored from OZONE-2026-10-13.xlsx · 2 rows'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    await closeApp(tester, db);
    await source.close();
  });

  testWidgets('first run: Start fresh → Not now leaves the reminder off', (tester) async {
    final db = memoryDb();
    final reminders = FakeReminderPlatform();
    await pumpApp(tester, db: db, initialLocation: '/welcome', reminders: reminders);
    await tester.tap(find.text('Start fresh'));
    await work(tester);
    await tester.tap(find.text('Not now'));
    await work(tester);
    expect(reminders.asked, isFalse);
    expect(reminders.scheduled, isNull);
    expect(find.text('All up to date'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('Needs attention says when no backup was made after the reminder period', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db, today: LocalDate.fromDateTime(DateTime.now().add(const Duration(days: 40))));
    expect(find.text('No backup exported yet'), findsOneWidget);
    await closeApp(tester, db);
  });
}
