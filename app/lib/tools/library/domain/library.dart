import '../../../core/domain/dates.dart';
import '../../../core/domain/validation.dart';

// Library rules and reports (docs/spec/F1-01 books, F1-04 §6). Pure Dart.

enum BookStatus {
  notStarted('not_started', 'Not started'),
  reading('reading', 'Reading'),
  finished('finished', 'Finished'),
  abandoned('abandoned', 'Abandoned');

  const BookStatus(this.key, this.label);

  /// Stored value. Never rename.
  final String key;
  final String label;

  static BookStatus of(String key) => values.firstWhere((s) => s.key == key, orElse: () => notStarted);
}

enum Acquisition {
  purchased('purchased', 'Purchased'),
  free('free', 'Free'),
  other('other', 'Other');

  const Acquisition(this.key, this.label);
  final String key;
  final String label;

  static Acquisition of(String key) => values.firstWhere((a) => a.key == key, orElse: () => other);
}

/// A book as the reports need it.
class BookFacts {
  const BookFacts({
    required this.status,
    required this.acquisition,
    this.onKindle = false,
    this.sizeKb,
    this.acquired,
    this.amount,
    this.ratingHalf,
  });

  final BookStatus status;
  final Acquisition acquisition;
  final bool onKindle;
  final int? sizeKb;
  final LocalDate? acquired;
  final int? amount;

  /// 0–10 half-stars; null = Not rated (different from 0 stars).
  final int? ratingHalf;
}

/// `842 KB` under 1,024 KB, `12.4 MB` under 1,024 MB, else `1.38 GB`. 1 MB = 1,024 KB.
String formatStorage(int kb) {
  if (kb < 1024) return '$kb KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb / 1024).toStringAsFixed(2)} GB';
}

/// `★ 3.5`, or `Not rated`. `★ 0.0` is a real rating of zero stars.
String ratingText(int? half) => half == null ? 'Not rated' : '★ ${(half / 2).toStringAsFixed(1)}';

/// Screen-reader wording: "Rated 3.5 out of 5" / "Not rated".
String ratingSpoken(int? half) => half == null ? 'Not rated' : 'Rated ${(half / 2).toStringAsFixed(1)} out of 5';

/// Amount is required for Purchased and must be empty otherwise (F1-01).
Validation<int?> checkAmount(Acquisition a, int? amount) {
  if (a == Acquisition.purchased) return amount == null ? const Invalid('Enter what you paid') : Ok(amount);
  return const Ok(null);
}

/// File size: optional whole KB, at least 1.
Validation<int?> parseSizeKb(String input) {
  final s = input.replaceAll(RegExp(r'[,\s]|kb$', caseSensitive: false), '');
  if (s.isEmpty) return const Ok(null);
  final n = int.tryParse(s);
  if (n == null || !RegExp(r'^\d+$').hasMatch(s)) return const Invalid('Enter the size in whole KB, like 2,348');
  if (n < 1) return const Invalid('Size is at least 1 KB');
  if (n > 100000000) return const Invalid('That size is too large');
  return Ok(n);
}

/// Library stats (W2 · Library stats).
class LibraryStats {
  const LibraryStats({
    required this.total,
    required this.kindleKb,
    required this.onKindle,
    required this.kindleNoSize,
    required this.spent,
    required this.purchased,
    required this.byStatus,
    required this.byAcquisition,
    required this.rated,
    required this.ratingSumHalf,
  });

  final int total;
  final int kindleKb;
  final int onKindle;

  /// Books on Kindle without a size (counted as 0): "3 books have no size".
  final int kindleNoSize;
  final int spent;
  final int purchased;
  final Map<BookStatus, int> byStatus;
  final Map<Acquisition, int> byAcquisition;
  final int rated;
  final int ratingSumHalf;

  int get notRated => total - rated;

  /// Mean of rating_half ÷ 2 over rated books, one decimal: "3.9"; null when none rated.
  String? get averageRating {
    if (rated == 0) return null;
    // Round half away from zero on tenths: sum/(2·rated) × 10.
    final tenths = ((ratingSumHalf * 10) / (2 * rated) + 0.5).floor();
    return (tenths / 10).toStringAsFixed(1);
  }
}

LibraryStats libraryStats(Iterable<BookFacts> books) {
  var total = 0, kb = 0, kindle = 0, noSize = 0, spent = 0, purchased = 0, rated = 0, sum = 0;
  final byStatus = {for (final s in BookStatus.values) s: 0};
  final byAcq = {for (final a in Acquisition.values) a: 0};
  for (final b in books) {
    total++;
    byStatus[b.status] = byStatus[b.status]! + 1;
    byAcq[b.acquisition] = byAcq[b.acquisition]! + 1;
    if (b.onKindle) {
      kindle++;
      if (b.sizeKb == null) {
        noSize++;
      } else {
        kb += b.sizeKb!;
      }
    }
    if (b.acquisition == Acquisition.purchased) {
      purchased++;
      spent += b.amount ?? 0;
    }
    if (b.ratingHalf != null) {
      rated++;
      sum += b.ratingHalf!;
    }
  }
  return LibraryStats(
    total: total,
    kindleKb: kb,
    onKindle: kindle,
    kindleNoSize: noSize,
    spent: spent,
    purchased: purchased,
    byStatus: byStatus,
    byAcquisition: byAcq,
    rated: rated,
    ratingSumHalf: sum,
  );
}

/// Books acquired per year for the last 5 years (by acquired date), with an
/// optional status filter; books with no date are counted separately.
({List<(int year, int count)> years, int noDate}) booksPerYear(Iterable<BookFacts> books, LocalDate today, {BookStatus? status}) {
  final counts = {for (var y = today.year - 4; y <= today.year; y++) y: 0};
  var noDate = 0;
  for (final b in books) {
    if (status != null && b.status != status) continue;
    final d = b.acquired;
    if (d == null) {
      noDate++;
    } else if (counts.containsKey(d.year)) {
      counts[d.year] = counts[d.year]! + 1;
    }
  }
  return (years: [for (final e in counts.entries) (e.key, e.value)], noDate: noDate);
}
