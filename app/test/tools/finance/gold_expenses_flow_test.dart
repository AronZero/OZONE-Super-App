import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/tools/finance/data/expenses_repo.dart';
import 'package:ozone/tools/finance/data/gold_repo.dart';

import '../../helpers/harness.dart';

LocalDate d(String iso) => LocalDate.parseIso(iso).valueOrNull!;

/// The W2 · Gold board's items and prices (sample data), plus a few expenses.
Future<AppDatabase> seeded(WidgetTester tester, {bool withoutChainPrice = false}) async {
  final db = memoryDb();
  await tester.runAsync(() async {
    final gold = GoldRepo(db, DeletionsRepo(db));
    GoldItemInput i(String n, int mg, int k, int cost) =>
        GoldItemInput(name: n, weightMg: mg, karat: k, purchaseDate: d('2026-01-10'), cost: cost);
    await gold.addItem(i('Gold bangle', 25000, 18, 11822000));
    await gold.addItem(i('Gold chain', 20300, 21, 11250000));
    await gold.addItem(i('Gold bar', 10000, 24, 6420000));
    await gold.addItem(i('Gold wedding bands', 12500, 18, 5800000));
    await gold.addItem(i('Ring', 14600, 14, 5000000));
    await gold.savePrices(d('2026-10-02'), {24: 735000, if (!withoutChainPrice) 21: 643000, 18: 551000, 14: 430000});

    final ex = ExpensesRepo(db, DeletionsRepo(db));
    await ex.add(ExpenseInput(item: 'Air fryer', vendor: 'Shopee', amount: 349900, date: d('2026-10-03')));
    await ex.add(ExpenseInput(item: 'USB-C cables, 3-pack', vendor: 'Lazada', amount: 130000, date: d('2026-10-09')));
    await ex.add(ExpenseInput(item: 'Running shoes', vendor: 'Lazada', amount: 425000, date: d('2026-09-28')));
    await ex.add(ExpenseInput(item: 'Lamp', vendor: 'Lazada', amount: 100000, date: d('2025-03-01')));
  });
  return db;
}

Future<void> openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.byKey(const ValueKey('bar-Finance')));
  await settle(tester);
  await tester.tap(find.text(tab));
  await settle(tester);
}

void main() {
  testWidgets('Gold tab reproduces the board totals', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openTab(tester, 'Gold');

    expect(find.text('₱473,434.00'), findsOneWidget);
    expect(find.text('▲ +₱70,514.00 · 17.5%'), findsOneWidget);
    expect(find.text('82.400 g'), findsOneWidget);
    expect(find.text('₱402,920.00'), findsOneWidget);
    expect(find.text('Items · 5'), findsOneWidget);
    expect(find.text('₱137,750.00'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('an item with no price is named, and Home flags it', (tester) async {
    final db = await seeded(tester, withoutChainPrice: true);
    await pumpApp(tester, db: db);
    expect(find.text('No price for 21K'), findsOneWidget);
    await openTab(tester, 'Gold');
    expect(find.text('Value leaves out 1 item with no 21K price'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('No 21K price'), 200);
    expect(find.text('No 21K price'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('Expenses: this year so far, and refunded leaves every total', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openTab(tester, 'Expenses');

    expect(find.text('₱9,049.00'), findsOneWidget); // 3,499 + 1,300 + 4,250
    expect(find.text('▲ +804.9% vs same period in 2025 (₱1,000.00)'), findsOneWidget);

    await tester.tap(find.text('USB-C cables, 3-pack'));
    await settle(tester);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('REFUNDED'), findsOneWidget);
    expect(find.text('Not counted in 2026 spending'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to Expenses'));
    await settle(tester);
    expect(find.text('₱7,749.00'), findsOneWidget);
    expect(find.text('REFUNDED'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('screen readers get the Refunded switch and karat names', (tester) async {
    final handle = tester.ensureSemantics();
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openTab(tester, 'Gold');
    expect(find.bySemanticsLabel(RegExp(r'^Gold bangle, 18 karat')), findsOneWidget);
    await openTab(tester, 'Expenses');
    await tester.tap(find.text('Air fryer'));
    await settle(tester);
    final node = tester.getSemantics(find.byType(Switch));
    expect(node.label, contains('Refunded'));
    expect(node.flagsCollection.isToggled, isNotNull);
    handle.dispose();
    await closeApp(tester, db);
  });

  testWidgets('a possible duplicate warns before saving', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openTab(tester, 'Expenses');
    await tester.tap(find.byTooltip('Add expense'));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('expense-item')), 'Cable');
    await tester.enterText(find.byKey(const ValueKey('expense-amount')), '500');
    await tester.enterText(find.byKey(const ValueKey('expense-vendor')), 'Lazada');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save & add another'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save & add another'));
    await settle(tester);
    expect(find.text('Saved Cable · ₱500.00'), findsOneWidget);
    // The vendor and date are kept for the next one.
    await tester.enterText(find.byKey(const ValueKey('expense-item')), 'Cables again');
    await tester.enterText(find.byKey(const ValueKey('expense-amount')), '500');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    expect(find.text('Possible duplicate'), findsOneWidget);
    await tester.tap(find.text('Save anyway'));
    await settle(tester);
    expect(find.text('Cables again'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('Spending by year opens from the Expenses card', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openTab(tester, 'Expenses');
    await tester.tap(find.text('Yearly report'));
    await settle(tester);
    expect(find.text('Spending by year'), findsOneWidget);
    await tester.tap(find.text('Table'));
    await settle(tester);
    expect(find.text('₱9,049.00'), findsOneWidget);
    expect(find.text('₱1,000.00'), findsOneWidget);
    await closeApp(tester, db);
  });
}
