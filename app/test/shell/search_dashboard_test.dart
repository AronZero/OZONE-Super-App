import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/tools/finance/data/expenses_repo.dart';
import 'package:ozone/tools/finance/data/savings_repo.dart';
import 'package:ozone/tools/library/data/books_repo.dart';
import 'package:ozone/tools/library/domain/library.dart';
import 'package:ozone/tools/notes/data/notes_repo.dart';

import '../helpers/harness.dart';

Future<AppDatabase> seeded(WidgetTester tester) async {
  final db = memoryDb();
  await tester.runAsync(() async {
    final d = DeletionsRepo(db);
    await SavingsRepo(db, d).addAccount(name: 'Payroll Savings', platform: 'BPI', startBalance: 12345678, asOf: LocalDate(2026, 10, 1));
    final e = ExpensesRepo(db, d);
    for (var i = 0; i < 5; i++) {
      await e.add(ExpenseInput(item: 'Coffee beans $i', vendor: 'Café Uno', amount: 45000 + i, date: LocalDate(2026, 10, 1 + i)));
    }
    await BooksRepo(db, d).add(const BookInput(title: 'Coffee Table Book', author: 'Ann', status: BookStatus.reading, acquisition: Acquisition.free));
    final n = NotesRepo(db, d);
    final id = await n.create();
    await n.save(id, title: 'Shopping', ops: [
      {'insert': 'buy coffee filters\n'},
    ]);
  });
  return db;
}

/// Types, waits out the 150 ms debounce, and lets the query run.
Future<void> type(WidgetTester tester, String s) async {
  await tester.enterText(find.byType(TextField).first, s);
  await tester.pump(const Duration(milliseconds: 200));
  await settle(tester);
}

void main() {
  testWidgets('search: groups in bar order, see all, open a record, back keeps the query', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await tester.tap(find.byTooltip('Search'));
    await settle(tester);
    expect(find.text('Locked notes aren’t searched.'), findsOneWidget);

    await type(tester, 'c');
    expect(find.text('Type at least 2 letters or numbers. Amounts like 1,299 match exactly.'), findsOneWidget);

    await type(tester, 'cof');
    expect(find.text('7 results'), findsOneWidget);
    // Bar order: Finance (Expenses) · Library (Books) · Notes.
    final heads = ['Expenses · 5', 'Books · 1', 'Notes · 1'];
    final ys = [for (final h in heads) tester.getTopLeft(find.text(h)).dy];
    expect(ys, [...ys]..sort());
    expect(find.text('See all 5'), findsOneWidget);
    expect(find.textContaining('Café Uno'), findsNWidgets(3), reason: 'only the top 3 show before See all');

    await tester.tap(find.text('See all 5'));
    await settle(tester);
    expect(find.text('Books · 1'), findsNothing);
    expect(find.textContaining('Café Uno'), findsNWidgets(5));

    // Exact amounts, typed any way.
    await tester.tap(find.text('All'));
    await type(tester, '₱450.02');
    expect(find.text('1 result'), findsOneWidget);
    await tester.tap(find.textContaining('Coffee beans 2'));
    await settle(tester);
    expect(find.text('Expense'), findsWidgets); // Expense detail
    await tester.tap(find.byTooltip('Back to Expenses').first);
    await settle(tester);
    expect(find.text('1 result'), findsOneWidget, reason: 'back returns to the results with the query');
    await closeApp(tester, db);
  });

  testWidgets('scope from a tool, no matches, Search all, and recent searches', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await tester.tap(find.byKey(const ValueKey('bar-Library')));
    await settle(tester);
    await tester.tap(find.byTooltip('Search'));
    await settle(tester);
    await type(tester, 'filters');
    expect(find.text('No matches in Books'), findsOneWidget);
    await tester.tap(find.text('Search all'));
    await settle(tester);
    expect(find.text('Notes · 1'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    await type(tester, '');
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('filters'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await settle(tester);
    expect(find.text('Recent searches'), findsNothing);
    await closeApp(tester, db);
  });

  testWidgets('Hide amounts: the eye on Home hides every ₱ figure; the setting starts hidden', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    expect(find.text('₱123,456.78'), findsWidgets);
    await tester.tap(find.byTooltip('Hide amounts'));
    await settle(tester);
    expect(find.text('₱123,456.78'), findsNothing);
    expect(find.text('₱ ••••'), findsWidgets);
    // Other screens follow too.
    await tester.tap(find.byKey(const ValueKey('bar-Finance')));
    await settle(tester);
    expect(find.text('₱123,456.78'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('bar-Home')));
    await settle(tester);
    await tester.tap(find.byTooltip('Show amounts'));
    await settle(tester);
    expect(find.text('₱123,456.78'), findsWidgets);
    await closeApp(tester, db);
  });

  testWidgets('quick add lists every tool action and runs it', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await tester.tap(find.byTooltip('Quick add'));
    await settle(tester);
    for (final a in ['Update balances', 'Add expense', 'Add gold item', 'Add book', 'New note']) {
      expect(find.text(a), findsOneWidget);
    }
    await tester.tap(find.text('Add book'));
    await settle(tester);
    expect(find.text('Add book'), findsWidgets); // the book form
    expect(find.text('Author'), findsWidgets);
    await closeApp(tester, db);
  });

  testWidgets('Needs attention collapses to "All up to date"', (tester) async {
    final db = memoryDb();
    await tester.runAsync(() => SettingsRepo(db).get(SettingKeys.theme));
    await pumpApp(tester, db: db);
    expect(find.text('All up to date'), findsOneWidget);
    await closeApp(tester, db);
  });
}
