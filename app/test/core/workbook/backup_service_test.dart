import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/workbook/backup_service.dart';
import 'package:ozone/core/workbook/ozone_export.dart';
import 'package:ozone/core/workbook/ozone_import.dart';
import 'package:ozone/tools/finance/data/expenses_repo.dart';

import '../../helpers/harness.dart';

/// Export, safety exports, the blank template and refused files (F1-03).
void main() {
  late AppDatabase db;
  late Directory root;
  late BackupService backup;
  final today = LocalDate(2026, 10, 15);

  setUp(() async {
    db = memoryDb();
    root = Directory.systemTemp.createTempSync('ozone_backup_service');
    backup = BackupService(db, workDir: () async => Directory('${root.path}/exports'), safetyDir: () async => Directory('${root.path}/safety'),
        heavy: <R>(R Function() work) async => work());
    await ExpensesRepo(db, DeletionsRepo(db)).add(ExpenseInput(item: 'Rice', vendor: 'SM', amount: 120000, date: LocalDate(2026, 10, 1)));
  });
  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  test('the export runs off the UI thread by default and reads back the same', () async {
    final real = BackupService(db, workDir: () async => Directory('${root.path}/exports'), safetyDir: () async => Directory('${root.path}/safety'));
    final e = await real.build();
    expect(e.counts['Expenses'], 1);
    final plan = await real.read(await e.file.readAsBytes(), fileName: e.name, today: today);
    expect(plan.rows.where((r) => r.table == 'expenses').single.cls, RowClass.same);
  });

  test('a cancelled export stops without a file', () async {
    await expectLater(backup.build(cancelled: () => true), throwsA(isA<ExportCancelled>()));
  });

  test('the blank template is an OZONE workbook with nothing to import', () async {
    final t = await backup.template();
    expect(t.name, 'OZONE-template.xlsx');
    final plan = await backup.read(await t.file.readAsBytes(), fileName: t.name, today: today);
    expect(plan.rows, isEmpty);
    expect(plan.sheetErrors, isEmpty);
  });

  test('files over 25 MB and files that aren’t workbooks are refused in words', () async {
    await expectLater(backup.read(List.filled(BackupService.maxBytes + 1, 0), fileName: 'big.xlsx', today: today),
        throwsA(isA<ImportRefused>().having((e) => e.message, 'message', contains('over 25 MB'))));
    await expectLater(backup.read([1, 2, 3, 4], fileName: 'notes.txt', today: today), throwsA(isA<ImportRefused>()));
  });

  test('safety exports keep the newest 3, on disk and in the log', () async {
    for (var i = 0; i < 4; i++) {
      await backup.safetyExport();
    }
    final files = await backup.safetyExports();
    expect(files, hasLength(3));
    final logged = await (db.select(db.exportsLog)..where((x) => x.kind.equals('safety'))).get();
    expect(logged.map((l) => l.fileName).toSet(), {for (final f in files) f.uri.pathSegments.last});
  });

  test('an import makes a safety export first; a restore onto an empty phone does not', () async {
    final e = await backup.build();
    final plan = await backup.read(await e.file.readAsBytes(), fileName: e.name, today: today);
    final (safety, _) = await backup.apply(plan);
    expect(safety, isNotNull);
    expect(safety!.existsSync(), isTrue);
    final (none, _) = await backup.apply(plan, restore: true);
    expect(none, isNull);
  });
}
