import 'package:intl/intl.dart';

import 'validation.dart';

/// Weights are whole milligrams in an `int` (docs/spec/F1-01 §1): 82.400 g = 82400.
abstract final class Weight {
  /// 1,000 kg, far above any piece of jewellery; keeps typos out.
  static const int max = 1000000000;

  static final NumberFormat _grouped = NumberFormat('#,##0', 'en_US');

  /// `82.400 g` (always 3 decimals, docs/05 formats).
  static String format(int mg) => '${_grouped.format(mg ~/ 1000)}.${(mg % 1000).toString().padLeft(3, '0')} g';

  /// Parses typed grams: digits with an optional `.` and at most 3 decimals;
  /// commas, spaces and a trailing `g` are ignored. Must be above 0.
  static Validation<int> parse(String input) {
    final s = input.replaceAll(RegExp(r'[,\s]|g$', caseSensitive: false), '');
    if (s.isEmpty) return const Invalid('Enter the weight in grams');
    final m = RegExp(r'^(\d+)(?:\.(\d{0,3}))?$').firstMatch(s);
    if (m == null) {
      if (RegExp(r'^\d+\.\d{4,}$').hasMatch(s)) return const Invalid('Use at most 3 decimals, like 12.345');
      return Invalid('"${input.trim()}" isn’t a weight. Use grams like 12.345');
    }
    final whole = m.group(1)!;
    if (whole.length > 7) return const Invalid('That weight is too large');
    final value = int.parse(whole) * 1000 + int.parse((m.group(2) ?? '').padRight(3, '0'));
    if (value == 0) return const Invalid('Enter a weight above 0 g');
    if (value > max) return const Invalid('That weight is too large');
    return Ok(value);
  }

  /// Text to put back in an input field: `12.345`.
  static String plain(int mg) => format(mg).replaceAll(' g', '').replaceAll(',', '');
}
