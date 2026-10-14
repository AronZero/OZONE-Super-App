import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/tools/finance/data/savings_repo.dart';

import '../../helpers/harness.dart';

LocalDate d(String iso) => LocalDate.parseIso(iso).valueOrNull!;

/// The W1 worked example: Payroll Savings last updated 30 Sep, Emergency Fund on 12 Oct.
Future<AppDatabase> seeded(WidgetTester tester) async {
  final db = memoryDb();
  await tester.runAsync(() async {
    final repo = SavingsRepo(db, DeletionsRepo(db));
    await repo.addAccount(name: 'Payroll Savings', platform: 'Bank', startBalance: 31240000, asOf: d('2026-09-30'));
    final ef = (await repo.addAccount(name: 'Emergency Fund', platform: 'Digital bank', startBalance: 41400000, asOf: d('2026-09-28'))).valueOrNull!;
    await repo.saveUpdate(ef, d('2026-10-12'), 42015000);
  });
  return db;
}

Future<void> openFinance(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('bar-Finance')));
  await settle(tester);
}

void main() {
  testWidgets('empty Savings, then add an account with its starting balance', (tester) async {
    final (db, _) = await pumpApp(tester);
    await openFinance(tester);
    expect(find.text('No savings accounts yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Add account'));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('account-name')), 'Emergency Fund');
    await tester.enterText(find.byKey(const ValueKey('account-balance')), '414,000');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add account'));
    await settle(tester);

    expect(find.text('Emergency Fund'), findsOneWidget);
    expect(find.text('₱414,000.00'), findsNWidgets(2)); // total and the account row
    await closeApp(tester, db);
  });

  testWidgets('the worked example on the Savings screen', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openFinance(tester);

    expect(find.text('₱732,550.00'), findsOneWidget);
    expect(find.text('▲ +₱6,150.00 vs Sep'), findsOneWidget);
    expect(find.text('2 accounts · 1 carried'), findsOneWidget);
    expect(find.text('Carried · 30 Sep'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('"Balance is unchanged" makes October Recorded', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openFinance(tester);
    await tester.tap(find.text('Update balances'));
    await settle(tester);

    expect(find.text('Needs an October balance · 1'), findsOneWidget);
    expect(find.text('Already updated in October · 1'), findsOneWidget);
    await tester.tap(find.text('Balance is unchanged'));
    await settle(tester);
    expect(find.text('Confirmed unchanged · ₱312,400.00'), findsOneWidget);
    await tester.tap(find.text('Save 1 update'));
    await settle(tester);

    expect(find.text('Carried · 30 Sep'), findsNothing);
    expect(find.text('2 accounts'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('Home shows Total savings and, from the 25th, Needs attention', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db, today: d('2026-10-25'));

    expect(find.text('Payroll Savings needs an October balance'), findsOneWidget);
    expect(find.text('₱732,550.00'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('Account detail lists months with Recorded and Start', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openFinance(tester);
    await tester.tap(find.text('Emergency Fund'));
    await settle(tester);

    expect(find.text('Oct 2026'), findsOneWidget);
    expect(find.text('● Recorded · so far'), findsOneWidget);
    expect(find.text('▲ +₱6,150.00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('— No data (before tracking)'), findsOneWidget);
    await closeApp(tester, db);
  });
}
