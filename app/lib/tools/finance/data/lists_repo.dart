import 'package:drift/drift.dart';

import '../../../core/data/database.dart';
import '../../../core/data/settings_repo.dart';
import '../../../core/data/watch.dart';

/// The suggestion lists of Settings › Lists (F1-01 §3). Values come from the
/// records themselves; there is no separate table.
enum ListField {
  vendor('vendor', 'Vendors'),
  platform('platform', 'Savings platforms'),
  type('type', 'Account types');

  const ListField(this.key, this.title);

  /// Key inside the `lists.hidden` setting.
  final String key;
  final String title;
}

/// One value with how many records use it.
class ListValue {
  const ListValue(this.value, this.uses, {this.hidden = false});
  final String value;
  final int uses;
  final bool hidden;
}

class ListsRepo {
  ListsRepo(this._db, this._settings);

  final AppDatabase _db;
  final SettingsRepo _settings;

  static int _now() => DateTime.now().toUtc().millisecondsSinceEpoch;

  /// (table, column) pairs that hold each list's values.
  static const Map<ListField, List<(String, String)>> _sources = {
    ListField.vendor: [('expenses', 'vendor'), ('gold_items', 'vendor')],
    ListField.platform: [('savings_accounts', 'platform')],
    ListField.type: [('savings_accounts', 'type')],
  };

  Set<ResultSetImplementation<dynamic, dynamic>> get _tables => {_db.expenses, _db.goldItems, _db.savingsAccounts};

  /// Values in use, most used first, then most recently changed.
  Future<List<ListValue>> values(ListField f) async {
    final union = _sources[f]!
        .map((s) => "SELECT ${s.$2} AS v, updated_at AS t FROM ${s.$1} WHERE ${s.$2} IS NOT NULL AND ${s.$2} <> ''")
        .join(' UNION ALL ');
    final rows = await _db.customSelect(
      'SELECT v, COUNT(*) AS n, MAX(t) AS t FROM ($union) GROUP BY v ORDER BY n DESC, t DESC',
      readsFrom: _tables,
    ).get();
    final hidden = await _hidden(f);
    return [
      for (final r in rows)
        ListValue(r.read<String>('v'), r.read<int>('n'), hidden: hidden.contains(r.read<String>('v').toLowerCase())),
    ];
  }

  /// Suggestions for a form: values in use minus hidden ones.
  Future<List<String>> suggestions(ListField f) async => [for (final v in await values(f)) if (!v.hidden) v.value];

  Stream<List<ListValue>> watch(ListField f) =>
      watchTables(_db, [_db.expenses, _db.goldItems, _db.savingsAccounts, _db.settings], () => values(f));

  Future<Set<String>> _hidden(ListField f) async =>
      {for (final v in (await _settings.get(SettingKeys.listsHidden))[f.key] ?? const <String>[]) v.toLowerCase()};

  /// Renames a value in every record that uses it, in one transaction.
  /// Renaming onto an existing value merges the two.
  Future<int> rename(ListField f, String from, String to) => _db.transaction(() async {
        var changed = 0;
        for (final (table, col) in _sources[f]!) {
          changed += await _db.customUpdate(
            'UPDATE $table SET $col = ?, updated_at = ? WHERE $col = ?',
            variables: [Variable.withString(to), Variable.withInt(_now()), Variable.withString(from)],
            updates: _tables,
            updateKind: UpdateKind.update,
          );
        }
        return changed;
      });

  /// Hides a value from suggestions (records keep it) or shows it again.
  Future<void> setHidden(ListField f, String value, bool hidden) async {
    final all = {...await _settings.get(SettingKeys.listsHidden)};
    final cur = [...?all[f.key]]..removeWhere((v) => v.toLowerCase() == value.toLowerCase());
    if (hidden) cur.add(value);
    all[f.key] = cur;
    for (final k in ListField.values) {
      all.putIfAbsent(k.key, () => []);
    }
    await _settings.set(SettingKeys.listsHidden, all);
  }
}
