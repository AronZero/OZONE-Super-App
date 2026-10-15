import 'package:excel/excel.dart' as xl;

import '../domain/dates.dart';
import 'cells.dart';

/// Values written to a cell (F1-02 §3). Plain [String]s are text cells.
class MoneyValue {
  const MoneyValue(this.centavos);
  final int centavos;
}

class GramsValue {
  const GramsValue(this.mg);
  final int mg;
}

/// A whole number cell (karat, order, rating halves are written as numbers).
class NumberValue {
  const NumberValue(this.value);
  final num value;
}

/// One sheet: a name, its header row and rows of cells. When written, a cell is
/// null, [String], [MoneyValue], [GramsValue], [NumberValue] or [LocalDate];
/// when read, it is null, [String], [num], [bool], [LocalDate] or [DateTime].
class WbSheet {
  WbSheet(this.name, this.headers, [List<List<Object?>>? rows]) : rows = rows ?? [];
  final String name;
  final List<String> headers;
  final List<List<Object?>> rows;

  /// Column index of a header, matched by name ignoring case and spaces (F1-02 §2).
  int? column(String header) {
    final k = headerKey(header);
    for (var i = 0; i < headers.length; i++) {
      if (headerKey(headers[i]) == k) return i;
    }
    return null;
  }

  /// Rows as maps keyed by [headerKey], with their 1-based sheet row number.
  Iterable<(int, Map<String, Object?>)> records() sync* {
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      if (row.every(isBlank)) continue; // empty lines people leave behind
      yield (r + 2, {for (var c = 0; c < headers.length; c++) headerKey(headers[c]): c < row.length ? row[c] : null});
    }
  }
}

/// A whole workbook, independent of the xlsx library.
class Workbook {
  Workbook(this.sheets);
  final List<WbSheet> sheets;

  WbSheet? sheet(String name) {
    final k = headerKey(name);
    for (final s in sheets) {
      if (headerKey(s.name) == k) return s;
    }
    return null;
  }
}

/// Reads and writes `.xlsx` with the `excel` package (F3-02), behind this one class.
abstract final class XlsxCodec {
  static final _bold = xl.CellStyle(bold: true);
  static final _money = xl.CellStyle(numberFormat: const xl.CustomNumericNumFormat(formatCode: '#,##0.00'));
  static final _grams = xl.CellStyle(numberFormat: const xl.CustomNumericNumFormat(formatCode: '0.000'));
  static final _date = xl.CellStyle(numberFormat: const xl.CustomDateTimeNumFormat(formatCode: 'yyyy-mm-dd'));

  static List<int> encode(Workbook book) {
    final x = xl.Excel.createExcel();
    final first = x.getDefaultSheet()!;
    for (final s in book.sheets) {
      final sheet = x[s.name];
      for (var c = 0; c < s.headers.length; c++) {
        sheet.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0), xl.TextCellValue(s.headers[c]), cellStyle: _bold);
      }
      for (var r = 0; r < s.rows.length; r++) {
        final row = s.rows[r];
        for (var c = 0; c < row.length; c++) {
          final v = row[c];
          if (v == null) continue;
          final at = xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1);
          switch (v) {
            case MoneyValue(:final centavos):
              sheet.updateCell(at, xl.DoubleCellValue(centavos / 100), cellStyle: _money);
            case GramsValue(:final mg):
              sheet.updateCell(at, xl.DoubleCellValue(mg / 1000), cellStyle: _grams);
            case NumberValue(:final value):
              sheet.updateCell(at, value is int ? xl.IntCellValue(value) : xl.DoubleCellValue(value.toDouble()));
            case LocalDate():
              sheet.updateCell(at, xl.DateCellValue(year: v.year, month: v.month, day: v.day), cellStyle: _date);
            default:
              // Written as a string cell, so Excel keeps IDs that look like numbers as text.
              sheet.updateCell(at, xl.TextCellValue(v.toString()));
          }
        }
      }
      for (var c = 0; c < s.headers.length; c++) {
        sheet.setColumnWidth(c, s.headers[c].length < 10 ? 14 : s.headers[c].length + 6.0);
      }
    }
    if (!book.sheets.any((s) => s.name == first)) x.delete(first);
    x.setDefaultSheet(book.sheets.first.name);
    return x.encode()!;
  }

  /// Throws [FormatException] when the bytes aren't a readable workbook.
  static Workbook decode(List<int> bytes) {
    final xl.Excel x;
    try {
      x = xl.Excel.decodeBytes(bytes);
    } on Object {
      throw const FormatException('This file can’t be opened as a workbook (.xlsx).');
    }
    final sheets = <WbSheet>[];
    for (final MapEntry(key: name, value: t) in x.tables.entries) {
      final rows = t.rows;
      if (rows.isEmpty) {
        sheets.add(WbSheet(name, const []));
        continue;
      }
      final headers = [for (final c in rows.first) c?.value == null ? '' : '${_read(c!.value)}'];
      sheets.add(WbSheet(name, headers, [
        for (final r in rows.skip(1)) [for (final c in r) _read(c?.value)],
      ]));
    }
    return Workbook(sheets);
  }

  static Object? _read(xl.CellValue? v) => switch (v) {
        null => null,
        xl.TextCellValue() => v.value.toString(),
        xl.IntCellValue(:final value) => value,
        xl.DoubleCellValue(:final value) => value,
        xl.BoolCellValue(:final value) => value,
        xl.DateCellValue(:final year, :final month, :final day) => LocalDate(year, month, day),
        xl.DateTimeCellValue(:final year, :final month, :final day, :final hour, :final minute, :final second) =>
          hour == 0 && minute == 0 && second == 0 ? LocalDate(year, month, day) : DateTime.utc(year, month, day, hour, minute, second),
        // Text formulas carry their cached value; numeric ones fail their column's check.
        xl.FormulaCellValue(:final formula) => formula,
        xl.TimeCellValue() => v.toString(),
      };
}
