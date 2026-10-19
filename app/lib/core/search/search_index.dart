import 'package:drift/drift.dart';

/// The global search index (docs/spec/F2-02 §1), kept in step by SQLite
/// triggers, so every insert, update and delete updates it inside the same
/// transaction, whichever repository made the write.
///
/// `search_index` (FTS5) holds one row per record:
/// `tool, entity, record_id, title, body, extra, label`.
/// `search_keys` gives each (entity, record_id) a fixed rowid, so a record's
/// row is found by rowid instead of scanning the index (decision M7-1).
///
/// Never indexed: locked notes and notes in the trash (F2-02 §1).
abstract final class SearchIndex {
  static const createIndex = 'CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5('
      'tool, entity, record_id UNINDEXED, title, body, extra, label UNINDEXED, '
      'tokenize = "unicode61 remove_diacritics 2")';

  static const createKeys = 'CREATE TABLE IF NOT EXISTS search_keys ('
      'rowid INTEGER PRIMARY KEY AUTOINCREMENT, entity TEXT NOT NULL, record_id TEXT NOT NULL, '
      'UNIQUE (entity, record_id))';

  /// `123456 1234.56` for an amount column (F2-02 §1: centavos and pesos).
  static String _amount(String col) => "printf('%d %d.%02d', $col, $col / 100, $col % 100)";

  /// One SELECT per entity giving (tool, entity, record_id, title, body, extra, label).
  /// `{ID}` is replaced by the record ID expression, or `NULL` for "every record".
  static final Map<String, _Source> _sources = {
    'savings_account': _Source(
      table: 'savings_accounts',
      select: "SELECT 'finance', 'savings_account', a.id, a.name, "
          "trim(coalesce(a.platform, '') || ' ' || coalesce(a.type, '') || ' ' || coalesce(a.remarks, '')), "
          "coalesce((SELECT ${_amount('u.balance')} FROM balance_updates u WHERE u.account_id = a.id ORDER BY u.date DESC LIMIT 1), ''), "
          "CASE WHEN a.archived_at IS NOT NULL THEN 'Archived' END "
          'FROM savings_accounts a WHERE ({ID} IS NULL OR a.id = {ID})',
    ),
    'gold_item': _Source(
      table: 'gold_items',
      select: "SELECT 'finance', 'gold_item', g.id, g.name, "
          "trim(coalesce(g.vendor, '') || ' ' || coalesce(g.remarks, '')), "
          "g.karat || 'k ' || printf('%d.%03d', g.weight_mg / 1000, g.weight_mg % 1000), "
          "CASE WHEN g.status = 'disposed' THEN 'Disposed' END "
          'FROM gold_items g WHERE ({ID} IS NULL OR g.id = {ID})',
    ),
    'expense': _Source(
      table: 'expenses',
      select: "SELECT 'finance', 'expense', e.id, e.item, "
          "trim(coalesce(e.vendor, '') || ' ' || coalesce(e.remarks, '')), "
          "${_amount('e.amount')}, "
          "CASE WHEN e.is_refunded THEN 'Refunded' END "
          'FROM expenses e WHERE ({ID} IS NULL OR e.id = {ID})',
    ),
    'book': _Source(
      table: 'books',
      select: "SELECT 'library', 'book', b.id, b.title, "
          "trim(coalesce(b.author, '') || ' ' || coalesce(b.remarks, '')), "
          "coalesce(substr(b.acquired_date, 1, 4), ''), "
          "CASE b.status WHEN 'not_started' THEN 'Not started' WHEN 'reading' THEN 'Reading' "
          "WHEN 'finished' THEN 'Finished' WHEN 'abandoned' THEN 'Abandoned' END "
          'FROM books b WHERE ({ID} IS NULL OR b.id = {ID})',
    ),
    'note': _Source(
      table: 'notes',
      select: "SELECT 'notes', 'note', n.id, coalesce(n.title, ''), coalesce(n.plain_text, ''), "
          "coalesce((SELECT group_concat(t.name, ' ') FROM note_tags nt JOIN tags t ON t.id = nt.tag_id WHERE nt.note_id = n.id), ''), "
          "CASE WHEN n.is_pinned THEN 'Pinned' END "
          'FROM notes n WHERE n.is_locked = 0 AND n.trashed_at IS NULL AND ({ID} IS NULL OR n.id = {ID})',
    ),
    // Recipe (F4-01 §7): ingredients, steps, source and notes are searchable; category and key names are extra words.
    'recipe': _Source(
      table: 'recipes',
      select: "SELECT 'recipe', 'recipe', r.id, r.title, "
          "trim(coalesce((SELECT group_concat(i.name, ' ') FROM recipe_ingredients i WHERE i.recipe_id = r.id), '') || ' ' || "
          "coalesce((SELECT group_concat(s.text, ' ') FROM recipe_steps s WHERE s.recipe_id = r.id), '') || ' ' || "
          "coalesce(r.source, '') || ' ' || coalesce(r.notes, '')), "
          "trim(coalesce(r.category, '') || ' ' || coalesce((SELECT group_concat(i.key_name, ' ') FROM recipe_ingredients i WHERE i.recipe_id = r.id), '')), "
          "CASE WHEN r.is_favourite THEN 'Favourite' END "
          'FROM recipes r WHERE ({ID} IS NULL OR r.id = {ID})',
    ),
  };

  /// Statements that drop a record's row and write it again (or not, if it
  /// no longer qualifies). [id] is an SQL expression such as `NEW.id`.
  static String _reindex(String entity, String id) {
    final s = _sources[entity]!;
    return "DELETE FROM search_index WHERE rowid = (SELECT rowid FROM search_keys WHERE entity = '$entity' AND record_id = $id); "
        "INSERT OR IGNORE INTO search_keys (entity, record_id) SELECT '$entity', $id WHERE EXISTS (SELECT 1 FROM ${s.table} WHERE id = $id); "
        'INSERT INTO search_index (rowid, tool, entity, record_id, title, body, extra, label) '
        "SELECT (SELECT rowid FROM search_keys WHERE entity = '$entity' AND record_id = $id), * FROM (${s.select.replaceAll('{ID}', id)}); ";
  }

  static String _forget(String entity, String id) =>
      "DELETE FROM search_index WHERE rowid = (SELECT rowid FROM search_keys WHERE entity = '$entity' AND record_id = $id); "
      "DELETE FROM search_keys WHERE entity = '$entity' AND record_id = $id; ";

  /// Every trigger, as `CREATE TRIGGER` statements.
  static List<String> get triggers {
    final out = <String>[];
    void on(String name, String event, String table, String body) =>
        out.add('CREATE TRIGGER IF NOT EXISTS si_$name AFTER $event ON $table BEGIN $body END');
    for (final MapEntry(key: entity, value: s) in _sources.entries) {
      on('${entity}_ai', 'INSERT', s.table, _reindex(entity, 'NEW.id'));
      on('${entity}_au', 'UPDATE', s.table, _reindex(entity, 'NEW.id'));
      on('${entity}_ad', 'DELETE', s.table, _forget(entity, 'OLD.id'));
    }
    // A balance update changes its account's latest balance.
    on('balance_ai', 'INSERT', 'balance_updates', _reindex('savings_account', 'NEW.account_id'));
    on('balance_au', 'UPDATE', 'balance_updates', _reindex('savings_account', 'NEW.account_id'));
    on('balance_ad', 'DELETE', 'balance_updates', _reindex('savings_account', 'OLD.account_id'));
    // A note's tags are searchable words.
    on('note_tag_ai', 'INSERT', 'note_tags', _reindex('note', 'NEW.note_id'));
    on('note_tag_ad', 'DELETE', 'note_tags', _reindex('note', 'OLD.note_id'));
    // A recipe's ingredients and steps are written after the recipe row (they need it), so they
    // re-index it as they arrive. Deletes need no trigger: an edit always updates the recipe row too.
    on('recipe_ingredient_ai', 'INSERT', 'recipe_ingredients', _reindex('recipe', 'NEW.recipe_id'));
    on('recipe_step_ai', 'INSERT', 'recipe_steps', _reindex('recipe', 'NEW.recipe_id'));
    // Renaming a tag renames it in every note that has it.
    out.add('CREATE TRIGGER IF NOT EXISTS si_tag_au AFTER UPDATE OF name ON tags BEGIN '
        'UPDATE notes SET updated_at = updated_at WHERE id IN (SELECT note_id FROM note_tags WHERE tag_id = NEW.id); END');
    return out;
  }

  /// Creates the index, the key table and the triggers.
  static Future<void> install(DatabaseConnectionUser db) async {
    await db.customStatement(createIndex);
    await db.customStatement(createKeys);
    for (final t in triggers) {
      await db.customStatement(t);
    }
  }

  /// Builds the index from scratch (F2-02 §1: after an import or a migration).
  static Future<void> rebuild(DatabaseConnectionUser db) async {
    await db.customStatement('DELETE FROM search_index');
    await db.customStatement('DELETE FROM search_keys');
    for (final MapEntry(key: entity, value: s) in _sources.entries) {
      await db.customStatement("INSERT INTO search_keys (entity, record_id) SELECT '$entity', id FROM ${s.table}");
      await db.customStatement('INSERT INTO search_index (rowid, tool, entity, record_id, title, body, extra, label) '
          "SELECT k.rowid, x.* FROM (${s.select.replaceAll('{ID}', 'NULL')}) x "
          "JOIN search_keys k ON k.entity = '$entity' AND k.record_id = x.id");
    }
  }
}

class _Source {
  const _Source({required this.table, required this.select});
  final String table;
  final String select;
}
