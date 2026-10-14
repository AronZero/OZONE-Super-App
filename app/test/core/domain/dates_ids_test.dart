import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/domain/ids.dart';
import 'package:ozone/core/domain/validation.dart';

void main() {
  group('LocalDate', () {
    final today = LocalDate(2026, 10, 13);

    test('ISO round trip and strict parsing', () {
      expect((LocalDate.parseIso('2026-10-13') as Ok<LocalDate>).value, today);
      expect(LocalDate.parseIso('10/03/2026'), isA<Invalid<LocalDate>>());
      expect(LocalDate.parseIso('2026-02-30'), isA<Invalid<LocalDate>>());
      expect(today.toIso(), '2026-10-13');
    });
    test('display: year only outside the current year', () {
      expect(LocalDate(2026, 10, 9).format(today), '9 Oct');
      expect(LocalDate(2025, 10, 13).format(today), '13 Oct 2025');
    });
    test('month ends, leap years, month arithmetic', () {
      expect(LocalDate(2028, 2, 3).monthEnd, LocalDate(2028, 2, 29));
      expect(LocalDate(2026, 1, 31).addMonths(1), LocalDate(2026, 2, 28));
      expect(LocalDate(2026, 1, 15).addMonths(-1), LocalDate(2025, 12, 15));
      expect(LocalDate(2026, 10, 13).addMonths(-12), LocalDate(2025, 10, 13));
    });
    test('day differences', () {
      expect(LocalDate(2026, 9, 2).daysUntil(today), 41);
      expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
    });
  });

  group('IDs', () {
    test('UUID v4, lower case, unique', () {
      final ids = {for (var i = 0; i < 1000; i++) newId()};
      expect(ids.length, 1000);
      for (final id in ids.take(20)) {
        expect(isId(id), isTrue, reason: id);
        expect(id[14], '4');
      }
    });
  });
}
