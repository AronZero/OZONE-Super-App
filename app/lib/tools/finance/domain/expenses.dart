import '../../../core/domain/dates.dart';

// Expense totals (docs/spec/F1-04 §5). Refunded expenses are left out of
// every total, count and chart, but stay listed.

class Spend {
  const Spend({required this.id, required this.item, required this.vendor, required this.amount, required this.date, this.refunded = false});
  final String id;
  final String item;
  final String vendor;
  final int amount;
  final LocalDate date;
  final bool refunded;
}

int _sum(Iterable<Spend> xs, bool Function(LocalDate d) keep) =>
    xs.where((e) => !e.refunded && keep(e.date)).fold(0, (a, e) => a + e.amount);

/// The same month and day last year; 29 Feb becomes 28 Feb.
LocalDate sameDayLastYear(LocalDate d) =>
    LocalDate(d.year - 1, d.month, d.day.clamp(1, LocalDate.daysInMonth(d.year - 1, d.month)));

/// This year so far vs the same period last year (1 Jan to the same day).
class YearToDate {
  const YearToDate(this.thisYear, this.lastYear, this.lastYearEnd);
  final int thisYear;
  final int lastYear;
  final LocalDate lastYearEnd;

  /// (this − last) ÷ last, as tenths of a percent; null when last is 0.
  int? get changeTenths => lastYear == 0 ? null : (((thisYear - lastYear) * 1000) / lastYear).round();
}

/// For a past [year] the whole year is compared with the whole year before.
YearToDate yearToDate(Iterable<Spend> xs, int year, LocalDate today) {
  final end = year == today.year ? today : LocalDate(year, 12, 31);
  final lastEnd = sameDayLastYear(end);
  final start = LocalDate(year, 1, 1), lastStart = LocalDate(year - 1, 1, 1);
  return YearToDate(
    _sum(xs, (d) => !d.isBefore(start) && !d.isAfter(end)),
    _sum(xs, (d) => !d.isBefore(lastStart) && !d.isAfter(lastEnd)),
    lastEnd,
  );
}

/// One bar in Spending by year.
class YearSpend {
  const YearSpend(this.year, this.total, {this.soFar = false});
  final int year;
  final int total;

  /// The current year, which is still running.
  final bool soFar;
}

/// The current year and the 4 before it. A year with no expenses is ₱0.00,
/// but years before the first expense ever are not shown.
List<YearSpend> spendingByYear(Iterable<Spend> xs, LocalDate today) {
  final counted = xs.where((e) => !e.refunded);
  if (counted.isEmpty) return const [];
  final first = counted.map((e) => e.date.year).reduce((a, b) => a < b ? a : b);
  return [
    for (var y = today.year - 4; y <= today.year; y++)
      if (y >= first) YearSpend(y, _sum(counted, (d) => d.year == y), soFar: y == today.year),
  ];
}

/// Totals for the 12 months of [year] (index 0 = January). Future months are null.
List<int?> monthlyTotals(Iterable<Spend> xs, int year, LocalDate today) => [
      for (var m = 1; m <= 12; m++)
        LocalDate(year, m, 1).isAfter(today) ? null : _sum(xs, (d) => d.year == year && d.month == m),
    ];

/// Possible duplicates of a new expense: same vendor (ignoring case) and amount
/// within ±3 days (decision M3-2). [exceptId] skips the expense being edited.
List<Spend> possibleDuplicates(Iterable<Spend> xs, {required String vendor, required int amount, required LocalDate date, String? exceptId}) {
  final v = vendor.trim().toLowerCase();
  return [
    for (final e in xs)
      if (e.id != exceptId && e.amount == amount && e.vendor.trim().toLowerCase() == v && e.date.daysUntil(date).abs() <= 3) e,
  ];
}

/// "12.5%" from tenths of a percent, with sign: "−9.1%".
String percentTenths(int tenths) {
  final s = (tenths.abs() / 10).toStringAsFixed(1);
  return tenths < 0 ? '−$s%' : (tenths > 0 ? '+$s%' : '0.0%');
}
