import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/tools/notes/data/notes_repo.dart';
import 'package:ozone/tools/notes/ui/notes_parts.dart' show NoteCard;

import '../../helpers/harness.dart';

Future<void> openNotes(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('bar-Notes')));
  await settle(tester);
}

/// Types into the open note's body, as the keyboard would.
void typeBody(WidgetTester tester, String s) {
  final q = tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;
  final at = q.document.length - 1;
  q.replaceText(at, 0, s, TextSelection.collapsed(offset: at + s.length));
}

/// Waits out the 1 s autosave on the test clock, then lets the database finish.
Future<void> afterAutosave(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1200));
  await settle(tester);
}

Future<AppDatabase> seeded(WidgetTester tester) async {
  final db = memoryDb();
  await tester.runAsync(() async {
    final r = NotesRepo(db, DeletionsRepo(db));
    final travel = await r.addFolder('Travel');
    await r.addFolder('Work');
    final tag = await r.ensureTag('travel');
    final trip = await r.create(folderId: travel, tagIds: [tag]);
    await r.save(trip, title: 'Trip plan', ops: [
      {'insert': 'Flights on the 24th\n'},
    ]);
    await r.setPinned(trip, true);
    final g = await r.create();
    await r.save(g, title: 'Groceries', ops: [
      {'insert': 'Rice'},
      {'insert': '\n', 'attributes': {'list': 'checked'}},
      {'insert': 'Eggs'},
      {'insert': '\n', 'attributes': {'list': 'unchecked'}},
    ]);
  });
  return db;
}

void main() {
  testWidgets('empty Notes; a new note saves itself and shows on the list', (tester) async {
    final (db, _) = await pumpApp(tester);
    await openNotes(tester);
    expect(find.text('No notes yet'), findsOneWidget);

    await tester.tap(find.byTooltip('New note'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Trip plan');
    typeBody(tester, 'Flights on the 24th');
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);
    await afterAutosave(tester);
    expect(find.text('Saved'), findsOneWidget);

    final saved = await tester.runAsync(() => db.select(db.notes).getSingle());
    expect(saved!.title, 'Trip plan');
    expect(saved.plainText, 'Flights on the 24th');

    await tester.tap(find.byTooltip('Back to Notes'));
    await settle(tester);
    expect(find.text('Trip plan'), findsOneWidget);
    expect(find.text('Flights on the 24th'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('a new note left empty is deleted silently', (tester) async {
    final (db, _) = await pumpApp(tester);
    await openNotes(tester);
    await tester.tap(find.byTooltip('New note'));
    await settle(tester);
    await tester.tap(find.byTooltip('Back to Notes'));
    await settle(tester);
    expect(find.text('No notes yet'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.notes).get()), isEmpty);
    await closeApp(tester, db);
  });

  testWidgets('pinned first, folder and tag filters, list view', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openNotes(tester);
    expect(find.text('Pinned'), findsOneWidget);
    expect(find.text('All notes'), findsOneWidget);
    expect(find.text('All · 2'), findsOneWidget);
    expect(find.text('☑ Rice ☐ Eggs'), findsOneWidget);

    await tester.tap(find.text('Travel'));
    await settle(tester);
    expect(find.text('Groceries'), findsNothing);
    expect(find.text('Trip plan'), findsOneWidget);

    await tester.tap(find.text('All · 2'));
    await settle(tester);
    await tester.tap(find.text('#travel').first);
    await settle(tester);
    expect(find.text('Groceries'), findsNothing);

    await tester.tap(find.byTooltip('Switch to list view'));
    await settle(tester);
    expect(find.byTooltip('Switch to grid view'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('long tags stay on one line; the date stays at the right edge', (tester) async {
    final db = memoryDb();
    await tester.runAsync(() async {
      final r = NotesRepo(db, DeletionsRepo(db));
      final long = await r.ensureTag('veryloooooooooooooooooooooooooooongtag');
      final short = await r.ensureTag('x');
      final a = await r.create(tagIds: [long]);
      await r.save(a, title: 'Long', ops: [{'insert': 'a\n'}]);
      final b = await r.create(tagIds: [short]);
      await r.save(b, title: 'Short', ops: [{'insert': 'b\n'}]);
    });
    await pumpApp(tester, db: db);
    await openNotes(tester);

    Future<void> check() async {
      final tagText = find.text('#veryloooooooooooooooooooooooooooongtag').first;
      // One line high, no overflow.
      expect(tester.getSize(tagText).height, lessThan(20));
      expect(tester.takeException(), isNull);
      // Every date's right edge lines up, whatever the tag length.
      final dates = find.byWidgetPredicate((w) => w is Text && RegExp(r'^\d{1,2} [A-Z][a-z]{2}( \d{4})?$').hasMatch(w.data ?? ''));
      expect(dates, findsNWidgets(2));
      final rights = {for (final e in dates.evaluate()) tester.getRect(find.byWidget(e.widget)).right};
      final cardRights = {
        for (final e in find.byType(NoteCard).evaluate()) tester.getRect(find.byWidget(e.widget)).right - 14,
      };
      expect(rights.length, lessThanOrEqualTo(2)); // one per grid column
      for (final r in rights) {
        expect(cardRights.any((c) => (c - r).abs() < 0.5), isTrue, reason: 'date at $r, cards end at $cardRights');
      }
    }

    await check();
    await tester.tap(find.byTooltip('Switch to list view'));
    await settle(tester);
    await check();
    await closeApp(tester, db);
  });

  testWidgets('menu: unpin, move to trash with Undo, restore from Trash', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openNotes(tester);
    await tester.tap(find.text('Trip plan'));
    await settle(tester);
    expect(find.text('Trip plan'), findsOneWidget); // the title field

    await tester.tap(find.byTooltip('Note options: folder, tags, lock, move to trash'));
    await settle(tester);
    expect(find.text('Move to folder'), findsOneWidget);
    expect(find.text('Travel ›'), findsOneWidget);
    await tester.tap(find.text('Unpin'));
    await settle(tester);
    expect(find.text('Pin to top'), findsOneWidget);

    await tester.tap(find.text('Move to trash'));
    await settle(tester);
    expect(find.text('Trip plan moved to trash'), findsOneWidget);
    expect(find.text('Pinned'), findsNothing);
    expect(find.text('All · 1'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('All · 2'), findsOneWidget);

    // Trash it again, then restore from the Trash screen.
    await tester.tap(find.text('Trip plan'));
    await settle(tester);
    await tester.tap(find.byTooltip('Note options: folder, tags, lock, move to trash'));
    await settle(tester);
    await tester.tap(find.text('Move to trash'));
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);

    await tester.tap(find.byTooltip('Notes options: folders, tags, trash'));
    await settle(tester);
    expect(find.text('Trash · 1'), findsOneWidget);
    await tester.tap(find.text('Trash · 1'));
    await settle(tester);
    expect(find.text('30 days left'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await settle(tester);
    expect(find.text('Trash is empty'), findsOneWidget);
    expect(find.text('Trip plan restored'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('Folders & tags: new folder, delete folder keeps notes', (tester) async {
    final db = await seeded(tester);
    await pumpApp(tester, db: db);
    await openNotes(tester);
    await tester.tap(find.byTooltip('Notes options: folders, tags, trash'));
    await settle(tester);
    expect(find.text('Folders · 2'), findsOneWidget);
    expect(find.text('Unfiled'), findsOneWidget);

    await tester.tap(find.text('New folder'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'travel');
    await tester.tap(find.text('Create'));
    await settle(tester);
    expect(find.text('A folder with this name already exists'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Personal');
    await tester.tap(find.text('Create'));
    await settle(tester);
    expect(find.text('Folders · 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete folder Travel'));
    await settle(tester);
    expect(find.text('Its 1 note move to Unfiled. No note is deleted.'), findsOneWidget);
    await tester.tap(find.text('Delete folder'));
    await settle(tester);
    expect(find.text('Folders · 2'), findsOneWidget);
    expect(find.text('2 notes · default, can\'t be removed'), findsOneWidget);

    await tester.tap(find.text('Tags · 1'));
    await settle(tester);
    expect(find.text('#travel'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('recovered draft shows the banner; Keep saves it', (tester) async {
    final db = await seeded(tester);
    late String id;
    await tester.runAsync(() async {
      final r = NotesRepo(db, DeletionsRepo(db), clock: () => DateTime.now().toUtc().millisecondsSinceEpoch + 60000);
      id = (await db.select(db.notes).get()).firstWhere((n) => n.title == 'Groceries').id;
      await r.writeDraft(id, title: 'Groceries', ops: [
        {'insert': 'Rice and coffee\n'},
      ]);
    });
    await pumpApp(tester, db: db);
    await openNotes(tester);
    await tester.tap(find.text('Groceries'));
    await settle(tester);
    expect(find.text('Recovered unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await settle(tester);
    expect(find.text('Recovered unsaved changes'), findsNothing);
    final n = await tester.runAsync(() => (db.select(db.notes)..where((x) => x.id.equals(id))).getSingle());
    expect(n!.plainText, 'Rice and coffee');
    await closeApp(tester, db);
  });
}
