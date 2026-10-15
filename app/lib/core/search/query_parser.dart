/// Turns what's typed into an FTS5 query (docs/spec/F2-02 §1, docs/04 Search):
/// - nothing until 2 characters;
/// - every word is a prefix term and all must match (AND);
/// - case and accents are ignored by the index's tokenizer;
/// - a word that looks like an amount (`1299`, `1,299`, `1299.00`, `₱1,299`)
///   also matches that amount exactly, as centavos.
/// Only letters and digits reach the query, so typed quotes or operators can
/// never change its meaning.
String? buildMatch(String typed) {
  final q = typed.trim();
  if (q.runes.length < 2) return null;
  final terms = <String>[];
  for (final word in q.split(RegExp(r'\s+'))) {
    final tokens = [for (final t in word.split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))) if (t.isNotEmpty) t.toLowerCase()];
    if (tokens.isEmpty) continue;
    final phrase = '"${tokens.join(' ')}"*';
    final cents = amountCentavos(word);
    terms.add(cents == null ? phrase : '($phrase OR "$cents")');
  }
  if (terms.isEmpty) return null;
  return '{title body extra} : (${terms.join(' AND ')})';
}

/// `1,299.5` → 129950; null when the word isn't an amount.
int? amountCentavos(String word) {
  final w = word.replaceFirst('₱', '');
  final m = RegExp(r'^(\d{1,3}(?:,\d{3})+|\d+)(?:\.(\d{1,2}))?$').firstMatch(w);
  if (m == null) return null;
  final whole = m.group(1)!.replaceAll(',', '');
  if (whole.length > 9) return null;
  return int.parse(whole) * 100 + int.parse((m.group(2) ?? '').padRight(2, '0'));
}

/// Splits FTS5 `highlight()` output (matches wrapped in \u0001…\u0002) into
/// (text, isMatch) runs for drawing.
List<(String, bool)> highlightRuns(String marked) {
  final out = <(String, bool)>[];
  final buf = StringBuffer();
  var inMatch = false;
  for (final ch in marked.runes) {
    if (ch == 1 || ch == 2) {
      if (buf.isNotEmpty) out.add((buf.toString(), inMatch));
      buf.clear();
      inMatch = ch == 1;
    } else {
      buf.writeCharCode(ch);
    }
  }
  if (buf.isNotEmpty) out.add((buf.toString(), inMatch));
  return out;
}
