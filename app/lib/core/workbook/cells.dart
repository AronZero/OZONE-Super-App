import '../domain/dates.dart';
import '../domain/validation.dart';

/// Workbook cell rules (docs/spec/F1-02 §3), free of the xlsx library so they
/// can be tested on their own. A cell read from a file is one of:
/// `null` (empty), [String], [num], [bool], [LocalDate] or [DateTime].

/// Header matching: by name, ignoring case and spaces (F1-02 §2). `Folder †` → `folder`.
String headerKey(String header) => header.replaceAll('†', '').replaceAll(RegExp(r'\s+'), '').toLowerCase();

bool isBlank(Object? v) => v == null || (v is String && v.trim().isEmpty);

String? text(Object? v) {
  if (isBlank(v)) return null;
  if (v is double && v == v.roundToDouble()) return v.toInt().toString();
  return v.toString().trim();
}

/// Money: a number, or text like `1,234.56` / `₱1,234.56`. More than 2
/// decimals is an error, never rounded silently.
Validation<int> moneyCell(Object? v, {bool allowZero = false, required String what}) {
  if (isBlank(v)) return Invalid('$what is empty');
  String s;
  if (v is num) {
    // Doubles from spreadsheets carry float noise: keep up to 6 places, then insist on 2.
    s = v is int ? '$v' : v.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  } else {
    s = v.toString().trim().replaceAll(RegExp(r'[₱,\s]'), '');
  }
  final m = RegExp(r'^(-?\d+)(?:\.(\d+))?$').firstMatch(s);
  if (m == null) return Invalid('$what "${v.toString().trim()}" isn’t a number');
  final frac = m.group(2) ?? '';
  if (frac.length > 2) return Invalid('$what ${v.toString().trim()} has more than 2 decimals');
  final whole = int.parse(m.group(1)!);
  if (whole < 0) return Invalid('$what can’t be negative');
  if (m.group(1)!.length > 9) return Invalid('$what is more than ₱999,999,999.99');
  final value = whole * 100 + int.parse(frac.padRight(2, '0'));
  if (value == 0 && !allowZero) return Invalid('$what must be above ₱0.00');
  return Ok(value);
}

/// Grams with up to 3 decimals → milligrams; above 0.
Validation<int> gramsCell(Object? v) {
  if (isBlank(v)) return const Invalid('Grams is empty');
  final s = v is num ? (v is int ? '$v' : v.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')) : v.toString().trim();
  final m = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(s);
  if (m == null) return Invalid('Grams "${v.toString().trim()}" isn’t a number');
  final frac = m.group(2) ?? '';
  if (frac.length > 3) return Invalid('Grams ${v.toString().trim()} has more than 3 decimals');
  final mg = int.parse(m.group(1)!) * 1000 + int.parse(frac.padRight(3, '0'));
  if (mg <= 0) return const Invalid('Grams must be above 0');
  return Ok(mg);
}

/// A business date: a date cell, or text `YYYY-MM-DD`. Anything else (such as
/// the ambiguous `10/03/2026`) is an error. Future dates are refused.
Validation<LocalDate> dateCell(Object? v, {required String what, LocalDate? notAfter}) {
  if (isBlank(v)) return Invalid('$what is empty');
  LocalDate? d;
  if (v is LocalDate) {
    d = v;
  } else if (v is DateTime) {
    d = LocalDate(v.year, v.month, v.day);
  } else {
    final r = LocalDate.parseIso(v.toString().trim());
    if (r case Ok(:final value)) d = value;
  }
  if (d == null) return Invalid('$what "${v.toString().trim()}" isn’t a date like 2026-10-13');
  if (notAfter != null && d.isAfter(notAfter)) return Invalid('$what ${d.toIso()} is in the future');
  return Ok(d);
}

Validation<LocalDate?> optionalDateCell(Object? v, {required String what, LocalDate? notAfter}) =>
    isBlank(v) ? const Ok(null) : switch (dateCell(v, what: what, notAfter: notAfter)) { Ok(:final value) => Ok(value), Invalid(:final reason) => Invalid(reason) };

/// ISO 8601 UTC timestamp → epoch ms; empty → null ("unknown").
Validation<int?> timestampCell(Object? v, {required String what}) {
  if (isBlank(v)) return const Ok(null);
  if (v is DateTime) return Ok(v.toUtc().millisecondsSinceEpoch);
  final t = DateTime.tryParse(v.toString().trim());
  if (t == null) return Invalid('$what "${v.toString().trim()}" isn’t a time like 2026-10-14T09:41:00.000Z');
  return Ok(t.toUtc().millisecondsSinceEpoch);
}

String timestampText(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

/// Yes/No, TRUE/FALSE, 1/0 in any case; empty = No.
Validation<bool> yesNoCell(Object? v, {required String what}) {
  if (isBlank(v)) return const Ok(false);
  if (v is bool) return Ok(v);
  if (v is num) return v == 1 ? const Ok(true) : (v == 0 ? const Ok(false) : Invalid('$what "$v" isn’t Yes or No'));
  return switch (v.toString().trim().toLowerCase()) {
    'yes' || 'true' || '1' || 'y' => const Ok(true),
    'no' || 'false' || '0' || 'n' => const Ok(false),
    final s => Invalid('$what "$s" isn’t Yes or No'),
  };
}

String yesNo(bool b) => b ? 'Yes' : 'No';

/// Words as shown in the app, any case → the stored key.
Validation<String> wordCell(Object? v, Map<String, String> words, {required String what}) {
  if (isBlank(v)) return Invalid('$what is empty');
  final s = v.toString().trim().toLowerCase();
  for (final MapEntry(:key, :value) in words.entries) {
    if (value.toLowerCase() == s || key == s) return Ok(key);
  }
  return Invalid('$what "${v.toString().trim()}" isn’t one of ${words.values.join(', ')}');
}

/// Rating 0–5 in steps of 0.5 → half-stars 0–10; empty = not rated.
Validation<int?> ratingCell(Object? v) {
  if (isBlank(v)) return const Ok(null);
  final d = v is num ? v.toDouble() : double.tryParse(v.toString().trim());
  if (d == null || d < 0 || d > 5 || (d * 2) != (d * 2).roundToDouble()) return Invalid('Rating "$v" isn’t 0 to 5 in steps of 0.5');
  return Ok((d * 2).round());
}

/// Whole karat 1–24; `18K` text is accepted.
Validation<int> karatCell(Object? v) {
  if (isBlank(v)) return const Invalid('Karat is empty');
  final s = v is num ? (v == v.roundToDouble() ? v.toInt().toString() : '$v') : v.toString().trim().toLowerCase().replaceFirst(RegExp(r'k$'), '');
  final k = int.tryParse(s);
  if (k == null || k < 1 || k > 24) return Invalid('Karat "$v" isn’t a whole number from 1 to 24');
  return Ok(k);
}

/// `travel, 2026` or `#travel #2026` → tag names (not yet checked against the tag rules).
List<String> tagsCell(Object? v) => isBlank(v)
    ? const []
    : [for (final t in v.toString().split(RegExp(r'[,\s]+'))) if (t.replaceAll('#', '').isNotEmpty) t.replaceAll('#', '').trim()];

/// Splits long text into ≤ [max]-character parts, never inside a surrogate pair (F1-02 §4).
List<String> splitParts(String s, {int max = 30000}) {
  if (s.length <= max) return [s];
  final out = <String>[];
  var i = 0;
  while (i < s.length) {
    var end = i + max < s.length ? i + max : s.length;
    // Don't end on a high surrogate: the pair would be cut in two.
    if (end < s.length && s.codeUnitAt(end - 1) >= 0xD800 && s.codeUnitAt(end - 1) <= 0xDBFF) end--;
    out.add(s.substring(i, end));
    i = end;
  }
  return out;
}
