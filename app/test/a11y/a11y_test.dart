import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/tools/finance/data/expenses_repo.dart';
import 'package:ozone/tools/finance/data/gold_repo.dart';
import 'package:ozone/tools/finance/data/savings_repo.dart';
import 'package:ozone/tools/library/data/books_repo.dart';
import 'package:ozone/tools/library/domain/library.dart';
import 'package:ozone/tools/notes/data/notes_repo.dart';

import '../helpers/harness.dart';

/// Accessibility pass (docs/04 â€º Accessibility, F3-03 Â§4): every screen in both
/// themes, at 100% and 200% text, on the A03's screen (720 Ã— 1600 px, 280 dpi).
/// Checks 48 dp touch targets, labelled controls and no overflow. Contrast is
/// checked exactly on the colour tokens (contrast_test.dart): the screenshot
/// heuristic mixes icons and highlight pills into the text colour.

typedef Ids = ({String account, String expense, String book, String note});

Future<(AppDatabase, Ids)> seeded(WidgetTester tester) async {
  final db = memoryDb();
  late Ids ids;
  await tester.runAsync(() async {
    final d = DeletionsRepo(db);
    final s = SavingsRepo(db, d);
    await s.addAccount(name: 'Emergency Fund', platform: 'BPI', type: 'Savings', startBalance: 12345678, asOf: LocalDate(2026, 8, 31));
    final account = (await db.select(db.savingsAccounts).get()).single.id;
    await s.saveUpdate(account, LocalDate(2026, 9, 30), 12500000);
    final g = GoldRepo(db, d);
    await g.savePrices(LocalDate(2026, 10, 1), {18: 520000, 21: 610000});
    await g.addItem(GoldItemInput(name: 'Wedding ring', weightMg: 4250, karat: 18, vendor: 'Goldsmith', purchaseDate: LocalDate(2024, 2, 14), cost: 1850000));
    final e = ExpensesRepo(db, d);
    String? expense;
    for (var i = 0; i < 6; i++) {
      expense = await e.add(ExpenseInput(item: 'Groceries week $i', vendor: 'SM Supermarket', amount: 245050 + i, date: LocalDate(2026, 10, 1 + i)));
    }
    await e.add(ExpenseInput(item: 'Headphones', vendor: 'Lazada', amount: 389900, date: LocalDate(2025, 6, 3)));
    final book = await BooksRepo(db, d).add(const BookInput(
        title: 'A Long Book Title That Wraps Across Lines', author: 'Some Author', status: BookStatus.reading, acquisition: Acquisition.purchased, amount: 59900, ratingHalf: 7));
    final n = NotesRepo(db, d);
    final note = await n.create();
    await n.save(note, title: 'Trip plan', ops: [
      {'insert': 'Book flights and hotel\n'},
    ]);
    ids = (account: account, expense: expense!, book: book, note: note);
  });
  return (db, ids);
}

void main() {
  // Real Manrope metrics (tests otherwise draw every letter as a wide square).
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader('Manrope')..addFont(rootBundle.load('assets/fonts/Manrope/Manrope-VariableFont_wght.ttf'))).load();
  });

  final routes = <String Function(Ids)>[
    (_) => '/home',
    (_) => '/finance?tab=savings',
    (_) => '/finance?tab=gold',
    (_) => '/finance?tab=expenses',
    (_) => '/finance/savings/update',
    (_) => '/finance/savings/history',
    (_) => '/finance/savings/archived',
    (i) => '/finance/savings/accounts/${i.account}',
    (_) => '/finance/gold/prices',
    (_) => '/finance/gold/prices/history',
    (_) => '/finance/gold/disposed',
    (_) => '/finance/expenses/years',
    (i) => '/finance/expenses/${i.expense}',
    (_) => '/finance/lists',
    (_) => '/library',
    (_) => '/library/add',
    (_) => '/library/stats',
    (i) => '/library/books/${i.book}',
    (_) => '/notes',
    (i) => '/notes/n/${i.note}',
    (_) => '/notes/manage',
    (_) => '/notes/trash',
    (_) => '/tools',
    (_) => '/search',
    (_) => '/settings',
    (_) => '/settings/appearance',
    (_) => '/settings/dashboard',
    (_) => '/settings/security',
    (_) => '/settings/about',
    (_) => '/settings/finance',
    (_) => '/settings/data',
    (_) => '/settings/data/safety',
    (_) => '/edit-bar',
    (_) => '/welcome',
  ];
  // Route names for test titles (IDs are only known once seeded).
  const ids = (account: ':account', expense: ':expense', book: ':book', note: ':note');

  for (final route in routes) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${route(ids)} Â· ${dark ? 'dark' : 'light'} Â· ${(scale * 100).round()}%', (tester) async {
          tester.view
            ..physicalSize = const Size(720, 1600)
            ..devicePixelRatio = 1.75;
          tester.platformDispatcher
            ..platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light
            ..textScaleFactorTestValue = scale;
          addTearDown(() {
            tester.view.reset();
            tester.platformDispatcher.clearAllTestValues();
          });
          final semantics = tester.ensureSemantics();
          final (db, i) = await seeded(tester);
          await pumpApp(tester, db: db, initialLocation: route(i));

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          // TalkBack reads amounts as pesos and centavos, never "peso sign 1,234.56".
          final raw = [for (final n in find.semantics.byPredicate((n) => n.label.contains('₱')).evaluate()) n.label];
          expect(raw, isEmpty, reason: 'amounts read with the peso sign');

          semantics.dispose();
          await closeApp(tester, db);
        });
      }
    }
  }
}
