import 'package:drift/drift.dart';

import '../data/database.dart';
import '../data/settings_repo.dart';
import 'query_parser.dart';

/// One search result. [title] and [snippet] carry FTS5 match markers (see
/// [highlightRuns]).
class SearchHit {
  const SearchHit({required this.entity, required this.recordId, required this.title, required this.snippet, this.label});
  final String entity;
  final String recordId;
  final String title;
  final String snippet;

  /// Archived, Disposed, Refunded, a book status or Pinned.
  final String? label;
}

/// Results for one entity: how many matched, and the first ones.
class SearchGroup {
  const SearchGroup(this.entity, this.count, this.hits);
  final String entity;
  final int count;
  final List<SearchHit> hits;
}

/// Reads the search index (F2-02 §1). Ranking: title matches first, then
/// bm25 with the title weighted highest.
class SearchRepo {
  SearchRepo(this._db, this._settings);
  final AppDatabase _db;
  final SettingsRepo _settings;

  static const _rank = 'bm25(search_index, 0.0, 0.0, 0.0, 10.0, 2.0, 1.0, 0.0)';
  static const _titleHl = 'highlight(search_index, 3, char(1), char(2))';
  static const _bodySnip = "snippet(search_index, 4, char(1), char(2), '…', 10)";

  /// Counts per entity, and the top [perGroup] hits of each (or of [only]).
  Future<List<SearchGroup>> search(String typed, {List<String> entities = const [], int perGroup = 3}) async {
    final match = buildMatch(typed);
    if (match == null) return const [];
    final counts = await _db.customSelect(
      'SELECT entity, count(*) AS n FROM search_index WHERE search_index MATCH ? GROUP BY entity',
      variables: [Variable.withString(match)],
    ).get();
    final byEntity = {for (final r in counts) r.read<String>('entity'): r.read<int>('n')};
    final groups = <SearchGroup>[];
    for (final e in entities.isEmpty ? byEntity.keys : entities) {
      final n = byEntity[e] ?? 0;
      if (n == 0) continue;
      groups.add(SearchGroup(e, n, await hits(match, e, perGroup)));
    }
    return groups;
  }

  /// Every hit of one entity ("See all"), best first.
  Future<List<SearchHit>> all(String typed, String entity, {int limit = 500}) async {
    final match = buildMatch(typed);
    return match == null ? const [] : hits(match, entity, limit);
  }

  Future<List<SearchHit>> hits(String match, String entity, int limit) async {
    final rows = await _db.customSelect(
      'SELECT record_id, label, $_titleHl AS t, $_bodySnip AS s FROM search_index '
      'WHERE search_index MATCH ? AND entity = ? '
      'ORDER BY (instr(t, char(1)) = 0), $_rank LIMIT ?',
      variables: [Variable.withString(match), Variable.withString(entity), Variable.withInt(limit)],
    ).get();
    return [
      for (final r in rows)
        SearchHit(
          entity: entity,
          recordId: r.read<String>('record_id'),
          title: r.read<String>('t'),
          snippet: r.read<String>('s'),
          label: r.readNullable<String>('label'),
        ),
    ];
  }

  // ── Recent searches (settings `search.recent`, phone only) ──────────────

  Stream<List<String>> watchRecent() => _settings.watch(SettingKeys.searchRecent);

  /// Keeps the last 5 submitted queries, newest first, without repeats.
  Future<void> remember(String typed) async {
    final q = typed.trim();
    if (buildMatch(q) == null) return;
    final cur = await _settings.get(SettingKeys.searchRecent);
    await _settings.set(SettingKeys.searchRecent, [q, ...cur.where((x) => x.toLowerCase() != q.toLowerCase())].take(5).toList());
  }

  Future<void> clearRecent() => _settings.set(SettingKeys.searchRecent, const <String>[]);
}
