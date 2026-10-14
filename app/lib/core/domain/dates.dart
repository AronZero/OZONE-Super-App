import 'validation.dart';

/// A calendar date with no time and no time zone (docs/spec/F1-01 §1).
/// Stored as `YYYY-MM-DD`; "today" is the phone's local date.
class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day)
      : assert(month >= 1 && month <= 12),
        assert(day >= 1 && day <= daysInMonth(year, month));

  factory LocalDate.fromDateTime(DateTime t) => LocalDate(t.year, t.month, t.day);

  /// The phone's local date. Pass [now] in tests.
  factory LocalDate.today([DateTime? now]) => LocalDate.fromDateTime(now ?? DateTime.now());

  final int year;
  final int month;
  final int day;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _monthsLong = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static bool isLeapYear(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

  static int daysInMonth(int y, int m) =>
      const [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1] + (m == 2 && isLeapYear(y) ? 1 : 0);

  /// Parses `YYYY-MM-DD` strictly; anything else is invalid (F1-02 §3).
  static Validation<LocalDate> parseIso(String s) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s.trim());
    if (m == null) return Invalid('"$s" isn’t a date like 2026-10-13');
    final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), d = int.parse(m.group(3)!);
    if (mo < 1 || mo > 12 || d < 1 || d > daysInMonth(y, mo)) return Invalid('"$s" isn’t a real date');
    return Ok(LocalDate(y, mo, d));
  }

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  /// `13 Oct` within [today]'s year, otherwise `13 Oct 2025` (docs/05 formats).
  String format(LocalDate today) =>
      year == today.year ? '$day ${_months[month - 1]}' : '$day ${_months[month - 1]} $year';

  /// Always with the year: `13 Oct 2026`.
  String formatLong() => '$day ${_months[month - 1]} $year';

  String get monthShort => _months[month - 1];
  String get monthName => _monthsLong[month - 1];

  LocalDate get monthStart => LocalDate(year, month, 1);
  LocalDate get monthEnd => LocalDate(year, month, daysInMonth(year, month));

  /// Adds whole months, clamping the day (31 Jan + 1 month = 28/29 Feb).
  LocalDate addMonths(int n) {
    final total = year * 12 + (month - 1) + n;
    final y = total ~/ 12, m = total % 12 + 1;
    return LocalDate(y, m, day.clamp(1, daysInMonth(y, m)));
  }

  LocalDate addDays(int n) => LocalDate.fromDateTime(DateTime.utc(year, month, day + n));

  /// Whole days from this date to [other] (positive when [other] is later).
  int daysUntil(LocalDate other) =>
      DateTime.utc(other.year, other.month, other.day).difference(DateTime.utc(year, month, day)).inDays;

  bool isAfter(LocalDate o) => compareTo(o) > 0;
  bool isBefore(LocalDate o) => compareTo(o) < 0;

  @override
  int compareTo(LocalDate other) => toIso().compareTo(other.toIso());

  @override
  bool operator ==(Object other) =>
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
