import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/tools/notes/data/notes_repo.dart';
import 'package:ozone/tools/notes/state/note_autosave.dart';

import '../../../helpers/harness.dart';

const _day = Duration.millisecondsPerDay;

List<Object?> _text(String s) => [
      {'insert': '$s\n'},
    ];

void main() {
  late AppDatabase db;
  late DeletionsRepo deletions;
  var now = 1000 * _day;
  late NotesRepo repo;

  setUp(() {
    db = memoryDb();
    deletions = DeletionsRepo(db);
    now = 1000 * _day;
    repo = NotesRepo(db, deletions, clock: () => now);
  });
  tearDown(() => db.close());

  group('saving', () {
    test('save writes title, Delta, plain text and edited_at; the draft goes', () async {
      final id = await repo.create();
      await repo.writeDraft(id, title: 'Trip', ops: _text('Flights'));
      now += 5000;
      expect(await repo.save(id, title: ' Trip plan ', ops: _text('Flights on the 24th')), isTrue);
      final n = (await repo.note(id))!;
      expect(n.title, 'Trip plan');
      expect(n.plainText, 'Flights on the 24th');
      expect(jsonDecode(n.content!), [{'insert': 'Flights on the 24th\n'}]);
      expect(n.editedAt, now);
      expect(await db.select(db.noteDrafts).get(), isEmpty);
    });

    test('saving the same content changes nothing', () async {
      final id = await repo.create();
      await repo.save(id, title: 'A', ops: _text('b'));
      final first = (await repo.note(id))!.editedAt;
      now += 60000;
      expect(await repo.save(id, title: 'A', ops: _text('b')), isFalse);
      expect((await repo.note(id))!.editedAt, first);
    });

    test('a draft newer than the last save is recoverable', () async {
      final id = await repo.create();
      await repo.save(id, title: 'A', ops: _text('saved'));
      now += 3000;
      await repo.writeDraft(id, title: 'A', ops: _text('saved and more'));
      final d = (await repo.recoverableDraft(id))!;
      expect(d.ops, _text('saved and more'));
      await repo.discardDraft(id);
      expect(await repo.recoverableDraft(id), isNull);
    });
  });

  group('blank new notes (F2-02 §3)', () {
    test('a new note left empty is deleted silently, without a tombstone', () async {
      final id = await repo.create();
      expect(await repo.deleteIfBlankNew(id), isTrue);
      expect(await repo.note(id), isNull);
      expect(await deletions.isDeleted(noteEntity, id), isFalse);
    });

    test('a note with text, or a draft with text, stays', () async {
      final a = await repo.create();
      now += 10;
      await repo.save(a, title: '', ops: _text('hello'));
      expect(await repo.deleteIfBlankNew(a), isFalse);

      final b = await repo.create();
      await repo.writeDraft(b, title: 'typed', ops: _text(''));
      expect(await repo.deleteIfBlankNew(b), isFalse);
    });

    test('an old note emptied later is kept', () async {
      final id = await repo.create();
      now += 10;
      await repo.save(id, title: 'X', ops: _text('y'));
      await repo.save(id, title: '', ops: _text(''));
      expect(await repo.deleteIfBlankNew(id), isFalse);
    });
  });

  group('trash (F2-02 §5)', () {
    test('trash, restore, delete forever writes a tombstone', () async {
      final id = await repo.create();
      await repo.save(id, title: 'T', ops: _text('x'));
      await repo.trash(id);
      var data = await repo.load();
      expect(data.live, isEmpty);
      expect(data.trashed.single.id, id);
      await repo.restore(id);
      data = await repo.load();
      expect(data.live.single.id, id);
      await repo.deleteForever(id);
      expect(await repo.note(id), isNull);
      expect(await deletions.isDeleted(noteEntity, id), isTrue);
    });

    test('purge deletes notes trashed over 30 days ago, and blank leftovers', () async {
      final old = await repo.create();
      final recent = await repo.create();
      final blank = await repo.create();
      now += 10;
      await repo.save(old, title: 'old', ops: _text('x'));
      await repo.save(recent, title: 'recent', ops: _text('x'));
      await repo.trash(old);
      now += 20 * _day;
      await repo.trash(recent);
      now += 11 * _day;
      expect(await repo.purge(), 1);
      expect(await repo.note(old), isNull);
      expect(await deletions.isDeleted(noteEntity, old), isTrue);
      expect(await repo.note(recent), isNotNull);
      expect(await repo.note(blank), isNull);
      expect(await deletions.isDeleted(noteEntity, blank), isFalse);
    });

    test('empty trash deletes every trashed note', () async {
      final a = await repo.create(), b = await repo.create(), c = await repo.create();
      now += 10;
      for (final id in [a, b, c]) {
        await repo.save(id, title: id, ops: _text('x'));
      }
      await repo.trash(a);
      await repo.trash(b);
      expect(await repo.emptyTrash(), 2);
      expect((await repo.load()).notes.single.id, c);
    });
  });

  group('folders and tags (F2-02 §4)', () {
    test('deleting a folder moves its notes to Unfiled', () async {
      final f = await repo.addFolder('Travel');
      final id = await repo.create(folderId: f);
      now += 10;
      await repo.save(id, title: 'Trip', ops: _text('x'));
      await repo.deleteFolder(f);
      final data = await repo.load();
      expect(data.folders, isEmpty);
      expect(data.byId(id)!.folderId, isNull);
      expect(await deletions.isDeleted(folderEntity, f), isTrue);
    });

    test('folders keep their order', () async {
      await repo.addFolder('Travel');
      await repo.addFolder('Personal');
      await repo.addFolder('Work');
      expect([for (final f in (await repo.load()).folders) f.name], ['Travel', 'Personal', 'Work']);
    });

    test('merge moves notes to the other tag; renaming onto a name merges', () async {
      final travel = await repo.ensureTag('travel');
      final trips = await repo.ensureTag('trips');
      final ideas = await repo.ensureTag('ideas');
      final a = await repo.create(tagIds: [travel]);
      final b = await repo.create(tagIds: [trips, travel]);
      final c = await repo.create(tagIds: [trips]);
      await repo.mergeTag(trips, travel);
      var data = await repo.load();
      expect(data.tags.map((t) => t.name), ['ideas', 'travel']);
      for (final id in [a, b, c]) {
        expect(data.tagsOf(id).map((t) => t.name), ['travel']);
      }
      expect(data.tagUse(travel), 3);

      await repo.renameTag(ideas, 'travel');
      data = await repo.load();
      expect(data.tags.single.id, travel);
    });

    test('deleting a tag removes the label only', () async {
      final t = await repo.ensureTag('x');
      final id = await repo.create(tagIds: [t]);
      await repo.deleteTag(t);
      final data = await repo.load();
      expect(data.byId(id), isNotNull);
      expect(data.tagsOf(id), isEmpty);
      expect(await deletions.isDeleted(tagEntity, t), isTrue);
    });

    test('pinned notes sort first, newest pinned first, then by edit', () async {
      final a = await repo.create(), b = await repo.create(), c = await repo.create();
      for (final id in [a, b, c]) {
        now += 1000;
        await repo.save(id, title: id, ops: _text('x'));
      }
      now += 1000;
      await repo.setPinned(a, true);
      now += 1000;
      await repo.setPinned(b, true);
      final sorted = [...(await repo.load()).live]..sort(NotesData.listOrder);
      expect(sorted.map((n) => n.id), [b, a, c]);
    });
  });

  group('autosave (F2-02 §3)', () {
    testWidgets('saves 1 s after typing stops; drafts at most once a second', (tester) async {
      var typed = '';
      final log = <String>[];
      final auto = NoteAutosave(
        save: (_, _) async => log.add('save'),
        draft: (_, _) async => log.add('draft'),
        read: () => ('T', _text(typed)),
      );
      for (var i = 0; i < 25; i++) {
        typed += 'a';
        auto.changed();
        await tester.pump(const Duration(milliseconds: 100));
      }
      // 2.5 s of typing: no save yet, drafts about once a second.
      expect(log.where((s) => s == 'save'), isEmpty);
      expect(log.where((s) => s == 'draft').length, inInclusiveRange(2, 3));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(log.where((s) => s == 'save').length, 1);
      expect(auto.dirty, isFalse);

      // Leaving the screen saves at once.
      typed += 'b';
      auto.changed();
      await auto.saveNow();
      expect(log.where((s) => s == 'save').length, 2);
      auto.dispose();
    });
  });
}
