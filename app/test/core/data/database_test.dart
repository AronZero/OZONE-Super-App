import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/domain/ids.dart';

import '../../helpers/harness.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  int now() => DateTime.now().millisecondsSinceEpoch;

  test('schema v3 creates every F1-01 and F4-01 table, the search index, its keys and app meta', () async {
    final rows = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    for (final t in [
      'app_meta', 'settings', 'deletions', 'exports_log', 'savings_accounts', 'balance_updates', 'gold_items',
      'karat_prices', 'expenses', 'books', 'folders', 'tags', 'notes', 'note_tags', 'note_drafts', 'vault', 'search_index', 'search_keys',
      'recipes', 'recipe_ingredients', 'recipe_steps', 'kitchen',
    ]) {
      expect(names, contains(t));
    }
    final meta = {for (final r in await db.select(db.appMeta).get()) r.key: r.value};
    expect(meta['schema_version'], '3');
    expect(isId(meta['install_id']!), isTrue);
  });

  test('one balance update per account per date', () async {
    final acc = newId();
    await db.into(db.savingsAccounts).insert(
        SavingsAccountsCompanion.insert(id: acc, name: 'Emergency Fund', createdAt: now(), updatedAt: now()));
    BalanceUpdatesCompanion upd() => BalanceUpdatesCompanion.insert(
        id: newId(), accountId: acc, date: '2026-10-12', balance: 42015000, createdAt: now(), updatedAt: now());
    await db.into(db.balanceUpdates).insert(upd());
    await expectLater(db.into(db.balanceUpdates).insert(upd()), throwsA(anything));
  });

  test('folder names are unique ignoring case', () async {
    await db.into(db.folders).insert(FoldersCompanion.insert(id: newId(), name: 'Travel', createdAt: now(), updatedAt: now()));
    await expectLater(
      db.into(db.folders).insert(FoldersCompanion.insert(id: newId(), name: 'travel', createdAt: now(), updatedAt: now())),
      throwsA(anything),
    );
  });

  test('foreign keys are enforced', () async {
    await expectLater(
      db.into(db.balanceUpdates).insert(BalanceUpdatesCompanion.insert(
          id: newId(), accountId: 'missing', date: '2026-10-12', balance: 1, createdAt: now(), updatedAt: now())),
      throwsA(anything),
    );
  });

  group('settings', () {
    test('defaults from F1-01 §4', () async {
      final s = SettingsRepo(db);
      expect(await s.get(SettingKeys.theme), ThemeChoice.system);
      expect(await s.get(SettingKeys.barTools), ['finance', 'library', 'notes']);
      final lock = await s.get(SettingKeys.appLock);
      expect((lock.on, lock.relockAfterS), (false, 60));
      final dash = await s.get(SettingKeys.dashboardWidgets);
      expect(dash.where((w) => w.on).length, 7);
    });

    test('round trip and stream', () async {
      final s = SettingsRepo(db);
      final seen = <ThemeChoice>[];
      final sub = s.watch(SettingKeys.theme).listen(seen.add);
      await s.set(SettingKeys.theme, ThemeChoice.dark);
      await pumpEventQueue();
      expect(await s.get(SettingKeys.theme), ThemeChoice.dark);
      expect(seen.last, ThemeChoice.dark);
      await sub.cancel();
    });

    test('a damaged value falls back to the default', () async {
      await db.into(db.settings).insert(SettingsCompanion.insert(key: 'theme', value: '{oops', updatedAt: 0));
      expect(await SettingsRepo(db).get(SettingKeys.theme), ThemeChoice.system);
    });

    test('dashboard: unknown widgets dropped, missing ones appended hidden', () async {
      await db.into(db.settings).insert(SettingsCompanion.insert(
          key: 'dashboard.widgets', value: '[{"id":"pinned_notes","on":true},{"id":"retired","on":true}]', updatedAt: 0));
      final d = await SettingsRepo(db).get(SettingKeys.dashboardWidgets);
      expect(d.first.id, 'pinned_notes');
      expect(d.length, 10);
      expect(d.skip(1).every((w) => !w.on), isTrue);
    });
  });

  test('tombstones', () async {
    final r = DeletionsRepo(db);
    await r.record('expense', 'abc');
    expect(await r.isDeleted('expense', 'abc'), isTrue);
    expect(await r.isDeleted('expense', 'xyz'), isFalse);
  });
}
