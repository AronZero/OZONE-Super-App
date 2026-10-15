import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/domain/ids.dart';
import 'package:ozone/core/search/query_parser.dart';
import 'package:ozone/core/search/search_index.dart';
import 'package:ozone/core/search/search_repo.dart';
import 'package:ozone/tools/finance/data/expenses_repo.dart';
import 'package:ozone/tools/finance/data/gold_repo.dart';
import 'package:ozone/tools/finance/data/savings_repo.dart';
import 'package:ozone/tools/library/data/books_repo.dart';
import 'package:ozone/tools/library/domain/library.dart';
import 'package:ozone/tools/notes/data/notes_repo.dart';

import '../../helpers/harness.dart';

List<Object?> _text(String s) => [
      {'insert': '$s\n'},
    ];

String _plain(String marked) => marked.replaceAll(RegExp('[\u0001\u0002]'), '');

void main() {
  group('query parsing (F2-02 §1)', () {
    test('nothing before 2 characters; every word a prefix term, all must match', () {
      expect(buildMatch(' a '), isNull);
      expect(buildMatch('go'), '{title body extra} : ("go"*)');
      expect(buildMatch('Gold  Chain'), '{title body extra} : ("gold"* AND "chain"*)');
    });

    test('quotes and operators typed by the person are only text', () {
      expect(buildMatch('"a" OR NOT b*'), '{title body extra} : ("a"* AND "or"* AND "not"* AND "b"*)');
      expect(buildMatch('***'), isNull);
    });

    test('amount-like words also match the exact amount', () {
      for (final w in ['1299', '1,299', '1299.00', '₱1,299', '1,299.0']) {
        expect(amountCentavos(w), 129900, reason: w);
      }
      expect(amountCentavos('1299.5'), 129950);
      expect(amountCentavos('12,99'), isNull);
      expect(amountCentavos('abc'), isNull);
      expect(buildMatch('₱1,299'), '{title body extra} : (("1 299"* OR "129900"))');
    });

    test('highlight markers split into runs', () {
      expect(highlightRuns('a \u0001Gold\u0002 bar'), [('a ', false), ('Gold', true), (' bar', false)]);
    });
  });

  group('index kept in step (F3-03 database)', () {
    late AppDatabase db;
    late SearchRepo search;
    late NotesRepo notes;

    setUp(() async {
      db = memoryDb();
      search = SearchRepo(db, SettingsRepo(db));
      notes = NotesRepo(db, DeletionsRepo(db));
      final d = DeletionsRepo(db);
      final savings = SavingsRepo(db, d);
      await savings.addAccount(name: 'Payroll Savings', platform: 'BPI', type: 'Savings', startBalance: 12345678, asOf: LocalDate(2026, 10, 1));
      final gold = GoldRepo(db, d);
      await gold.addItem(GoldItemInput(name: 'Gold bangle', weightMg: 25000, karat: 18, vendor: 'Tita Café', purchaseDate: LocalDate(2025, 1, 2), cost: 9000000));
      final exp = ExpensesRepo(db, d);
      await exp.add(ExpenseInput(item: 'Gold-plated earring hooks', vendor: 'Shopee', amount: 18000, date: LocalDate(2026, 8, 21)));
      await exp.add(ExpenseInput(item: 'Rice cooker', vendor: 'Lazada', amount: 129900, date: LocalDate(2026, 9, 1)));
      await BooksRepo(db, d).add(const BookInput(title: 'Golden Son', author: 'Pierce Brown', status: BookStatus.reading, acquisition: Acquisition.free));
      final n = await notes.create(tagIds: [await notes.ensureTag('travel')]);
      await notes.save(n, title: 'Trip plan', ops: _text('souvenir: small gold pendant for Mom'));
    });
    tearDown(() => db.close());

    test('groups with counts; title matches rank first', () async {
      final r = await search.search('gold');
      expect({for (final g in r) g.entity: g.count}, {'gold_item': 1, 'expense': 1, 'book': 1, 'note': 1});
      expect(_plain(r.firstWhere((g) => g.entity == 'note').hits.single.snippet), contains('gold pendant'));
      expect(r.firstWhere((g) => g.entity == 'gold_item').hits.single.title, '\u0001Gold\u0002 bangle');
    });

    test('accents and case are ignored; words match from their start', () async {
      expect((await search.search('cafe')).single.entity, 'gold_item');
      expect((await search.search('TITA caf')).single.entity, 'gold_item');
      expect(await search.search('old'), isEmpty, reason: 'no match inside a word');
    });

    test('amounts match exactly, in any typed form', () async {
      for (final q in ['1299', '1,299', '₱1,299.00', '129900']) {
        final r = await search.search(q);
        expect(r.single.entity, 'expense', reason: q);
      }
      // The latest balance of an account is searchable too.
      expect((await search.search('123,456.78')).single.entity, 'savings_account');
      expect((await search.search('18k')).single.entity, 'gold_item');
    });

    test('labels: refunded, archived; tags are searchable; a tag rename follows', () async {
      final id = (await db.select(db.expenses).get()).firstWhere((e) => e.item == 'Rice cooker').id;
      await ExpensesRepo(db, DeletionsRepo(db)).setRefunded(id, true);
      expect((await search.search('rice')).single.hits.single.label, 'Refunded');
      expect((await search.search('travel')).single.entity, 'note');
      final tag = (await db.select(db.tags).get()).single;
      await notes.renameTag(tag.id, 'trips');
      expect(await search.search('travel'), isEmpty);
      expect((await search.search('trips')).single.entity, 'note');
    });

    test('trashed and locked notes are never in the index', () async {
      final n = (await db.select(db.notes).get()).single.id;
      await notes.trash(n);
      expect(await search.search('pendant'), isEmpty);
      await notes.restore(n);
      expect((await search.search('pendant')).single.entity, 'note');
      await notes.lockNote(n, 'AQ==');
      expect(await search.search('pendant'), isEmpty);
      expect(await search.search('trip'), isEmpty);
      final rows = await db.customSelect("SELECT count(*) AS c FROM search_index WHERE entity = 'note'").getSingle();
      expect(rows.read<int>('c'), 0);
    });

    test('deleting a record removes its row', () async {
      final b = (await db.select(db.books).get()).single.id;
      await BooksRepo(db, DeletionsRepo(db)).delete(b);
      expect((await search.search('golden')), isEmpty);
    });

    test('a rebuild gives the same results as the triggers', () async {
      final before = await search.search('gold');
      await SearchIndex.rebuild(db);
      final after = await search.search('gold');
      expect([for (final g in after) (g.entity, g.count)], [for (final g in before) (g.entity, g.count)]);
    });

    test('recent searches: last 5, newest first, no repeats', () async {
      for (final q in ['gold', 'rice', 'book', 'tita', 'shopee', 'GOLD', 'x']) {
        await search.remember(q);
      }
      expect(await SettingsRepo(db).get(SettingKeys.searchRecent), ['GOLD', 'shopee', 'tita', 'book', 'rice']);
      await search.clearRecent();
      expect(await SettingsRepo(db).get(SettingKeys.searchRecent), isEmpty);
    });
  });

  test('under 100 ms with 20,000 indexed rows (F2-03 §8, on the PC)', () async {
    final db = memoryDb();
    final now = DateTime.now().millisecondsSinceEpoch;
    const words = ['rice', 'coffee', 'gold', 'book', 'phone', 'shoes', 'gift', 'grocery', 'bus', 'lunch'];
    await db.batch((b) {
      for (var i = 0; i < 20000; i++) {
        b.insert(db.expenses, ExpensesCompanion.insert(
          id: newId(), item: '${words[i % 10]} item $i', vendor: 'Vendor ${i % 50}', amount: 1000 + i, date: '2026-01-01',
          createdAt: now, updatedAt: now,
        ));
      }
    });
    final search = SearchRepo(db, SettingsRepo(db));
    await search.search('gold'); // warm up
    final sw = Stopwatch()..start();
    final r = await search.search('gold ite');
    sw.stop();
    expect(r.single.count, 2000);
    expect(sw.elapsedMilliseconds, lessThan(100));
    await db.close();
  });

  test('migration v1 → v2 builds the index for existing data', () async {
    final dir = await Directory.systemTemp.createTemp('ozone_mig');
    final file = File('${dir.path}/ozone.db');
    // Make a v1 database: today's schema minus the M7 parts, marked as version 1.
    var db = AppDatabase(NativeDatabase(file));
    await BooksRepo(db, DeletionsRepo(db)).add(const BookInput(title: 'Dune', status: BookStatus.notStarted, acquisition: Acquisition.free));
    final triggers = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'").get();
    for (final t in triggers) {
      await db.customStatement('DROP TRIGGER ${t.read<String>('name')}');
    }
    await db.customStatement('DROP TABLE search_keys');
    await db.customStatement('DELETE FROM search_index');
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    final search = SearchRepo(db, SettingsRepo(db));
    expect((await search.search('dune')).single.entity, 'book');
    final meta = await (db.select(db.appMeta)..where((m) => m.key.equals('schema_version'))).getSingle();
    expect(meta.value, '2');
    // And the triggers are back.
    await BooksRepo(db, DeletionsRepo(db)).add(const BookInput(title: 'Emma', status: BookStatus.notStarted, acquisition: Acquisition.free));
    expect((await search.search('emma')).single.entity, 'book');
    await db.close();
    await dir.delete(recursive: true);
  });
}
