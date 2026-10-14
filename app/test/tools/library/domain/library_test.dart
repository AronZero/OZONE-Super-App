import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/tools/library/domain/library.dart';

LocalDate d(String iso) => LocalDate.parseIso(iso).valueOrNull!;

void main() {
  test('storage units are 1,024-based', () {
    expect(formatStorage(842), '842 KB');
    expect(formatStorage(1023), '1023 KB');
    expect(formatStorage(1024), '1.0 MB');
    expect(formatStorage(4300), '4.2 MB');
    expect(formatStorage(12698), '12.4 MB');
    expect(formatStorage(1447034), '1.38 GB');
  });

  test('ratings: halves 0–5; Not rated differs from 0', () {
    expect(ratingText(null), 'Not rated');
    expect(ratingText(0), '★ 0.0');
    expect(ratingText(7), '★ 3.5');
    expect(ratingSpoken(10), 'Rated 5.0 out of 5');
  });

  test('amount is required only for Purchased', () {
    expect(checkAmount(Acquisition.purchased, null).isOk, isFalse);
    expect(checkAmount(Acquisition.purchased, 34900).valueOrNull, 34900);
    expect(checkAmount(Acquisition.free, 34900).valueOrNull, isNull);
  });

  test('file size', () {
    expect(parseSizeKb('').valueOrNull, isNull);
    expect(parseSizeKb('2,348').valueOrNull, 2348);
    expect(parseSizeKb('2.5').isOk, isFalse);
    expect(parseSizeKb('0').isOk, isFalse);
  });

  group('stats (F1-04 §6)', () {
    const books = [
      BookFacts(status: BookStatus.reading, acquisition: Acquisition.purchased, onKindle: true, sizeKb: 4300, amount: 59900),
      BookFacts(status: BookStatus.finished, acquisition: Acquisition.purchased, onKindle: true, sizeKb: 1946, amount: 34900, ratingHalf: 8),
      BookFacts(status: BookStatus.finished, acquisition: Acquisition.free, onKindle: true, ratingHalf: 9),
      BookFacts(status: BookStatus.abandoned, acquisition: Acquisition.other, ratingHalf: 0),
      BookFacts(status: BookStatus.notStarted, acquisition: Acquisition.purchased, amount: 45000),
    ];

    test('Kindle storage counts sizes of books on Kindle; missing sizes are noted', () {
      final s = libraryStats(books);
      expect(s.onKindle, 3);
      expect(s.kindleKb, 6246);
      expect(s.kindleNoSize, 1);
    });

    test('spent = purchased amounts; counts per status and acquisition', () {
      final s = libraryStats(books);
      expect(s.spent, 59900 + 34900 + 45000);
      expect(s.purchased, 3);
      expect(s.byStatus[BookStatus.finished], 2);
      expect(s.byAcquisition[Acquisition.free], 1);
    });

    test('average over rated books only; a 0 rating counts', () {
      final s = libraryStats(books);
      expect(s.rated, 3);
      expect(s.notRated, 2);
      expect(s.averageRating, '2.8'); // (4 + 4.5 + 0) / 3 = 2.833…
      expect(libraryStats(const []).averageRating, isNull);
    });
  });

  test('books per year: last 5 years by acquired date, status filter, no-date note', () {
    final books = [
      BookFacts(status: BookStatus.finished, acquisition: Acquisition.free, acquired: d('2026-02-01')),
      BookFacts(status: BookStatus.reading, acquisition: Acquisition.free, acquired: d('2026-09-18')),
      BookFacts(status: BookStatus.finished, acquisition: Acquisition.free, acquired: d('2022-05-05')),
      BookFacts(status: BookStatus.finished, acquisition: Acquisition.free, acquired: d('2019-05-05')),
      const BookFacts(status: BookStatus.finished, acquisition: Acquisition.free),
    ];
    final all = booksPerYear(books, d('2026-10-13'));
    expect(all.years.map((e) => e.$1), [2022, 2023, 2024, 2025, 2026]);
    expect(all.years.last.$2, 2);
    expect(all.years.first.$2, 1);
    expect(all.noDate, 1);
    final fin = booksPerYear(books, d('2026-10-13'), status: BookStatus.finished);
    expect(fin.years.last.$2, 1);
  });
}
