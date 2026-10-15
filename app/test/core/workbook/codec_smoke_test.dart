import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/workbook/workbook.dart';

void main() {
  test('round trip of every cell kind', () {
    final book = Workbook([
      WbSheet('Read me', ['About'], [['This is OZONE']]),
      WbSheet('Expenses', ['ID', 'Item', 'Amount', 'Date', 'Grams', 'Karat'], [
        ['00123', 'Rice', const MoneyValue(129950), LocalDate(2026, 10, 3), const GramsValue(25005), const NumberValue(18)],
        [null, 'Ünïcode ✓ 日本', const MoneyValue(1), LocalDate(2024, 2, 29), null, null],
      ]),
    ]);
    final back = XlsxCodec.decode(XlsxCodec.encode(book));
    expect(back.sheets.map((s) => s.name), ['Read me', 'Expenses']);
    final e = back.sheet('expenses')!;
    expect(e.headers, ['ID', 'Item', 'Amount', 'Date', 'Grams', 'Karat']);
    // ignore: avoid_print
    print(e.rows);
    expect(e.rows[0][0], '00123');
    expect(e.rows[0][1], 'Rice');
    expect(e.rows[0][2], 1299.5);
    expect(e.rows[0][3], LocalDate(2026, 10, 3));
    expect(e.rows[0][4], 25.005);
    expect(e.rows[0][5], 18);
    expect(e.rows[1][1], 'Ünïcode ✓ 日本');
    expect(e.rows[1][3], LocalDate(2024, 2, 29));
  });
}
