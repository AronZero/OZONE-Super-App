import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/data/database.dart';
import '../../../core/data/deletions_repo.dart';
import '../../../core/data/watch.dart';
import '../../../core/domain/ids.dart';
import '../domain/notes.dart';

const String noteEntity = 'note';
const String folderEntity = 'folder';
const String tagEntity = 'tag';

/// Everything the Notes screens show, loaded together.
class NotesData {
  NotesData({required this.notes, required this.folders, required this.tags, required List<NoteTagRow> links}) {
    for (final l in links) {
      (_tagsByNote[l.noteId] ??= []).add(l.tagId);
    }
    final live = {for (final n in notes) if (n.trashedAt == null) n.id};
    for (final l in links) {
      if (live.contains(l.noteId)) _tagUse[l.tagId] = (_tagUse[l.tagId] ?? 0) + 1;
    }
  }

  /// Every note, trashed ones included.
  final List<NoteRow> notes;

  /// In their saved order (new folders go last).
  final List<FolderRow> folders;

  /// Sorted by name.
  final List<TagRow> tags;

  final Map<String, List<String>> _tagsByNote = {};
  final Map<String, int> _tagUse = {};

  late final List<NoteRow> live = [for (final n in notes) if (n.trashedAt == null) n];

  /// Trashed notes, most recently trashed first.
  late final List<NoteRow> trashed = [for (final n in notes) if (n.trashedAt != null) n]
    ..sort((a, b) => b.trashedAt!.compareTo(a.trashedAt!));

  /// Pinned first (newest pinned first), then by last edit (F2-02 §4).
  static int listOrder(NoteRow a, NoteRow b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    if (a.isPinned) {
      final p = (b.pinnedAt ?? 0).compareTo(a.pinnedAt ?? 0);
      if (p != 0) return p;
    }
    return b.editedAt.compareTo(a.editedAt);
  }

  NoteRow? byId(String id) {
    for (final n in notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  FolderRow? folder(String? id) {
    if (id == null) return null;
    for (final f in folders) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// A note's tags, sorted by name.
  List<TagRow> tagsOf(String noteId) {
    final ids = _tagsByNote[noteId] ?? const [];
    return [for (final t in tags) if (ids.contains(t.id)) t];
  }

  /// Notes (not in the trash) using a tag.
  int tagUse(String tagId) => _tagUse[tagId] ?? 0;

  int folderUse(String? folderId) => live.where((n) => n.folderId == folderId).length;
}

/// A crash-recovery draft (F2-02 §3): the title and Delta as typed.
class NoteDraft {
  const NoteDraft({required this.title, required this.ops, required this.savedAt});
  final String title;
  final List<Object?> ops;
  final int savedAt;

  String encode() => jsonEncode({'title': title, 'ops': ops});

  static NoteDraft? decode(NoteDraftRow row) {
    try {
      final m = jsonDecode(row.content) as Map<String, Object?>;
      return NoteDraft(title: (m['title'] as String?) ?? '', ops: (m['ops']! as List).cast<Object?>(), savedAt: row.savedAt);
    } on Object {
      return null; // a damaged draft is ignored, never shown
    }
  }
}

/// What a trashed note needs to come back exactly as it was.
class TrashedNote {
  const TrashedNote(this.row, this.tagIds);
  final NoteRow row;
  final List<String> tagIds;
}

/// The only code that reads and writes notes, folders and tags (F3-01 §1).
/// The search index is kept in step from M7 (F2-02 §1).
class NotesRepo {
  NotesRepo(this._db, this._deletions, {int Function()? clock}) : _clock = clock ?? _systemNow;

  final AppDatabase _db;
  final DeletionsRepo _deletions;
  final int Function() _clock;

  static int _systemNow() => DateTime.now().toUtc().millisecondsSinceEpoch;

  Future<NotesData> load() async => NotesData(
        notes: await _db.select(_db.notes).get(),
        folders: await (_db.select(_db.folders)..orderBy([(f) => OrderingTerm(expression: f.sortOrder), (f) => OrderingTerm(expression: f.createdAt)])).get(),
        tags: await (_db.select(_db.tags)..orderBy([(t) => OrderingTerm(expression: t.name)])).get(),
        links: await _db.select(_db.noteTags).get(),
      );

  Stream<NotesData> watch() => watchTables(_db, [_db.notes, _db.folders, _db.tags, _db.noteTags], load);

  Future<NoteRow?> note(String id) => (_db.select(_db.notes)..where((n) => n.id.equals(id))).getSingleOrNull();

  // ── Notes ──────────────────────────────────────────────────────────────

  /// A new empty note. Its `edited_at` equals `created_at` until the first
  /// save, which is how a never-written note is recognised.
  Future<String> create({String? folderId, List<String> tagIds = const []}) async {
    final id = newId();
    final now = _clock();
    await _db.transaction(() async {
      await _db.into(_db.notes).insert(NotesCompanion.insert(
            id: id,
            folderId: Value(folderId),
            title: const Value(null),
            content: const Value('[{"insert":"\\n"}]'),
            plainText: const Value(''),
            editedAt: now,
            createdAt: now,
            updatedAt: now,
          ));
      for (final t in tagIds) {
        await _db.into(_db.noteTags).insert(NoteTagsCompanion.insert(noteId: id, tagId: t), mode: InsertMode.insertOrIgnore);
      }
    });
    return id;
  }

  /// Autosave (F2-02 §3): content, plain text and `edited_at`, and the draft
  /// goes, all in one transaction. Nothing is written when nothing changed.
  Future<bool> save(String id, {required String title, required List<Object?> ops}) async {
    final clean = sanitizeDelta(ops);
    final content = jsonEncode(clean);
    final t = normaliseTitle(title);
    final plain = plainTextFromDelta(clean);
    return _db.transaction(() async {
      final cur = await note(id);
      await (_db.delete(_db.noteDrafts)..where((d) => d.noteId.equals(id))).go();
      if (cur == null || cur.isLocked) return false;
      if (cur.title == t && cur.content == content) return false;
      final now = _clock();
      await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(NotesCompanion(
        title: Value(t),
        content: Value(content),
        plainText: Value(plain),
        // Never equal to created_at once written (see [create]).
        editedAt: Value(now == cur.createdAt ? now + 1 : now),
        updatedAt: Value(now),
      ));
      return true;
    });
  }

  /// Between saves: the typed state, at most once a second (the caller throttles).
  Future<void> writeDraft(String id, {required String title, required List<Object?> ops}) => _db.into(_db.noteDrafts).insertOnConflictUpdate(
        NoteDraftsCompanion.insert(noteId: id, content: NoteDraft(title: title, ops: ops, savedAt: 0).encode(), savedAt: _clock()),
      );

  /// A draft newer than the note's last save, if any (shown as "Recovered unsaved changes").
  Future<NoteDraft?> recoverableDraft(String id) async {
    final n = await note(id);
    final row = await (_db.select(_db.noteDrafts)..where((d) => d.noteId.equals(id))).getSingleOrNull();
    if (n == null || row == null || row.savedAt <= n.editedAt) return null;
    return NoteDraft.decode(row);
  }

  Future<void> discardDraft(String id) => (_db.delete(_db.noteDrafts)..where((d) => d.noteId.equals(id))).go();

  /// A new note left with no title and no text is deleted silently: never
  /// trashed, no tombstone (F2-02 §3). Returns whether it was deleted.
  Future<bool> deleteIfBlankNew(String id) => _db.transaction(() async {
        final n = await note(id);
        if (n == null || n.isLocked || n.editedAt != n.createdAt) return false;
        final draft = await (_db.select(_db.noteDrafts)..where((d) => d.noteId.equals(id))).getSingleOrNull();
        if (draft != null) {
          final d = NoteDraft.decode(draft);
          if (d != null && !isBlankNote(d.title, plainTextFromDelta(d.ops))) return false;
        }
        if (!isBlankNote(n.title, n.plainText)) return false;
        await _hardDelete(id);
        return true;
      });

  // ── Locked notes (the crypto is in VaultService; these are the writes) ──

  /// Lock a note (F2-01 §4): the cipher replaces title, text and tags, and the
  /// draft goes, in one transaction. M7 removes its search row here too.
  Future<void> lockNote(String id, String cipher) => _db.transaction(() async {
        await (_db.delete(_db.noteTags)..where((l) => l.noteId.equals(id))).go();
        await (_db.delete(_db.noteDrafts)..where((d) => d.noteId.equals(id))).go();
        await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(NotesCompanion(
          isLocked: const Value(true),
          cipher: Value(cipher),
          title: const Value(null),
          content: const Value(null),
          plainText: const Value(null),
          updatedAt: Value(_clock()),
        ));
      });

  /// "Remove lock": the plain columns and tags come back from the decrypted note.
  Future<void> unlockNote(String id, {required String? title, required String content, required List<String> tagNames}) => _db.transaction(() async {
        final clean = sanitizeDelta(jsonDecode(content) as List<Object?>);
        await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(NotesCompanion(
          isLocked: const Value(false),
          cipher: const Value(null),
          title: Value(title),
          content: Value(jsonEncode(clean)),
          plainText: Value(plainTextFromDelta(clean)),
          updatedAt: Value(_clock()),
        ));
        for (final name in tagNames) {
          final parsed = parseTag(name).valueOrNull;
          if (parsed == null) continue;
          await _db.into(_db.noteTags).insert(NoteTagsCompanion.insert(noteId: id, tagId: await ensureTag(parsed)), mode: InsertMode.insertOrIgnore);
        }
        await (_db.delete(_db.noteDrafts)..where((d) => d.noteId.equals(id))).go();
      });

  /// Autosave of a locked note: the new cipher and `edited_at`; the draft goes.
  Future<void> saveLocked(String id, String cipher) => _db.transaction(() async {
        final cur = await note(id);
        await (_db.delete(_db.noteDrafts)..where((d) => d.noteId.equals(id))).go();
        if (cur == null || !cur.isLocked) return;
        final now = _clock();
        await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(NotesCompanion(
          cipher: Value(cipher),
          editedAt: Value(now == cur.createdAt ? now + 1 : now),
          updatedAt: Value(now),
        ));
      });

  /// An encrypted draft of a locked note (F2-02 §3), stored as given.
  Future<void> writeSealedDraft(String id, String sealed) =>
      _db.into(_db.noteDrafts).insertOnConflictUpdate(NoteDraftsCompanion.insert(noteId: id, content: sealed, savedAt: _clock()));

  /// A locked note's draft newer than its last save, still sealed.
  Future<NoteDraftRow?> sealedDraft(String id) async {
    final n = await note(id);
    final row = await (_db.select(_db.noteDrafts)..where((d) => d.noteId.equals(id))).getSingleOrNull();
    if (n == null || row == null || row.savedAt <= n.editedAt) return null;
    return row;
  }

  Future<void> setPinned(String id, bool pinned) => (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(NotesCompanion(
        isPinned: Value(pinned),
        pinnedAt: Value(pinned ? _clock() : null),
        updatedAt: Value(_clock()),
      ));

  Future<void> moveToFolder(String id, String? folderId) => (_db.update(_db.notes)..where((n) => n.id.equals(id)))
      .write(NotesCompanion(folderId: Value(folderId), updatedAt: Value(_clock())));

  /// Replaces a note's tags.
  Future<void> setTags(String noteId, Iterable<String> tagIds) => _db.transaction(() async {
        await (_db.delete(_db.noteTags)..where((l) => l.noteId.equals(noteId))).go();
        for (final t in tagIds) {
          await _db.into(_db.noteTags).insert(NoteTagsCompanion.insert(noteId: noteId, tagId: t), mode: InsertMode.insertOrIgnore);
        }
        await (_db.update(_db.notes)..where((n) => n.id.equals(noteId))).write(NotesCompanion(updatedAt: Value(_clock())));
      });

  /// Move to trash (F2-02 §5). The note keeps its tags and folder for Restore.
  /// [at] puts it back with its first trash date (Undo of Restore).
  Future<void> trash(String id, {int? at}) => (_db.update(_db.notes)..where((n) => n.id.equals(id)))
      .write(NotesCompanion(trashedAt: Value(at ?? _clock()), updatedAt: Value(_clock())));

  /// Restore, or Undo of Move to trash.
  Future<void> restore(String id) => (_db.update(_db.notes)..where((n) => n.id.equals(id)))
      .write(NotesCompanion(trashedAt: const Value(null), updatedAt: Value(_clock())));

  /// Delete forever: the note, its tags and draft go, and a tombstone is written.
  Future<void> deleteForever(String id) => _db.transaction(() async {
        await _hardDelete(id);
        await _deletions.record(noteEntity, id);
      });

  Future<int> emptyTrash() => _db.transaction(() async {
        final ids = await (_db.selectOnly(_db.notes)
              ..addColumns([_db.notes.id])
              ..where(_db.notes.trashedAt.isNotNull()))
            .map((r) => r.read(_db.notes.id)!)
            .get();
        for (final id in ids) {
          await _hardDelete(id);
          await _deletions.record(noteEntity, id);
        }
        return ids.length;
      });

  /// On app start and on return to the foreground (F2-02 §5): notes trashed
  /// more than 30 days ago are deleted, and so are blank new notes left behind
  /// by a forced stop.
  Future<int> purge() => _db.transaction(() async {
        final old = await (_db.select(_db.notes)..where((n) => n.trashedAt.isSmallerThanValue(purgeCutoff(_clock())))).get();
        for (final n in old) {
          await _hardDelete(n.id);
          await _deletions.record(noteEntity, n.id);
        }
        final fresh = await (_db.select(_db.notes)
              ..where((n) => n.editedAt.equalsExp(n.createdAt) & n.isLocked.equals(false) & n.trashedAt.isNull()))
            .get();
        for (final n in fresh) {
          final hasDraft = await (_db.select(_db.noteDrafts)..where((d) => d.noteId.equals(n.id))).getSingleOrNull() != null;
          if (!hasDraft && isBlankNote(n.title, n.plainText)) await _hardDelete(n.id);
        }
        return old.length;
      });

  Future<void> _hardDelete(String id) async {
    await (_db.delete(_db.noteTags)..where((l) => l.noteId.equals(id))).go();
    await (_db.delete(_db.noteDrafts)..where((d) => d.noteId.equals(id))).go();
    await (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();
  }

  // ── Folders ────────────────────────────────────────────────────────────

  Future<String> addFolder(String name) async {
    final id = newId();
    final now = _clock();
    final last = await (_db.selectOnly(_db.folders)..addColumns([_db.folders.sortOrder.max()])).map((r) => r.read(_db.folders.sortOrder.max())).getSingle();
    await _db.into(_db.folders).insert(FoldersCompanion.insert(id: id, name: name, sortOrder: Value((last ?? -1) + 1), createdAt: now, updatedAt: now));
    return id;
  }

  Future<void> renameFolder(String id, String name) => (_db.update(_db.folders)..where((f) => f.id.equals(id)))
      .write(FoldersCompanion(name: Value(name), updatedAt: Value(_clock())));

  /// Its notes move to Unfiled in the same transaction; no note is deleted (F2-02 §4).
  Future<void> deleteFolder(String id) => _db.transaction(() async {
        await (_db.update(_db.notes)..where((n) => n.folderId.equals(id)))
            .write(NotesCompanion(folderId: const Value(null), updatedAt: Value(_clock())));
        await (_db.delete(_db.folders)..where((f) => f.id.equals(id))).go();
        await _deletions.record(folderEntity, id);
      });

  // ── Tags ───────────────────────────────────────────────────────────────

  /// The tag's ID, creating it when it's new. [name] is already parsed ([parseTag]).
  Future<String> ensureTag(String name) async {
    final found = await (_db.select(_db.tags)..where((t) => t.name.equals(name))).getSingleOrNull();
    if (found != null) return found.id;
    final id = newId();
    final now = _clock();
    await _db.into(_db.tags).insert(TagsCompanion.insert(id: id, name: name, createdAt: now, updatedAt: now));
    return id;
  }

  Future<TagRow?> tagNamed(String name) => (_db.select(_db.tags)..where((t) => t.name.equals(name))).getSingleOrNull();

  /// Rename; when another tag already has [name], the two merge (the caller confirms first).
  Future<void> renameTag(String id, String name) async {
    final other = await tagNamed(name);
    if (other != null && other.id != id) return mergeTag(id, other.id);
    await (_db.update(_db.tags)..where((t) => t.id.equals(id))).write(TagsCompanion(name: Value(name), updatedAt: Value(_clock())));
  }

  /// Every note tagged [fromId] gets [intoId]; then [fromId] is deleted.
  Future<void> mergeTag(String fromId, String intoId) => _db.transaction(() async {
        if (fromId == intoId) return;
        await _db.customStatement(
          'INSERT OR IGNORE INTO note_tags (note_id, tag_id) SELECT note_id, ? FROM note_tags WHERE tag_id = ?',
          [intoId, fromId],
        );
        await _removeTag(fromId);
      });

  /// Removes the label only; the notes stay (F2-02 §4).
  Future<void> deleteTag(String id) => _db.transaction(() => _removeTag(id));

  Future<void> _removeTag(String id) async {
    await (_db.delete(_db.noteTags)..where((l) => l.tagId.equals(id))).go();
    await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
    await _deletions.record(tagEntity, id);
  }
}
