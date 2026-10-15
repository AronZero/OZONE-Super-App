import 'database.dart';

/// Welcome is shown once, on a phone with no data (W2 · Welcome, F1-03 §3).
/// Phones that already have records (installs from before M8) skip it.
abstract final class FirstRun {
  static const _key = 'welcome_done';

  static Future<bool> needsWelcome(AppDatabase db) async {
    if (await (db.select(db.appMeta)..where((m) => m.key.equals(_key))).getSingleOrNull() != null) return false;
    final any = await db.customSelect(
      'SELECT EXISTS (SELECT 1 FROM savings_accounts) OR EXISTS (SELECT 1 FROM expenses) OR EXISTS (SELECT 1 FROM gold_items) '
      'OR EXISTS (SELECT 1 FROM books) OR EXISTS (SELECT 1 FROM notes) AS x',
    ).getSingle();
    if (any.read<bool>('x')) {
      await done(db);
      return false;
    }
    return true;
  }

  static Future<void> done(AppDatabase db) =>
      db.into(db.appMeta).insertOnConflictUpdate(AppMetaCompanion.insert(key: _key, value: DateTime.now().toUtc().toIso8601String()));
}
