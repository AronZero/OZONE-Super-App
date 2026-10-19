import '../../../core/domain/validation.dart';
import 'units.dart';

/// Ingredient amounts (docs/spec/F4-01 §1, F4-02 §4 and §6). Stored in
/// thousandths so no floating point is used: ½ = 500, 1⅓ = 1333, 2 = 2000.
class Amount {
  const Amount(this.milli, [this.maxMilli]);

  final int milli;

  /// The top of a range ("2–3 cloves"), else null.
  final int? maxMilli;

  static const max = 99999000;

  /// Both ends multiplied by [factor], for servings scaling.
  Amount scaled(double factor) =>
      Amount((milli * factor).round(), maxMilli == null ? null : (maxMilli! * factor).round());

  @override
  bool operator ==(Object other) => other is Amount && other.milli == milli && other.maxMilli == maxMilli;

  @override
  int get hashCode => Object.hash(milli, maxMilli);

  @override
  String toString() => 'Amount($milli, $maxMilli)';
}

/// What the Amount field or the start of a scanned line holds.
class ParsedAmount {
  const ParsedAmount(this.amount, this.unit, this.rest);

  /// Null when there was no number ("salt to taste").
  final Amount? amount;
  final String? unit;

  /// The text after the amount and unit (the ingredient's name on a scanned line).
  final String rest;
}

const _fractions = {'¼': 250, '½': 500, '¾': 750, '⅓': 333, '⅔': 667, '⅛': 125, '⅜': 375, '⅝': 625, '⅞': 875};

const _frac = '[¼½¾⅓⅔⅛⅜⅝⅞]';

/// One number: `1 1/2`, `1/2`, `1½`, `1 ½`, `½`, `1.5`, `1,5`, `2`.
const _number = '(?:\\d+\\s+\\d+\\s*/\\s*\\d+|\\d+\\s*/\\s*\\d+|\\d+\\s*$_frac|$_frac|\\d+(?:[.,]\\d+)?)';

final RegExp _lead = RegExp('^\\s*($_number)(?:\\s*(?:-|–|—|to)\\s*($_number))?(?![\\d/])\\s*(.*)\$', caseSensitive: false);

/// Thousandths for one number token, or null if it isn't one.
int? _milli(String token) {
  final t = token.replaceAll(RegExp(r'\s+'), ' ').trim();
  final mixed = RegExp(r'^(\d+) (\d+) ?/ ?(\d+)$').firstMatch(t);
  if (mixed != null) {
    final d = int.parse(mixed[3]!);
    if (d == 0) return null;
    return int.parse(mixed[1]!) * 1000 + (int.parse(mixed[2]!) * 1000 / d).round();
  }
  final frac = RegExp(r'^(\d+) ?/ ?(\d+)$').firstMatch(t);
  if (frac != null) {
    final d = int.parse(frac[2]!);
    if (d == 0) return null;
    return (int.parse(frac[1]!) * 1000 / d).round();
  }
  final uni = RegExp('^(\\d*) ?($_frac)\$').firstMatch(t);
  if (uni != null) return (uni[1]!.isEmpty ? 0 : int.parse(uni[1]!) * 1000) + _fractions[uni[2]]!;
  final dec = RegExp(r'^(\d+)(?:[.,](\d+))?$').firstMatch(t);
  if (dec != null) {
    final whole = int.parse(dec[1]!);
    final part = dec[2];
    if (part == null) return whole * 1000;
    // "1,000" is a thousand; "1,5" and "1.5" are one and a half.
    if (t.contains(',') && part.length == 3) return (whole * 1000 + int.parse(part)) * 1000;
    return whole * 1000 + (double.parse('0.$part') * 1000).round();
  }
  return null;
}

/// Reads an amount, an optional unit and the rest from the start of [text].
/// Returns null when [text] doesn't start with a number.
ParsedAmount? readAmount(String text) {
  final m = _lead.firstMatch(text);
  if (m == null) return null;
  final lo = _milli(m[1]!);
  final hi = m[2] == null ? null : _milli(m[2]!);
  if (lo == null || (m[2] != null && hi == null)) return null;
  var rest = m[3]!.trim();
  String? unit;
  final word = RegExp(r'^([A-Za-z]+\.?)(?=\s|$)').firstMatch(rest);
  if (word != null) {
    unit = Units.of(word[1]!);
    if (unit != null) rest = rest.substring(word[1]!.length).trim();
  }
  return ParsedAmount(Amount(lo, hi), unit, rest);
}

/// The form's Amount field: empty, or a number or range with an optional unit
/// (`2`, `1.5`, `1,5`, `½`, `1 1/2`, `2-3`, `½ cup`, `8 cloves`).
Validation<(Amount?, String?)> parseAmountField(String input) {
  final s = input.trim();
  if (s.isEmpty) return const Ok((null, null));
  final p = readAmount(s);
  if (p == null) return const Invalid('Amount isn’t a number. Try 2, 1.5, ½ or 1 1/2.');
  final a = p.amount!;
  if (a.milli <= 0) return const Invalid('Amount must be more than 0');
  if (a.milli > Amount.max || (a.maxMilli ?? 0) > Amount.max) return const Invalid('Amount is too large');
  if (a.maxMilli != null && a.maxMilli! <= a.milli) return const Invalid('In a range, the second number must be larger');
  if (p.rest.isNotEmpty) {
    return Invalid('“${p.rest}” isn’t a unit. Put it in the ingredient’s name.');
  }
  return Ok((a, p.unit));
}

const _shownFractions = [(250, '¼'), (333, '⅓'), (500, '½'), (667, '⅔'), (750, '¾')];

/// One number as shown (F4-02 §6): whole numbers plain; else the nearest of
/// ¼ ⅓ ½ ⅔ ¾ when within 0.04 of it ("1 ½"); else one decimal under 10 and
/// whole numbers above. [wholeOnly] for g and ml.
String formatMilli(int milli, {bool wholeOnly = false}) {
  if (wholeOnly) return _group((milli / 1000).round());
  final whole = milli ~/ 1000, part = milli % 1000;
  if (part == 0) return _group(whole);
  if (part >= 960) return _group(whole + 1);
  if (part <= 40 && whole > 0) return _group(whole);
  for (final (v, f) in _shownFractions) {
    if ((part - v).abs() <= 40) return whole == 0 ? f : '${_group(whole)} $f';
  }
  if (milli < 10000) {
    final tenths = (milli / 100).round();
    return tenths % 10 == 0 ? _group(tenths ~/ 10) : '${tenths ~/ 10}.${tenths % 10}';
  }
  return _group((milli / 1000).round());
}

String _group(int n) {
  final s = '$n';
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// "½ cup", "2–3 cloves", "1 kg"; empty when there is no amount.
String formatAmount(Amount? a, String? unit) {
  if (a == null) return unit ?? '';
  final whole = Units.wholeOnly(unit);
  final n = a.maxMilli == null ? formatMilli(a.milli, wholeOnly: whole) : '${formatMilli(a.milli, wholeOnly: whole)}–${formatMilli(a.maxMilli!, wholeOnly: whole)}';
  if (unit == null) return n;
  return '$n ${Units.label(unit, milli: a.maxMilli ?? a.milli)}';
}

/// What the form's Amount field shows for a saved amount ("1 ½ cup" reads back the same).
String amountFieldText(Amount? a, String? unit) => formatAmount(a, unit);

const _spokenFractions = {'¼': 'a quarter', '⅓': 'a third', '½': 'a half', '⅔': 'two thirds', '¾': 'three quarters'};

/// TalkBack: "1 and a half cups", "half a cup" is read as "a half cup".
String spokenAmount(Amount? a, String? unit) {
  final shown = formatAmount(a, unit);
  return shown.replaceAllMapped(RegExp(r'(\d+) ([¼⅓½⅔¾])|([¼⅓½⅔¾])'), (m) {
    if (m[1] != null) return '${m[1]} and ${_spokenFractions[m[2]]}';
    return _spokenFractions[m[3]]!;
  }).replaceAll('–', ' to ');
}
