import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/tools/finance/data/expenses_repo.dart';
import 'package:ozone/tools/finance/data/gold_repo.dart';
import 'package:ozone/tools/finance/data/lists_repo.dart';
import 'package:ozone/tools/finance/data/savings_repo.dart';

import '../../../helpers/harness.dart';

LocalDate d(String iso) => LocalDate.parseIso(iso).valueOrNull!;
final oct1 = LocalDate(2026, 10, 1);

void main() {
  late AppDatabase db;
  late DeletionsRepo deletions;
  late GoldRepo gold;
  late ExpensesRepo expenses;
  late ListsRepo lists;
  late SettingsRepo settings;

  setUp(() {
    db = memoryDb();
    deletions = DeletionsRepo(db);
    settings = SettingsRepo(db);
    gold = GoldRepo(db, deletions);
    expenses = ExpensesRepo(db, deletions);
    lists = ListsRepo(db, settings);
  });
  tearDown(() => db.close());

  GoldItemInput item(String name, {int karat = 18, LocalDate? disposed, String? vendor}) => GoldItemInput(
        name: name,
        weightMg: 25000,
        karat: karat,
        vendor: vendor,
        purchaseDate: d('2026-01-10'),
        cost: 11822000,
        disposedDate: disposed,
      );

  group('gold', () {
    test('prices: one per karat per date; the latest date is current', () async {
      await gold.savePrices(d('2026-09-01'), {18: 500000});
      await gold.savePrices(d('2026-10-02'), {18: 550000, 24: 735000});
      await gold.savePrices(d('2026-10-02'), {18: 551000});
      final data = await gold.load();
      expect(data.priceRows.length, 3);
      expect(data.prices[18]!.pricePerGram, 551000);
      expect(data.prices[24]!.date, d('2026-10-02'));
    });

    test('disposed items count nowhere; values use the current price', () async {
      await gold.addItem(item('Bangle'));
      await gold.addItem(item('Old ring', disposed: d('2026-05-01')));
      await gold.savePrices(d('2026-10-02'), {18: 551000});
      final data = await gold.load();
      expect(data.held.length, 1);
      expect(data.disposed.single.disposedDate, '2026-05-01');
      expect(data.totals.value, 13775000);
      expect(data.valueOf(data.held.single), 13775000);
    });

    test('delete, Undo, then tombstone', () async {
      final id = await gold.addItem(item('Bangle'));
      final row = await gold.deleteItem(id);
      expect((await gold.load()).items, isEmpty);
      await gold.restoreItem(row);
      expect((await gold.load()).items.single.name, 'Bangle');
      await gold.deleteItem(id);
      await gold.recordItemDeleted(id);
      expect(await deletions.isDeleted(goldItemEntity, id), isTrue);
    });

    test('editing without changes keeps updated_at', () async {
      final id = await gold.addItem(item('Bangle'));
      final before = (await gold.load()).items.single.updatedAt;
      await gold.editItem(id, item('Bangle'));
      expect((await gold.load()).items.single.updatedAt, before);
    });
  });

  group('expenses', () {
    ExpenseInput e(String item, int amount, String date, {String vendor = 'Shopee'}) =>
        ExpenseInput(item: item, vendor: vendor, amount: amount, date: d(date));

    test('newest first; refunded keeps the row and records when', () async {
      final a = await expenses.add(e('Air fryer', 349900, '2026-10-03'));
      await expenses.add(e('Earbuds', 129900, '2026-10-12'));
      await expenses.setRefunded(a, true);
      final data = await expenses.load();
      expect(data.rows.first.item, 'Earbuds');
      final r = data.byId(a)!;
      expect(r.isRefunded, isTrue);
      expect(r.refundedAt, isNotNull);
      await expenses.setRefunded(a, false);
      expect((await expenses.load()).byId(a)!.refundedAt, isNull);
    });

    test('watch re-emits on every write (no skipped "same" results)', () async {
      final seen = <int>[];
      final sub = expenses.watch().listen((d) => seen.add(d.rows.length));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await expenses.add(e('A', 100, '2026-10-01'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await expenses.add(e('B', 100, '2026-10-01'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await sub.cancel();
      expect(seen, [0, 1, 2]);
    });

    test('delete, Undo, then tombstone', () async {
      final id = await expenses.add(e('Lamp', 50000, '2026-10-01'));
      final row = await expenses.delete(id);
      await expenses.restore(row);
      expect((await expenses.load()).rows.length, 1);
      await expenses.delete(id);
      await expenses.recordDeleted(id);
      expect(await deletions.isDeleted(expenseEntity, id), isTrue);
    });
  });

  group('lists', () {
    test('vendors come from expenses and gold, most used first; hidden ones are left out', () async {
      await expenses.add(ExpenseInput(item: 'a', vendor: 'Lazada', amount: 1, date: oct1));
      await expenses.add(ExpenseInput(item: 'b', vendor: 'Shopee', amount: 1, date: oct1));
      await gold.addItem(item('Bangle', vendor: 'Shopee'));
      expect(await lists.suggestions(ListField.vendor), ['Shopee', 'Lazada']);
      await lists.setHidden(ListField.vendor, 'lazada', true);
      expect(await lists.suggestions(ListField.vendor), ['Shopee']);
      expect((await lists.values(ListField.vendor)).last.hidden, isTrue);
      await lists.setHidden(ListField.vendor, 'Lazada', false);
      expect(await lists.suggestions(ListField.vendor), ['Shopee', 'Lazada']);
    });

    test('rename updates every record in one go, and can merge', () async {
      await expenses.add(ExpenseInput(item: 'a', vendor: 'shopee', amount: 1, date: oct1));
      await gold.addItem(item('Bangle', vendor: 'shopee'));
      await expenses.add(ExpenseInput(item: 'b', vendor: 'Shopee', amount: 1, date: oct1));
      expect(await lists.rename(ListField.vendor, 'shopee', 'Shopee'), 2);
      expect(await lists.values(ListField.vendor), hasLength(1));
      expect((await gold.load()).items.single.vendor, 'Shopee');
    });

    test('platform and type come from savings accounts', () async {
      final s = SavingsRepo(db, deletions);
      await s.addAccount(name: 'A', platform: 'Bank', type: 'Savings', startBalance: 1, asOf: oct1);
      await s.addAccount(name: 'B', platform: 'Digital bank', startBalance: 1, asOf: oct1);
      await s.addAccount(name: 'C', platform: 'Digital bank', startBalance: 1, asOf: oct1);
      expect(await lists.suggestions(ListField.platform), ['Digital bank', 'Bank']);
      expect(await lists.suggestions(ListField.type), ['Savings']);
    });
  });
}
