// Rich-text (Quill Delta JSON) rules shared by the note editor and the
// workbook import (docs/spec/F2-02 §2, F1-02 §4).

/// Text colours of the Components board, stored in the Delta as their light
/// value and drawn with the dark value in dark mode.
const List<(String, String, String)> textColours = [
  ('Violet', '#5B3E99', '#C2AEF0'),
  ('Blue', '#1F5A8F', '#9CC5F2'),
  ('Teal', '#16676A', '#86D4D2'),
  ('Red', '#A3361F', '#F59B85'),
  ('Amber', '#7E410B', '#F2C38B'),
];

/// Highlight colours of the Components board (light, dark).
const List<(String, String, String)> highlightColours = [
  ('Yellow', '#FFE98A', '#6B5A12'),
  ('Green', '#C7EBC9', '#24502C'),
  ('Blue', '#CFE3FA', '#1F3E63'),
  ('Pink', '#F8D3DE', '#5E2638'),
];

/// The dark-mode value of a stored palette colour (null if it isn't one).
String? darkColourOf(String stored) {
  final s = stored.toUpperCase();
  for (final (_, light, dark) in [...textColours, ...highlightColours]) {
    if (light == s) return dark;
  }
  return null;
}

final Set<String> _textHex = {for (final (_, l, _) in textColours) l};
final Set<String> _highlightHex = {for (final (_, l, _) in highlightColours) l};

/// Keeps only what the W1 toolbar can make (F2-02 §2): bold, italic, underline,
/// palette text colour and highlight; heading (one level) and the three list
/// kinds. Embeds (images and the like) and every other attribute are dropped,
/// so pasted content can't bring in links, fonts or sizes.
List<Map<String, Object?>> sanitizeDelta(List<Object?> ops) {
  final out = <Map<String, Object?>>[];
  for (final raw in ops) {
    if (raw is! Map) continue;
    final insert = raw['insert'];
    if (insert is! String || insert.isEmpty) continue;
    final attrs = raw['attributes'];
    final keep = <String, Object?>{};
    if (attrs is Map) {
      for (final MapEntry(:key, :value) in attrs.entries) {
        switch (key) {
          case 'bold' || 'italic' || 'underline' when value == true:
            keep[key as String] = true;
          case 'color' when value is String && _textHex.contains(value.toUpperCase()):
            keep['color'] = value.toUpperCase();
          case 'background' when value is String && _highlightHex.contains(value.toUpperCase()):
            keep['background'] = value.toUpperCase();
          case 'header' when value is int && value >= 1 && value <= 6:
            keep['header'] = 2;
          case 'list' when const ['bullet', 'ordered', 'checked', 'unchecked'].contains(value):
            keep['list'] = value;
        }
      }
    }
    final op = <String, Object?>{'insert': insert, if (keep.isNotEmpty) 'attributes': keep};
    // Join neighbours with the same attributes, as Quill does.
    final last = out.isEmpty ? null : out.last;
    if (last != null && _sameAttrs(last['attributes'], op['attributes'])) {
      out[out.length - 1] = {...last, 'insert': '${last['insert']}$insert'};
    } else {
      out.add(op);
    }
  }
  // A Quill document always ends with a newline.
  if (out.isEmpty || !(out.last['insert']! as String).endsWith('\n')) out.add({'insert': '\n'});
  return out;
}

bool _sameAttrs(Object? a, Object? b) {
  if (a == null || b == null) return a == b;
  final x = a as Map, y = b as Map;
  if (x.length != y.length) return false;
  for (final k in x.keys) {
    if (x[k] != y[k]) return false;
  }
  return true;
}

/// Plain text from a Delta (F2-02 §2): no formatting; checklist items become
/// "☐ item" / "☑ item". Trailing blank lines are dropped.
String plainTextFromDelta(List<Object?> ops) {
  final lines = <String>[];
  final line = StringBuffer();
  for (final raw in ops) {
    if (raw is! Map) continue;
    final insert = raw['insert'];
    if (insert is! String) continue;
    final attrs = raw['attributes'];
    final parts = insert.split('\n');
    for (var i = 0; i < parts.length; i++) {
      line.write(parts[i]);
      if (i < parts.length - 1) {
        // A newline ends the line; its attributes say what kind of line it was.
        final list = attrs is Map ? attrs['list'] : null;
        final prefix = list == 'checked' ? '☑ ' : (list == 'unchecked' ? '☐ ' : '');
        lines.add('$prefix$line');
        line.clear();
      }
    }
  }
  if (line.isNotEmpty) lines.add(line.toString());
  while (lines.isNotEmpty && lines.last.trim().isEmpty) {
    lines.removeLast();
  }
  return lines.join('\n');
}
