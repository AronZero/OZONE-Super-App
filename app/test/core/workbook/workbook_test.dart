import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/domain/validation.dart';
import 'package:ozone/core/search/search_repo.dart';
import 'package:ozone/core/workbook/cells.dart';
import 'package:ozone/core/workbook/ozone_export.dart';
import 'package:ozone/core/workbook/ozone_import.dart';
import 'package:ozone/core/workbook/workbook.dart';
import 'package:ozone/tools/finance/data/expenses_repo.dart';
import 'package:ozone/tools/finance/data/gold_repo.dart';
import 'package:ozone/tools/finance/data/savings_repo.dart';
import 'package:ozone/tools/library/data/books_repo.dart';
import 'package:ozone/tools/library/domain/library.dart';
import 'package:ozone/tools/notes/data/notes_repo.dart';
import 'package:ozone/tools/notes/state/notes_vault.dart';

import '../../helpers/harness.dart';

final today = LocalDate(2026, 10, 13);

Future<void> seed(AppDatabase db) async {
  final d = DeletionsRepo(db);
  final s = SavingsRepo(db, d);
  await s.addAccount(name: 'Payroll Savings', platform: 'BPI', type: 'Savings', remarks: 'Auto-sweep', startBalance: 12345678, asOf: LocalDate(2026, 9, 30));
  await s.addAccount(name: 'Old Account', startBalance: 0, asOf: LocalDate(2025, 1, 1));
  final old = (await s.load()).accounts.firstWhere((a) => a.name == 'Old Account').id;
  await s.archive(old, LocalDate(2026, 1, 5));
  final g = GoldRepo(db, d);
  await g.addItem(GoldItemInput(name: 'Gold bangle', weightMg: 25005, karat: 18, vendor: 'Tita', purchaseDate: LocalDate(2025, 1, 2), cost: 9000050));
  await g.addItem(GoldItemInput(name: 'Ring', weightMg: 3000, karat: 21, purchaseDate: LocalDate(2024, 3, 3), cost: 1500000, disposedDate: LocalDate(2026, 2, 2)));
  await g.savePrices(LocalDate(2026, 10, 1), {18: 551000, 21: 643000});
  final e = ExpensesRepo(db, d);
  await e.add(ExpenseInput(item: 'Rice cooker', vendor: 'Lazada', amount: 129900, date: LocalDate(2026, 9, 1), remarks: 'Gift'));
  final refunded = await e.add(ExpenseInput(item: 'Headset', vendor: 'Shopee', amount: 120000, date: LocalDate(2025, 9, 5)));
  await e.setRefunded(refunded, true);
  final b = BooksRepo(db, d);
  await b.add(BookInput(title: 'Dune', author: 'Frank Herbert', sizeKb: 4300, onKindle: true, status: BookStatus.reading, acquisition: Acquisition.purchased, acquired: LocalDate(2026, 1, 1), amount: 45000, ratingHalf: 9));
  await b.add(const BookInput(title: 'Emma', status: BookStatus.notStarted, acquisition: Acquisition.free));
  final n = NotesRepo(db, d);
  final travel = await n.addFolder('Travel');
  final trip = await n.create(folderId: travel, tagIds: [await n.ensureTag('travel'), await n.ensureTag('2026')]);
  await n.save(trip, title: 'Trip plan', ops: [
    {'insert': 'Flights on the '},
    {'insert': '24th', 'attributes': {'bold': true}},
    {'insert': '\n'},
    {'insert': 'Passport'},
    {'insert': '\n', 'attributes': {'list': 'checked'}},
  ]);
  await n.setPinned(trip, true);
  final long = await n.create();
  await n.save(long, title: 'Long', ops: [
    {'insert': '${'😀' * 20000}\n'}, // 40,000 code units: split into 2 parts, never inside a pair
  ]);
  final gone = await n.create();
  await n.save(gone, title: 'In the trash', ops: [{'insert': 'x\n'}]);
  await n.trash(gone);
  final vault = testVault(db, fastKdf: true);
  await vault.create(password: 'harbor-lantern-42', recoveryCode: 'K7QF2M9DXR4T8BWL');
  final secret = await n.create();
  await n.save(secret, title: 'Diary', ops: [{'insert': 'dear diary\n'}]);
  await NotesVault(vault, n).lock(secret);
  final settings = SettingsRepo(db);
  await settings.set(SettingKeys.theme, ThemeChoice.dark);
  await settings.set(SettingKeys.goldStaleDays, 14);
  await settings.set(SettingKeys.searchRecent, ['phone only']); // not in the workbook
}

/// Every table's rows, without updated_at (which an import sets to now).
Future<Map<String, List<Map<String, Object?>>>> dump(AppDatabase db) async {
  final out = <String, List<Map<String, Object?>>>{};
  for (final t in ['savings_accounts', 'balance_updates', 'gold_items', 'karat_prices', 'expenses', 'books', 'folders', 'tags', 'notes', 'note_tags', 'vault']) {
    final rows = await db.customSelect('SELECT * FROM $t ORDER BY ${t == 'tags' ? 'name' : '1, 2'}').get();
    out[t] = [
      for (final r in rows)
        {
          for (final MapEntry(:key, :value) in r.data.entries)
            // Not in the workbook (F1-02 §2): import sets them.
            if (!const {'updated_at', 'refunded_at', 'pinned_at'}.contains(key) && !(t == 'tags' && (key == 'created_at' || key == 'id')) && !(t == 'folders' && key == 'created_at'))
              key: value,
        },
    ];
  }
  out['note_tags'] = [
    for (final r in await db.customSelect('SELECT nt.note_id, t.name FROM note_tags nt JOIN tags t ON t.id = nt.tag_id ORDER BY 1, 2').get()) r.data,
  ];
  return out;
}

Future<Workbook> exported(AppDatabase db) async => XlsxCodec.decode(XlsxCodec.encode(await buildWorkbook(db, appVersion: 'test')));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // the vault's secure-screen channel
  group('cells (F1-02 §3)', () {
    test('money: numbers or text; more than 2 decimals is an error', () {
      expect(moneyCell(1299.5, what: 'Amount').valueOrNull, 129950);
      expect(moneyCell('₱1,234.56', what: 'Amount').valueOrNull, 123456);
      expect(moneyCell(0.1 + 0.2, what: 'Amount').valueOrNull, 30, reason: 'spreadsheet float noise is not a third decimal');
      expect(moneyCell(1.234, what: 'Amount'), isA<Invalid<int>>());
      expect(moneyCell('1.234', what: 'Amount'), isA<Invalid<int>>());
      expect((moneyCell('₱1,2OO', what: 'Amount') as Invalid).reason, 'Amount "₱1,2OO" isn’t a number');
      expect(moneyCell(0, what: 'Balance', allowZero: true).valueOrNull, 0);
    });
    test('dates: date cells or YYYY-MM-DD; ambiguous text and the future are errors', () {
      expect(dateCell('2026-10-03', what: 'Date').valueOrNull, LocalDate(2026, 10, 3));
      expect(dateCell(DateTime(2026, 1, 2), what: 'Date').valueOrNull, LocalDate(2026, 1, 2));
      expect(dateCell('10/03/2026', what: 'Date'), isA<Invalid<LocalDate>>());
      expect((dateCell('2026-12-01', what: 'Date', notAfter: today) as Invalid).reason, 'Date 2026-12-01 is in the future');
    });
    test('yes/no, karat, rating, tags, grams', () {
      expect([for (final v in ['Yes', 'TRUE', 1, 'no', null, false]) yesNoCell(v, what: 'x').valueOrNull], [true, true, true, false, false, false]);
      expect(karatCell('18K').valueOrNull, 18);
      expect(karatCell(25), isA<Invalid<int>>());
      expect(ratingCell(4.5).valueOrNull, 9);
      expect(ratingCell(4.3), isA<Invalid<int?>>());
      expect(tagsCell('#travel, 2026 ideas'), ['travel', '2026', 'ideas']);
      expect(gramsCell(25.005).valueOrNull, 25005);
      expect(gramsCell('1.2345'), isA<Invalid<int>>());
    });
    test('long text splits into parts without breaking a surrogate pair', () {
      final s = 'a${'😀' * 20000}';
      final parts = splitParts(s);
      expect(parts.length, 2);
      expect(parts.every((p) => p.length <= 30000), isTrue);
      expect(parts.join(), s);
      expect(parts[0].codeUnitAt(parts[0].length - 1) >= 0xD800 && parts[0].codeUnitAt(parts[0].length - 1) <= 0xDBFF, isFalse);
    });
  });

  group('round trip (F3-03: "a restore onto a wiped phone gives identical data")', () {
    late AppDatabase db;
    setUp(() async {
      db = memoryDb();
      await seed(db);
    });
    tearDown(() => db.close());

    test('the workbook has every sheet, readable rows and _Meta', () async {
      final book = await exported(db);
      expect(book.sheets.map((s) => s.name), [
        'Read me', '_Meta', 'Accounts', 'Balance updates', 'Gold items', 'Gold prices', 'Expenses', 'Books', 'Folders', 'Notes', 'Notes_Content', //
        'Vault', 'Settings', 'Deleted',
      ]);
      final meta = {for (final (_, r) in book.sheet('_Meta')!.records()) r['key']: r['value']};
      expect(meta['format'], 'ozone-workbook');
      expect(meta['rows.Expenses'], '2');
      final notes = book.sheet('Notes')!;
      final locked = notes.records().firstWhere((x) => x.$2['locked'] == 'Yes').$2;
      expect(locked['title'], 'Locked note');
      expect(locked['text'], 'Locked note');
      final trip = notes.records().firstWhere((x) => x.$2['title'] == 'Trip plan').$2;
      expect(trip['tags'], anyOf('travel, 2026', '2026, travel'));
      expect(trip['folder'], 'Travel');
      expect(book.sheet('Notes_Content')!.rows.where((r) => r[3].toString().contains('😀')).length, 2);
      final settings = {for (final (_, r) in book.sheet('Settings')!.records()) r['key']: r['value']};
      expect(settings['theme'], '"dark"');
      expect(settings.containsKey('search.recent'), isFalse, reason: 'phone-only settings stay out');
      final expenses = book.sheet('Expenses')!;
      expect(expenses.records().map((x) => x.$2['amount']), containsAll([1299.0, 1200.0]));
    });

    test('importing your own export: everything is Same, nothing to write', () async {
      final plan = await planImport(db, await exported(db), fileName: 'x.xlsx', today: today);
      final notSame = plan.rows.where((r) => r.cls != RowClass.same).toList();
      expect([for (final r in notSame) '${r.sheet} ${r.rowNo} ${r.cls} ${r.reason} ${r.diffs}'], isEmpty);
      expect(plan.toWrite, 0);
      expect(plan.sheetErrors, isEmpty);
    });

    test('restore onto a wiped phone gives identical data, vault and search', () async {
      final book = await exported(db);
      final fresh = memoryDb();
      final plan = await planImport(fresh, book, fileName: 'OZONE-2026-10-13.xlsx', today: today, restore: true);
      expect(plan.importVault, isTrue);
      expect(plan.rows.where((r) => r.cls == RowClass.error), isEmpty);
      final written = await applyImport(fresh, plan);
      expect(written['Expenses'], 2);
      expect(await dump(fresh), await dump(db));
      // Settings came with the file; phone-only ones didn't.
      expect(await SettingsRepo(fresh).get(SettingKeys.theme), ThemeChoice.dark);
      expect(await SettingsRepo(fresh).get(SettingKeys.searchRecent), isEmpty);
      // The file's vault password opens the restored locked note.
      final v = testVault(fresh, fastKdf: true);
      expect(await v.unlock('harbor-lantern-42'), isA<Object>());
      expect(v.isOpen.value, isTrue);
      final locked = (await fresh.select(fresh.notes).get()).firstWhere((n) => n.isLocked);
      expect((await v.openNote(locked.id, locked.cipher!)).title, 'Diary');
      // The search index follows (triggers).
      expect((await SearchRepo(fresh, SettingsRepo(fresh)).search('passport')).single.entity, 'note');
      await fresh.close();
    });
  });

  group('classification (F1-03 §2)', () {
    late AppDatabase db;
    late Workbook book;
    setUp(() async {
      db = memoryDb();
      await seed(db);
      book = await exported(db);
    });
    tearDown(() => db.close());

    void setCell(String sheet, String header, bool Function(Map<String, Object?>) where, Object? value) {
      final s = book.sheet(sheet)!;
      final c = s.column(header)!;
      for (final (n, r) in s.records()) {
        if (where(r)) s.rows[n - 2][c] = value;
      }
    }

    test('Changed: Keep mine by default, Use file\'s writes it; the newer side is known', () async {
      setCell('Accounts', 'Remarks', (r) => r['name'] == 'Payroll Savings', 'Auto-sweep stopped Aug');
      setCell('Accounts', 'Updated', (r) => r['name'] == 'Payroll Savings', '2030-01-01T00:00:00.000Z');
      final plan = await planImport(db, book, fileName: 'x', today: today);
      final r = plan.rows.singleWhere((r) => r.cls == RowClass.changed);
      expect(r.diffs, [('Remarks', 'Auto-sweep', 'Auto-sweep stopped Aug')]);
      expect(r.apply, isFalse);
      expect(r.updated! > r.mineUpdated!, isTrue);
      plan.setSheetChoice('Accounts', useFile: true);
      expect(plan.toWrite, 1);
      await applyImport(db, plan);
      final a = (await SavingsRepo(db, DeletionsRepo(db)).load()).accounts.firstWhere((a) => a.name == 'Payroll Savings');
      expect(a.remarks, 'Auto-sweep stopped Aug');
    });

    test('new rows, possible duplicates and errors in words', () async {
      final e = book.sheet('Expenses')!;
      e.rows.add([null, 'Coffee', 'Café Uno', 450.0, LocalDate(2026, 10, 1), 'No', null, null, null]); // new
      e.rows.add([null, 'rice COOKER', 'Lazada', 1299.0, LocalDate(2026, 9, 1), 'No', null, null, null]); // duplicate
      e.rows.add([null, 'Bad', 'X', '₱1,2OO', LocalDate(2026, 9, 1), 'No', null, null, null]); // error
      e.rows.add([null, 'Later', 'X', 10.0, LocalDate(2027, 1, 1), 'No', null, null, null]); // future
      final plan = await planImport(db, book, fileName: 'x', today: today);
      final c = plan.counts['Expenses']!;
      expect([c.newRows, c.changed, c.same, c.check], [1, 0, 2, 3]);
      final reasons = plan.rows.where((r) => r.sheet == 'Expenses' && r.cls == RowClass.error).map((r) => r.reason).toList();
      expect(reasons, ['Row 6: Amount "₱1,2OO" isn’t a number', 'Row 7: Date 2027-01-01 is in the future']);
      expect(plan.rows.singleWhere((r) => r.cls == RowClass.duplicate).apply, isFalse);
      expect(plan.toWrite, 1);
      await applyImport(db, plan);
      expect((await db.select(db.expenses).get()).length, 3);
    });

    test('deleted here is skipped; balance updates find their account by name', () async {
      final exp = (await db.select(db.expenses).get()).first;
      await ExpensesRepo(db, DeletionsRepo(db)).delete(exp.id);
      await ExpensesRepo(db, DeletionsRepo(db)).recordDeleted(exp.id);
      final u = book.sheet('Balance updates')!;
      u.rows.add([null, null, 'payroll savings', LocalDate(2026, 10, 12), 1.0, 'No', null, null, null]);
      u.rows.add([null, null, 'Nobody', LocalDate(2026, 10, 12), 1.0, 'No', null, null, null]);
      final plan = await planImport(db, book, fileName: 'x', today: today);
      expect(plan.rows.singleWhere((r) => r.fileId == exp.id).cls, RowClass.deletedHere);
      expect(plan.rows.where((r) => r.sheet == 'Balance updates' && r.cls == RowClass.newRow).length, 1);
      expect(plan.rows.singleWhere((r) => r.sheet == 'Balance updates' && r.cls == RowClass.error).reason, 'Row 5: Account not found');
    });

    test('a different vault: locked notes need that file\'s password', () async {
      final other = memoryDb();
      final v = testVault(other, fastKdf: true);
      await v.create(password: 'another-password', recoveryCode: 'P3WN6HTA9C2ELQ5V');
      final plan = await planImport(other, book, fileName: 'x', today: today);
      expect(plan.rows.singleWhere((r) => r.cls == RowClass.otherVault).reason, 'Locked with a different vault password');
      await other.close();
    });

    test('refused files and missing columns', () async {
      expect(() => planImport(db, Workbook([WbSheet('Sheet1', ['A'])]), fileName: 'x', today: today), throwsA(isA<ImportRefused>()));
      final newer = await exported(db);
      newer.sheet('_Meta')!.rows.firstWhere((r) => r[0] == 'format_version')[1] = '9';
      expect(
        () => planImport(db, newer, fileName: 'x', today: today),
        throwsA(isA<ImportRefused>().having((e) => e.message, 'message', 'This file is from a newer OZONE. Update the app to import it.')),
      );
      final s = book.sheet('Expenses')!;
      s.headers[s.column('Amount')!] = 'Price';
      final plan = await planImport(db, book, fileName: 'x', today: today);
      expect(plan.sheetErrors, ['Expenses is missing the Amount column, so that sheet was left out.']);
    });

    test('a template filled in by hand (no _Meta, no IDs) imports as new', () async {
      final fresh = memoryDb();
      final b = Workbook([
        WbSheet('Expenses', ['Item', 'Vendor', 'Amount', 'Date'], [
          ['Lunch', 'Jollibee', '₱250', '2026-10-01'],
        ]),
        WbSheet('Notes', ['Title', 'Text'], [
          ['Typed in Excel', 'Hello there'],
        ]),
      ]);
      final plan = await planImport(fresh, b, fileName: 'x', today: today);
      expect(plan.toWrite, 2);
      await applyImport(fresh, plan);
      final n = (await fresh.select(fresh.notes).get()).single;
      expect(n.plainText, 'Hello there');
      expect(jsonDecode(n.content!), [{'insert': 'Hello there\n'}]);
      await fresh.close();
    });
  });
}
