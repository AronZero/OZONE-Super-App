import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/domain/ids.dart';
import 'package:ozone/core/workbook/ozone_export.dart';
import 'package:ozone/core/workbook/ozone_import.dart';
import 'package:ozone/core/workbook/workbook.dart';

import '../../helpers/harness.dart';

void main() {
  test('10,000 rows + 500 notes: export and read times (F1-03 budgets, measured on the PC)', () async {
    final db = memoryDb();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.batch((b) {
      for (var i = 0; i < 10000; i++) {
        b.insert(db.expenses, ExpensesCompanion.insert(
          id: newId(), item: 'Item $i', vendor: 'Vendor ${i % 40}', amount: 1000 + i, date: '2026-0${1 + i % 9}-1${i % 9}', createdAt: now, updatedAt: now,
        ));
      }
      for (var i = 0; i < 500; i++) {
        b.insert(db.notes, NotesCompanion.insert(
          id: newId(), title: Value('Note $i'), content: Value(jsonEncode([{'insert': 'Some text for note $i, a few words long.\n'}])),
          plainText: Value('Some text for note $i, a few words long.'), editedAt: now + 1, createdAt: now, updatedAt: now,
        ));
      }
    });
    final sw = Stopwatch()..start();
    final book = await buildWorkbook(db, appVersion: 't');
    final buildMs = sw.elapsedMilliseconds;
    final bytes = XlsxCodec.encode(book);
    final exportMs = sw.elapsedMilliseconds;
    // ignore: avoid_print
    print('build ${buildMs}ms');
    sw.reset();
    final back = XlsxCodec.decode(bytes);
    final plan = await planImport(db, back, fileName: 'x', today: LocalDate(2026, 10, 13));
    final readMs = sw.elapsedMilliseconds;
    // ignore: avoid_print
    print('export ${exportMs}ms (${(bytes.length / 1024).round()} KB) · read+classify ${readMs}ms');
    expect(plan.rows.where((r) => r.cls == RowClass.same).length, 10500);
    expect(exportMs, lessThan(10000));
    expect(readMs, lessThan(8000));
    await db.close();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
