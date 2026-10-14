import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/domain/validation.dart';
import 'package:ozone/tools/finance/data/savings_repo.dart';
import 'package:ozone/tools/finance/domain/savings_history.dart';

import '../../../helpers/harness.dart';

LocalDate d(String iso) => LocalDate.parseIso(iso).valueOrNull!;

void main() {
  late AppDatabase db;
  late SavingsRepo repo;
  late DeletionsRepo deletions;
  late SettingsRepo settings;

  setUp(() {
    db = memoryDb();
    deletions = DeletionsRepo(db);
    settings = SettingsRepo(db);
    repo = SavingsRepo(db, deletions, settings);
  });
  tearDown(() => db.close());

  Future<String> add(String name, int balance, String date, {String? platform, String? type}) async =>
      (await repo.addAccount(name: name, platform: platform, type: type, startBalance: balance, asOf: d(date))).valueOrNull!;

  test('adding an account also saves its starting balance', () async {
    final id = await add('Emergency Fund', 41400000, '2026-09-28');
    final data = await repo.load();
    expect(data.accounts.single.name, 'Emergency Fund');
    expect(data.updatesOf(id).single.balance, 41400000);
    expect(data.updatesOf(id).single.date, '2026-09-28');
  });

  test('a zero starting balance is allowed', () async {
    final id = await add('Kiddie Account', 0, '2026-01-15');
    expect((await repo.load()).updatesOf(id).single.balance, 0);
  });

  test('open account names are unique, ignoring case; archived names can be reused', () async {
    final id = await add('Payroll Savings', 100, '2026-09-30');
    final dup = await repo.addAccount(name: 'payroll savings', startBalance: 1, asOf: d('2026-10-01'));
    expect(dup, isA<Invalid<String>>());

    await repo.archive(id, d('2026-10-01'));
    final again = await repo.addAccount(name: 'Payroll Savings', startBalance: 1, asOf: d('2026-10-01'));
    expect(again.isOk, isTrue);

    // The archived one can't come back while an open one has its name.
    expect(await repo.restore(id), isA<Invalid<void>>());
  });

  test('editing to an open account\'s name is refused; no change keeps updated_at', () async {
    final a = await add('A', 100, '2026-10-01');
    await add('B', 100, '2026-10-01');
    expect(await repo.editAccount(a, name: 'b'), isA<Invalid<void>>());
    final before = (await repo.load()).account(a)!.updatedAt;
    await repo.editAccount(a, name: 'A');
    expect((await repo.load()).account(a)!.updatedAt, before);
  });

  test('one update per account per date: saving again replaces it', () async {
    final id = await add('A', 100, '2026-10-01');
    await repo.saveUpdate(id, d('2026-10-12'), 500);
    await repo.saveUpdate(id, d('2026-10-12'), 700, remarks: 'fixed');
    final ups = (await repo.load()).updatesOf(id);
    expect(ups.length, 2);
    expect(ups.last.balance, 700);
    expect(ups.last.remarks, 'fixed');
  });

  test('unchanged updates are stored as such and make the month Recorded', () async {
    final id = await add('A', 31240000, '2026-09-30');
    await repo.saveUpdates(d('2026-10-13'), [UpdateEntry(id, 31240000, isUnchanged: true)]);
    final data = await repo.load();
    expect(data.updatesOf(id).last.isUnchanged, isTrue);
    expect(monthBalance(data.history(id)!, d('2026-10-01'), d('2026-10-13')).status, MonthStatus.recorded);
  });

  test('saveUpdates writes all entries or none', () async {
    final a = await add('A', 100, '2026-10-01');
    await expectLater(
      repo.saveUpdates(d('2026-10-13'), [UpdateEntry(a, 200), const UpdateEntry('missing-account', 300)]),
      throwsA(anything),
    );
    expect((await repo.load()).updatesOf(a).length, 1);
  });

  test('deleting an account removes its updates and writes tombstones', () async {
    final id = await add('A', 100, '2026-09-01');
    await repo.saveUpdate(id, d('2026-10-01'), 200);
    final updateIds = [for (final u in (await repo.load()).updatesOf(id)) u.id];
    await repo.deleteAccount(id);
    final data = await repo.load();
    expect(data.accounts, isEmpty);
    expect(data.updates, isEmpty);
    expect(await deletions.isDeleted(accountEntity, id), isTrue);
    for (final u in updateIds) {
      expect(await deletions.isDeleted(balanceUpdateEntity, u), isTrue);
    }
  });

  test('a deleted update can be restored (Undo); the tombstone is written after', () async {
    final id = await add('A', 100, '2026-09-01');
    await repo.saveUpdate(id, d('2026-10-01'), 200);
    final u = (await repo.load()).updatesOf(id).last;
    final row = await repo.deleteUpdate(u.id);
    expect((await repo.load()).updatesOf(id).length, 1);
    await repo.restoreUpdate(row);
    expect((await repo.load()).updatesOf(id).last.balance, 200);
    expect(await deletions.isDeleted(balanceUpdateEntity, u.id), isFalse);
    await repo.deleteUpdate(u.id);
    await repo.recordUpdateDeleted(u.id);
    expect(await deletions.isDeleted(balanceUpdateEntity, u.id), isTrue);
  });

  test('suggestions: most used first, hidden values left out', () async {
    await add('A', 1, '2026-10-01', platform: 'Bank');
    await add('B', 1, '2026-10-01', platform: 'Digital bank');
    await add('C', 1, '2026-10-01', platform: 'Digital bank');
    expect(await repo.suggestions(SuggestionField.platform), ['Digital bank', 'Bank']);
    await settings.set(SettingKeys.listsHidden, {'vendor': <String>[], 'platform': ['bank'], 'type': <String>[]});
    expect(await repo.suggestions(SuggestionField.platform), ['Digital bank']);
  });

  test('watch emits when an update is saved', () async {
    final id = await add('A', 100, '2026-10-01');
    final seen = <int>[];
    final sub = repo.watch().listen((d) => seen.add(d.updatesOf(id).length));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.saveUpdate(id, d('2026-10-05'), 300);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(seen.last, 2);
  });
}
