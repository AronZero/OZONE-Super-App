import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/photo_store.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/search/search_repo.dart';
import 'package:ozone/core/workbook/backup_service.dart';
import 'package:ozone/core/workbook/backup_zip.dart';
import 'package:ozone/core/workbook/ozone_import.dart';
import 'package:ozone/core/workbook/workbook.dart';
import 'package:ozone/tools/recipe/data/recipes_repo.dart';

import '../../helpers/harness.dart';
import '../../tools/recipe/recipes_repo_test.dart' show adobo;

final today = LocalDate(2026, 10, 19);

/// One phone: a database, its photo store and its backup service.
class Phone {
  Phone() {
    db = memoryDb();
    photos = testPhotos();
    backup = testBackup(db, photos: photos);
    recipes = RecipesRepo(db, DeletionsRepo(db), photos);
  }
  late final AppDatabase db;
  late final PhotoStore photos;
  late final BackupService backup;
  late final RecipesRepo recipes;
}

/// A sample JPEG's bytes (only the start matters to OZONE).
final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List.generate(500, (i) => i % 251)]);

Future<String> addPhoto(Phone p) async {
  final src = File('${Directory.systemTemp.createTempSync('pick').path}/p.jpg')..writeAsBytesSync(jpeg);
  return p.photos.adopt(src.path);
}

/// Writes a zip with [entries] (name → bytes) and returns it.
File zipOf(Map<String, List<int>> entries) {
  final dir = Directory.systemTemp.createTempSync('ozone_zip');
  addTearDown(() => dir.deleteSync(recursive: true));
  final path = '${dir.path}/backup.zip';
  final enc = ZipFileEncoder()..create(path, level: ZipFileEncoder.STORE);
  for (final MapEntry(key: name, value: bytes) in entries.entries) {
    enc.addArchiveFile(ArchiveFile(name, bytes.length, bytes)..compress = false);
  }
  enc.closeSync();
  return File(path);
}

void main() {
  late Phone a;
  setUp(() async {
    a = Phone();
    final photo = await addPhoto(a);
    await a.recipes.add(adobo(photo: photo));
    await a.recipes.add(adobo(title: 'Tortang talong'));
    await a.db.into(a.db.kitchen).insert(KitchenCompanion.insert(keyName: 'garlic', updatedAt: 1));
  });
  tearDown(() => a.db.close());

  test('export is a .zip with the workbook and the photos', () async {
    final e = await a.backup.build();
    expect(e.name, endsWith('.zip'));
    final out = Directory.systemTemp.createTempSync('unzip');
    addTearDown(() => out.deleteSync(recursive: true));
    final z = BackupZip.unpack(e.file.path, out.path);
    final photo = (await a.recipes.load()).recipes.firstWhere((r) => r.row.photoFile != null).row.photoFile!;
    expect(z.photos, {photo});
    expect(File('${z.photoDir}/$photo').readAsBytesSync(), jpeg);
    expect(XlsxCodec.decode(z.workbook).sheet('Recipe ingredients')!.rows.length, 6);
    expect(e.counts['Recipes'], 2);
    expect(e.counts.containsKey('Recipe ingredients'), isFalse, reason: 'parts of a recipe, not records');
  });

  test('round trip onto an empty phone: every recipe, step and photo, byte for byte', () async {
    final e = await a.backup.build();
    final b = Phone();
    addTearDown(b.db.close);
    final plan = await b.backup.readFile(e.file, fileName: e.name, today: today, restore: true);
    expect(plan.counts['Recipes']!.newRows, 2);
    expect(plan.counts['Kitchen']!.newRows, 1);
    expect(plan.photos, (newPhotos: 1, same: 0, missing: 0));
    await b.backup.apply(plan, restore: true);

    final mine = {for (final r in (await a.recipes.load()).recipes) r.id: r};
    final theirs = (await b.recipes.load()).recipes;
    expect(theirs.length, 2);
    for (final r in theirs) {
      final m = mine[r.id]!;
      expect(r.row.title, m.row.title);
      expect(r.row.photoFile, m.row.photoFile);
      expect([for (final i in r.ingredients) (i.section, i.amountMilli, i.unit, i.name, i.keyName)],
          [for (final i in m.ingredients) (i.section, i.amountMilli, i.unit, i.name, i.keyName)]);
      expect([for (final s in r.steps) s.body], [for (final s in m.steps) s.body]);
      if (r.row.photoFile != null) expect((await b.photos.file(r.row.photoFile!)).readAsBytesSync(), jpeg);
    }
    expect([for (final k in await b.db.select(b.db.kitchen).get()) k.keyName], ['garlic']);
    expect(Directory(plan.photoDir!).existsSync(), isFalse, reason: 'unpacked files are removed');

    // Search finds the restored recipes by an ingredient and a step (each indexed once, M14),
    // and the paused child triggers are back: an edit after the import is indexed too.
    final search = SearchRepo(b.db, SettingsRepo(b.db));
    expect((await search.search('bay leaves')).single.count, 2);
    expect((await search.search('marinate')).single.count, 2);

    // The same file again: nothing new, nothing changed.
    final again = await b.backup.readFile(e.file, fileName: e.name, today: today);
    expect(again.counts['Recipes']!.newRows, 0);
    expect(again.counts['Recipes']!.changed, 0);
    expect(again.counts['Recipes']!.same, 2);
    expect(again.photos, (newPhotos: 0, same: 0, missing: 0), reason: 'Same rows aren’t written');
    b.backup.discard(again);

    final talong = theirs.firstWhere((r) => r.row.title == 'Tortang talong').id;
    await b.recipes.edit(talong, adobo(title: 'Tortang talong', steps: const ['Grill the eggplant.']));
    expect([for (final h in (await search.search('grill eggplant')).single.hits) h.recordId], [talong]);
  });

  test('a plain .xlsx imports without touching the phone’s photos', () async {
    final e = await a.backup.build();
    final out = Directory.systemTemp.createTempSync('unzip');
    addTearDown(() => out.deleteSync(recursive: true));
    final xlsx = File('${out.path}/OZONE.xlsx')..writeAsBytesSync(BackupZip.unpack(e.file.path, out.path).workbook);
    final plan = await a.backup.readFile(xlsx, fileName: 'OZONE.xlsx', today: today);
    expect(plan.photos, isNull);
    expect(plan.counts['Recipes']!.same, 2, reason: 'the phone keeps its photo');
  });

  test('a changed ingredient makes the recipe Changed, shown as counts', () async {
    final e = await a.backup.build();
    final out = Directory.systemTemp.createTempSync('unzip');
    addTearDown(() => out.deleteSync(recursive: true));
    final book = XlsxCodec.decode(BackupZip.unpack(e.file.path, out.path).workbook);
    final s = book.sheet('Recipe ingredients')!;
    s.rows.first[s.column('Name')!] = 'chicken legs';
    final xlsx = File('${out.path}/edited.xlsx')..writeAsBytesSync(XlsxCodec.encode(book));
    final plan = await a.backup.readFile(xlsx, fileName: 'edited.xlsx', today: today);
    final changed = plan.rows.singleWhere((r) => r.cls == RowClass.changed);
    expect(changed.diffs.single.$1, 'Ingredients and steps');
    expect(changed.diffs.single.$2, '3 ingredients, 2 steps');
    expect(changed.apply, isFalse, reason: 'Keep mine');
  });

  test('a photo missing from the zip is listed; the recipe still imports', () async {
    final e = await a.backup.build();
    final out = Directory.systemTemp.createTempSync('unzip');
    addTearDown(() => out.deleteSync(recursive: true));
    final wb = BackupZip.unpack(e.file.path, out.path).workbook;
    final b = Phone();
    addTearDown(b.db.close);
    final plan = await b.backup.readFile(zipOf({'OZONE.xlsx': wb}), fileName: 'backup.zip', today: today);
    final err = plan.rows.singleWhere((r) => r.entity == 'recipe_photo');
    expect(err.reason, 'Photo for Chicken adobo is missing from the file');
    expect(plan.photos!.missing, 1);
    await b.backup.apply(plan);
    expect([for (final r in (await b.recipes.load()).recipes) r.row.photoFile], [null, null]);
  });

  test('unsafe or broken zips are refused in words; a fake JPEG counts as missing', () async {
    final wb = XlsxCodec.encode(Workbook([WbSheet('Recipes', ['Title'])]));
    Future<String> refused(Map<String, List<int>> entries) async {
      try {
        await a.backup.readFile(zipOf(entries), fileName: 'backup.zip', today: today);
      } on ImportRefused catch (e) {
        return e.message;
      }
      fail('not refused');
    }

    expect(await refused({'OZONE.xlsx': wb, '../evil.jpg': jpeg}), 'This backup file is damaged.');
    expect(await refused({'photos/a.jpg': jpeg}), contains('It should hold one workbook'));
    expect(await refused({'a.xlsx': wb, 'b.xlsx': wb}), contains('It should hold one workbook'));
    expect(await refused({'notes.txt': [1, 2, 3]}), contains('It should hold one workbook'));

    final out = Directory.systemTemp.createTempSync('unzip');
    addTearDown(() => out.deleteSync(recursive: true));
    const name = '3f1c2b4a-1111-4222-8333-444455556666.jpg';
    final z = BackupZip.unpack(zipOf({'OZONE.xlsx': wb, 'photos/$name': [1, 2, 3, 4]}).path, out.path);
    expect(z.photos, isEmpty);
  });

  test('a failed import removes the photos it copied', () async {
    final e = await a.backup.build();
    final b = Phone();
    addTearDown(b.db.close);
    final plan = await b.backup.readFile(e.file, fileName: e.name, today: today, restore: true);
    await b.db.close(); // the transaction can't run
    await expectLater(b.backup.apply(plan, restore: true), throwsA(anything));
    expect((await b.photos.folder()).listSync(), isEmpty);
  });
}
