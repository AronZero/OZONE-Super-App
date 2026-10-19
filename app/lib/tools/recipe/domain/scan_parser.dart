import 'amounts.dart';
import 'ingredient_words.dart';
import 'recipe.dart';
import 'units.dart';

// Sorting scanned text into a recipe (docs/spec/F4-02 §4). Rules only, no AI;
// pure Dart so it's tested with text fixtures.

/// One line of text the recognizer found, with its box in page pixels.
class ScanLine {
  const ScanLine(this.text, {required this.left, required this.top, required this.width, required this.height, this.confidence});

  final String text;
  final double left, top, width, height;

  /// 0–1 where the platform gives one (Android), else null.
  final double? confidence;
}

class ScanPage {
  const ScanPage({required this.width, required this.height, required this.lines});

  final double width, height;
  final List<ScanLine> lines;
}

/// The groups on Check what was read, in screen order.
enum ScanLabel { ingredient, step, note, unused }

/// A line on Check what was read. [lowConfidence] stays until the line is edited.
class ReadLine {
  const ReadLine(this.text, this.label, {this.lowConfidence = false});

  final String text;
  final ScanLabel label;
  final bool lowConfidence;

  ReadLine copyWith({String? text, ScanLabel? label, bool? lowConfidence}) =>
      ReadLine(text ?? this.text, label ?? this.label, lowConfidence: lowConfidence ?? this.lowConfidence);
}

class ScanResult {
  const ScanResult({required this.title, this.servings, this.prepMin, this.cookMin, required this.lines, required this.lineCount});

  final String title;
  final int? servings;
  final int? prepMin, cookMin;
  final List<ReadLine> lines;

  /// Lines the recognizer found, before headings and joins.
  final int lineCount;
}

const _headings = {
  ScanLabel.ingredient: {'ingredients', 'ingredient', 'you will need', 'what you need', 'mga sangkap', 'sangkap'},
  ScanLabel.step: {
    'method', 'directions', 'procedure', 'instructions', 'steps', 'preparation', 'how to cook', //
    'paraan ng pagluluto', 'paraan', 'pamamaraan',
  },
  ScanLabel.note: {'notes', 'note', 'tips', 'tip'},
};

ScanLabel? _heading(String text) {
  final t = text.toLowerCase().replaceAll(RegExp(r'\s*:\s*$'), '').trim();
  for (final MapEntry(key: label, value: words) in _headings.entries) {
    if (words.contains(t)) return label;
  }
  return null;
}

final _stepNumber = RegExp(r'^(?:step\s*\d+\s*[.:)\-–]?|\d{1,2}\s*[.)](?!\d))\s*', caseSensitive: false);
final _bullet = RegExp(r'^[•·▪●\-–*]\s*');
final _pageNumber = RegExp(r'^(?:p\.?\s*|page\s+)?\d{1,4}$', caseSensitive: false);

String _clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

int _words(String s) => s.split(' ').where((w) => w.isNotEmpty).length;

/// A section heading inside ingredients: "For the sauce:" (at most 5 words).
bool isSectionLine(String text) => text.endsWith(':') && _words(text) <= 5;

bool _startsWithUnit(String text) {
  final first = RegExp(r'^([A-Za-z]+\.?)(?=\s)').firstMatch(text);
  return first != null && Units.of(first[1]!) != null;
}

// Durations: "1 h 10 min", "1 hr", "45 mins", "1½ hours", "1.5 hours".
const _num = r'(\d+(?:[.,]\d+)?\s*[¼½¾]?|[¼½¾])';
final _duration = RegExp('$_num\\s*(?:h|hr|hrs|hour|hours)\\b(?:\\s*(?:and\\s*)?(\\d+)\\s*(?:m|min|mins|minute|minutes)\\b)?|(\\d+)\\s*(?:m|min|mins|minute|minutes)\\b', caseSensitive: false);

double _number(String s) {
  s = s.replaceAll(' ', '').replaceAll(',', '.');
  var extra = 0.0;
  for (final (f, v) in [('¼', .25), ('½', .5), ('¾', .75)]) {
    if (s.endsWith(f)) {
      extra = v;
      s = s.substring(0, s.length - 1);
    }
  }
  return (s.isEmpty ? 0 : double.parse(s)) + extra;
}

/// Minutes in the duration at the start of [text], or null.
int? durationMinutes(String text) {
  final m = _duration.matchAsPrefix(text.trimLeft());
  if (m == null) return null;
  if (m[3] != null) return int.parse(m[3]!);
  return (_number(m[1]!) * 60).round() + (m[2] == null ? 0 : int.parse(m[2]!));
}

final _servings = RegExp(r'\b(?:serves|servings|makes|yields?)\b\s*:?\s*(?:about\s+)?(\d{1,3})|(\d{1,3})\s*servings\b', caseSensitive: false);
final _timed = RegExp(r'\b(prep(?:aration)?|cook(?:ing)?|total)\b(?:\s*time)?\s*:?\s*', caseSensitive: false);

/// A details line starts with servings or a time ("Serves 4 · Prep 15 min").
final _detailStart = RegExp(r'^(?:serves|servings|makes|yields?|prep(?:aration)?|cook(?:ing)?|total)\b', caseSensitive: false);

/// Words that mix letters and digits (`1O`, `l5`), which OCR often makes.
/// Amounts with a unit stuck on (`500g`, `2tbsp`, `350°F`, `10x`) are fine.
String? _mixedWord(String text) {
  for (final raw in text.split(RegExp(r'\s+'))) {
    final w = raw.replaceAll(RegExp(r'^[(\["]+|[)\]",.;:!?]+$'), '');
    if (!RegExp(r'[0-9]').hasMatch(w) || !RegExp(r'[A-Za-z]').hasMatch(w)) continue;
    final unitStuck = RegExp(r'^\d+(?:[.,/]\d+)?(?:-\d+)?°?([A-Za-z]+)$').firstMatch(w);
    if (unitStuck != null) {
      final u = unitStuck[1]!;
      if (Units.of(u) != null || const {'f', 'c', 'x', 'cm', 'mm', 'in', 'inch', 'st', 'nd', 'rd', 'th', 's'}.contains(u.toLowerCase())) continue;
    }
    return w;
  }
  return null;
}

/// The amber Check reason for a line, or null (F4-02 §4 rule 9).
String? checkReason(ReadLine line, {Set<String> knownKeys = const {}}) {
  if (line.lowConfidence) return 'Check: hard to read';
  final mixed = _mixedWord(line.text);
  if (mixed != null) return 'Check: $mixed?';
  if (line.label == ScanLabel.ingredient && !isSectionLine(line.text)) {
    final key = ingredientFromLine(line.text).keyName;
    if (!isKnownKey(key, known: knownKeys)) return 'Check: $key?';
  }
  return null;
}

/// Lines of one page in reading order: two columns when the left edges fall
/// into two groups more than 30% of the page apart with 4+ lines each.
List<ScanLine> readingOrder(ScanPage page) {
  final lines = page.lines.where((l) => _clean(l.text).isNotEmpty).toList();
  // Lines whose middles are within half a line height are one row, read left to right.
  int byTop(ScanLine a, ScanLine b) {
    final h = a.height < b.height ? a.height : b.height;
    final mid = (a.top + a.height / 2) - (b.top + b.height / 2);
    return mid.abs() < h * 0.5 ? a.left.compareTo(b.left) : a.top.compareTo(b.top);
  }
  if (lines.length >= 8) {
    final lefts = lines.map((l) => l.left).toList()..sort();
    var gap = 0.0, split = 0.0;
    for (var i = 1; i < lefts.length; i++) {
      if (lefts[i] - lefts[i - 1] > gap) {
        gap = lefts[i] - lefts[i - 1];
        split = lefts[i];
      }
    }
    if (gap > page.width * 0.3) {
      final left = lines.where((l) => l.left < split).toList()..sort(byTop);
      final right = lines.where((l) => l.left >= split).toList()..sort(byTop);
      if (left.length >= 4 && right.length >= 4) return [..._joinRows(left), ..._joinRows(right)];
    }
  }
  return _joinRows(lines..sort(byTop));
}

/// Joins pieces of one printed line that the recognizer split ("1" and
/// "pack sinigang mix"): same height band, the second just right of the first.
List<ScanLine> _joinRows(List<ScanLine> lines) {
  final out = <ScanLine>[];
  for (final l in lines) {
    final prev = out.isEmpty ? null : out.last;
    if (prev != null) {
      final h = prev.height < l.height ? prev.height : l.height;
      final sameRow = ((prev.top + prev.height / 2) - (l.top + l.height / 2)).abs() < h * 0.5;
      final gap = l.left - (prev.left + prev.width);
      if (sameRow && gap > -h * 0.5 && gap < h * 2.5) {
        final top = prev.top < l.top ? prev.top : l.top;
        final bottom = [prev.top + prev.height, l.top + l.height].reduce((a, b) => a > b ? a : b);
        final c = [prev.confidence, l.confidence].whereType<double>();
        out[out.length - 1] = ScanLine('${prev.text} ${l.text}',
            left: prev.left,
            top: top,
            width: l.left + l.width - prev.left,
            height: bottom - top,
            confidence: c.isEmpty ? null : c.reduce((a, b) => a < b ? a : b));
        continue;
      }
    }
    out.add(l);
  }
  return out;
}

/// Sorts recognised [pages] into a title, details and labelled lines.
ScanResult parseScan(List<ScanPage> pages) {
  final ordered = [for (final p in pages) readingOrder(p)];
  final lineCount = ordered.fold(0, (n, p) => n + p.length);
  if (lineCount == 0) return const ScanResult(title: '', lines: [], lineCount: 0);

  // Title: the first tall line(s) in the top quarter of page 1, else the first line.
  final first = ordered.firstWhere((p) => p.isNotEmpty);
  final firstPage = pages[ordered.indexOf(first)];
  final heights = first.map((l) => l.height).toList()..sort();
  final median = heights[heights.length ~/ 2];
  bool tall(ScanLine l) => l.top < firstPage.height * 0.25 && l.height >= median * 1.3;
  final start = first.indexWhere(tall);
  final titleLines = <ScanLine>[
    if (start >= 0)
      for (var i = start; i < first.length && tall(first[i]); i++) first[i],
  ];
  if (titleLines.isEmpty) titleLines.add(first.first);
  final title = _clean(titleLines.map((l) => l.text).join(' '));

  int? servings, prep, cook, total;
  ScanLabel? section;
  final out = <ReadLine>[];

  for (final l in ordered.expand((p) => p)) {
    if (titleLines.contains(l)) continue;
    final raw = _clean(l.text);
    final low = (l.confidence ?? 1) < 0.6;

    final heading = _heading(raw);
    if (heading != null) {
      section = heading;
      continue;
    }

    // Details: servings and times go to Not used once read (not inside Steps).
    if (section != ScanLabel.step &&
        !_stepNumber.hasMatch(raw) &&
        _words(raw) <= 14 &&
        (_detailStart.hasMatch(raw) || _servings.hasMatch(raw))) {
      final s = _servings.firstMatch(raw);
      final timed = _timed.allMatches(raw).toList();
      var found = false;
      if (s != null) {
        final n = int.parse(s[1] ?? s[2]!);
        if (n >= 1 && n <= RecipeLimits.maxServings) {
          servings ??= n;
          found = true;
        }
      }
      for (var i = 0; i < timed.length; i++) {
        final end = i + 1 < timed.length ? timed[i + 1].start : raw.length;
        final mins = durationMinutes(raw.substring(timed[i].end, end));
        if (mins == null) continue;
        found = true;
        final kind = timed[i][1]!.toLowerCase();
        if (kind.startsWith('prep')) {
          prep ??= mins;
        } else if (kind.startsWith('cook')) {
          cook ??= mins;
        } else {
          total ??= mins;
        }
      }
      if (found) {
        out.add(ReadLine(raw, ScanLabel.unused, lowConfidence: low));
        continue;
      }
    }

    final numbered = _stepNumber.hasMatch(raw);
    var text = raw.replaceFirst(_bullet, '');
    if (raw.length <= 2 || _pageNumber.hasMatch(raw)) {
      out.add(ReadLine(raw, ScanLabel.unused, lowConfidence: low));
      continue;
    }

    final ScanLabel label;
    if (section != null) {
      label = section;
    } else if (numbered || (_words(text) >= 8 && text.endsWith('.'))) {
      label = ScanLabel.step;
    } else if (readAmount(text) != null || _startsWithUnit(text)) {
      label = ScanLabel.ingredient;
    } else {
      label = ScanLabel.unused;
    }
    if (label == ScanLabel.step) text = text.replaceFirst(_stepNumber, '');
    if (text.isEmpty) continue;

    // Joining: a run-on step or a wrapped ingredient continues the line before.
    final prev = out.isEmpty ? null : out.last;
    if (prev != null && prev.label == label) {
      final joinStep = label == ScanLabel.step && !numbered && !RegExp(r'[.!?]$').hasMatch(prev.text);
      final joinIngredient = label == ScanLabel.ingredient &&
          readAmount(text) == null &&
          !isSectionLine(prev.text) &&
          !isSectionLine(text) &&
          (prev.text.endsWith(',') || RegExp(r'^[a-z]').hasMatch(text));
      if (joinStep || joinIngredient) {
        out[out.length - 1] = prev.copyWith(text: '${prev.text} $text', lowConfidence: prev.lowConfidence || low);
        continue;
      }
    }
    out.add(ReadLine(text, label, lowConfidence: low));
  }

  if (prep == null && cook == null) cook = total;
  return ScanResult(title: title, servings: servings, prepMin: prep, cookMin: cook, lines: out, lineCount: lineCount);
}

/// An ingredient line as the form takes it: "2 cups of rice" → 2, cup, "rice".
IngredientInput ingredientFromLine(String text, {String? section}) {
  final p = readAmount(text);
  var name = p?.rest ?? text;
  String? unit = p?.unit;
  if (p == null && _startsWithUnit(text)) {
    final w = RegExp(r'^([A-Za-z]+\.?)\s+').firstMatch(text)!;
    unit = Units.of(w[1]!);
    name = text.substring(w[0]!.length);
  }
  name = name.replaceFirst(RegExp(r'^of\s+', caseSensitive: false), '').trim();
  if (name.isEmpty) name = text.trim();
  if (name.length > RecipeLimits.name) name = name.substring(0, RecipeLimits.name);
  return IngredientInput(section: section, amount: p?.amount, unit: unit, name: name, keyName: keyNameFor(name));
}

/// What "Continue to recipe" fills the form with.
class ScanDraft {
  const ScanDraft({required this.title, this.servings, this.prepMin, this.cookMin, required this.ingredients, required this.steps, this.notes});

  final String title;
  final int? servings, prepMin, cookMin;
  final List<IngredientInput> ingredients;
  final List<String> steps;
  final String? notes;
}

/// Builds the form draft from the checked lines: section lines head the
/// ingredients after them, Notes join into one text, Not used is dropped.
ScanDraft draftFromLines({required String title, int? servings, int? prepMin, int? cookMin, required List<ReadLine> lines}) {
  final ingredients = <IngredientInput>[];
  final steps = <String>[];
  final notes = <String>[];
  String? section;
  for (final l in lines) {
    final text = l.text.trim();
    if (text.isEmpty) continue;
    switch (l.label) {
      case ScanLabel.ingredient:
        if (isSectionLine(text)) {
          final s = text.substring(0, text.length - 1).trim();
          section = s.length > RecipeLimits.section ? s.substring(0, RecipeLimits.section) : s;
        } else if (ingredients.length < RecipeLimits.maxIngredients) {
          ingredients.add(ingredientFromLine(text, section: section));
        }
      case ScanLabel.step:
        if (steps.length < RecipeLimits.maxSteps) steps.add(text.length > RecipeLimits.step ? text.substring(0, RecipeLimits.step) : text);
      case ScanLabel.note:
        notes.add(text);
      case ScanLabel.unused:
        break;
    }
  }
  var note = notes.join('\n');
  if (note.length > RecipeLimits.notes) note = note.substring(0, RecipeLimits.notes);
  final t = title.trim();
  return ScanDraft(
    title: t.length > RecipeLimits.title ? t.substring(0, RecipeLimits.title) : t,
    servings: servings,
    prepMin: prepMin,
    cookMin: cookMin,
    ingredients: ingredients,
    steps: steps,
    notes: note.isEmpty ? null : note,
  );
}
