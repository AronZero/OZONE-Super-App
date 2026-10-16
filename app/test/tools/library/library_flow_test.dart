import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/ui/components/components.dart';
import 'package:ozone/tools/library/data/books_repo.dart';
import 'package:ozone/tools/library/domain/library.dart';

import '../../helpers/harness.dart';

/// A few books from the W2 · Library board (sample data).
Future<AppDatabase> seeded(WidgetTester tester) async {
  final db = memoryDb();
  await tester.runAsync(() async {
    final r = BooksRepo(db, DeletionsRepo(db));
    await r.add(BookInput(
      title: 'Project Hail Mary', author: 'Andy Weir', sizeKb: 4300, onKindle: true, status: BookStatus.reading,
      acquisition: Acquisition.purchased, acquired: LocalDate(2026, 9, 18), amount: 59900,
    ));
    await r.add(BookInput(
      title: 'Pride and Prejudice', author: 'Jane Austen', sizeKb: 812, onKindle: true, status: BookStatus.finished,
      acquisition: Acquisition.free, acquired: LocalDate(2025, 3, 2), ratingHalf: 9,
    ));
    await r.add(BookInput(
      title: 'Dune', author: 'Frank Herbert', status: BookStatus.notStarted, remarks: 'Gift',
      acquisition: Acquisition.purchased, acquired: LocalDate(2024, 1, 5), amount: 45000,
    ));
  });
  return db;
}

Future<void> openLibrary(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('bar-Library')));
  await settle(tester);
}

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await settle(tester);
}

void main() {
  testWidgets('list, header counts, status filter and sort', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openLibrary(tester);

    expect(find.text('3 books · 2 on Kindle'), findsOneWidget);
    expect(find.text('Kindle · 4.2 MB'), findsOneWidget);
    expect(find.text('Kindle · 812 KB'), findsOneWidget);
    expect(find.text('★ 4.5'), findsOneWidget);

    await tester.tap(find.text('Reading').first);
    await settle(tester);
    expect(find.text('Reading · 1'), findsOneWidget);
    expect(find.text('Dune'), findsNothing);
    await closeApp(tester, db);
  });

  testWidgets('Add book: amount appears and is required only for Purchased', (tester) async {
    final (db, _) = await pumpApp(tester);
    await openLibrary(tester);
    await tester.tap(find.byTooltip('Add book'));
    await settle(tester);

    await tester.enterText(find.byKey(const ValueKey('book-title')), 'The Name of the Rose');
    expect(find.byKey(const ValueKey('book-amount')), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save book'));
    expect(find.text('Enter what you paid'), findsOneWidget);

    await tapVisible(tester, find.text('Free'));
    expect(find.byKey(const ValueKey('book-amount')), findsNothing);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save book'));
    expect(find.text('The Name of the Rose'), findsOneWidget);
    expect(find.text('1 book · 1 on Kindle'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('Book detail: rating steps in halves; Not rated differs from 0', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openLibrary(tester);
    await tester.tap(find.text('Dune'));
    await settle(tester);

    expect(find.text('Not rated'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Lower rating by half a star'));
    expect(find.text('0.0'), findsOneWidget); // a real 0-star rating
    await tapVisible(tester, find.byTooltip('Raise rating by half a star'));
    await tapVisible(tester, find.byTooltip('Raise rating by half a star'));
    await tapVisible(tester, find.byTooltip('Raise rating by half a star'));
    expect(find.text('1.5'), findsOneWidget);
    await tapVisible(tester, find.text('Clear rating'));
    expect(find.text('Not rated'), findsOneWidget);

    await tapVisible(tester, find.text('Finished'));
    // The picked chip's tick has grown in.
    final tick = find.descendant(of: find.ancestor(of: find.text('Finished'), matching: find.byType(Row)).first, matching: find.byType(AnimatedContainer));
    expect(tester.getSize(tick).width, 19);
    await closeApp(tester, db);
  });

  testWidgets('Book detail: Remarks is always full width, even for short text', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openLibrary(tester);
    await tester.tap(find.text('Dune'));
    await settle(tester);
    await tester.ensureVisible(find.text('Gift'));
    await tester.pumpAndSettle();
    final card = tester.getSize(find.byType(GroupCard)).width;
    final block = tester.getSize(find.ancestor(of: find.text('Gift'), matching: find.byType(Padding)).first).width;
    expect(block, card);
    await closeApp(tester, db);
  });

  testWidgets('Library stats and the Currently reading widget', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    expect(find.text('Currently reading'), findsOneWidget);
    expect(find.textContaining('Project Hail Mary'), findsOneWidget);

    await openLibrary(tester);
    await tester.tap(find.text('Stats'));
    await settle(tester);
    expect(find.text('5.0 MB'), findsOneWidget); // 4,300 + 812 = 5,112 KB
    expect(find.text('₱1,049.00'), findsOneWidget);
    expect(find.text('★ 4.5'), findsOneWidget);
    expect(find.text('1 rated · 2 not rated'), findsOneWidget);
    await closeApp(tester, db);
  });
}
