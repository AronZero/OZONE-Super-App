import 'package:intl/intl.dart';

import 'validation.dart';

/// Money is always whole centavos in an `int` (docs/spec/F1-01 §1, F1-04 §1).
/// ₱1,234.56 is 123456. Floating point is never used for amounts.
abstract final class Money {
  /// Largest amount the app accepts: ₱999,999,999.99.
  static const int max = 99999999999;

  static final NumberFormat _grouped = NumberFormat('#,##0', 'en_US');

  /// `₱1,234.56`; negative amounts use a true minus sign: `−₱1,234.56`.
  static String format(int centavos) {
    final sign = centavos < 0 ? '−' : '';
    final abs = centavos.abs();
    return '$sign₱${_grouped.format(abs ~/ 100)}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  /// Shown instead of an amount when "Hide amounts" is on.
  static const String hidden = '₱ ••••';

  /// Chart axes only: `₱1.28M`, `₱64.8k`, `₱950`.
  static String compact(int centavos) {
    final pesos = centavos / 100;
    final abs = pesos.abs();
    final sign = pesos < 0 ? '−' : '';
    if (abs >= 1000000) return '$sign₱${_trim((abs / 1000000).toStringAsFixed(2))}M';
    if (abs >= 1000) return '$sign₱${_trim((abs / 1000).toStringAsFixed(1))}k';
    return '$sign₱${abs.round()}';
  }

  /// A change with sign and arrow, never colour alone: `▲ +₱18,420.00`, `▼ −₱2,000.00`.
  static String change(int centavos) {
    if (centavos == 0) return 'No change';
    final body = format(centavos.abs());
    return centavos > 0 ? '▲ +$body' : '▼ −$body';
  }

  /// One-decimal percentage of [part] over [base]: `17.5%`; `—` when base is 0.
  static String percent(int part, int base) {
    if (base == 0) return '—';
    final p = mulDivRound(part, 1000, base) / 10;
    return '${p.toStringAsFixed(1)}%';
  }

  /// Screen-reader wording: "1,234 pesos and 56 centavos".
  static String spoken(int centavos) {
    final abs = centavos.abs();
    final pesos = abs ~/ 100;
    final cents = abs % 100;
    final minus = centavos < 0 ? 'minus ' : '';
    final p = '${_grouped.format(pesos)} ${pesos == 1 ? 'peso' : 'pesos'}';
    return cents == 0 ? '$minus$p' : '$minus$p and $cents ${cents == 1 ? 'centavo' : 'centavos'}';
  }

  /// Parses typed amounts (F1-04 §1): digits with an optional `.` and at most
  /// 2 decimals; commas, spaces and `₱` are ignored. Must be above 0 unless
  /// [allowZero] (balances may be ₱0.00; decision F1-1).
  static Validation<int> parse(String input, {bool allowZero = false}) {
    final s = input.replaceAll(RegExp(r'[₱,\s]'), '');
    if (s.isEmpty) return const Invalid('Enter an amount');
    final m = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(s);
    if (m == null) {
      if (RegExp(r'^\d+\.\d{3,}$').hasMatch(s)) {
        return const Invalid('Use at most 2 decimals, like 1,234.56');
      }
      return Invalid('"${input.trim()}" isn’t an amount. Use numbers like 1,234.56');
    }
    final whole = m.group(1)!;
    if (whole.length > 9) return const Invalid('That’s more than ₱999,999,999.99');
    final frac = (m.group(2) ?? '').padRight(2, '0');
    final value = int.parse(whole) * 100 + int.parse(frac);
    if (value > max) return const Invalid('That’s more than ₱999,999,999.99');
    if (value == 0 && !allowZero) return const Invalid('Enter an amount above ₱0.00');
    return Ok(value);
  }

  static String _trim(String n) => n.contains('.') ? n.replaceFirst(RegExp(r'\.?0+$'), '') : n;
}

/// Rounds half away from zero (F1-04 §1): 2.5 → 3, −2.5 → −3.
int roundHalfAwayFromZero(num x) => x < 0 ? -((-x) + 0.5).floor() : (x + 0.5).floor();

/// Exact integer `a × b ÷ d`, rounded half away from zero. Used where a
/// multiplication creates fractions of a centavo (gold value: mg × price ÷ 1000).
int mulDivRound(int a, int b, int d) {
  final n = BigInt.from(a) * BigInt.from(b);
  final den = BigInt.from(d);
  final q = n ~/ den;
  final r = n.remainder(den);
  final twice = r.abs() * BigInt.two;
  if (twice >= den.abs()) {
    return (q + ((n.isNegative != den.isNegative) ? -BigInt.one : BigInt.one)).toInt();
  }
  return q.toInt();
}
