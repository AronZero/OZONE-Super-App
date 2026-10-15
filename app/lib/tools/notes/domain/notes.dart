import '../../../core/domain/validation.dart';

export '../../../core/domain/delta.dart';

/// Notes rules that don't need the database or Flutter (F1-01 "Notes", F2-02).

/// Notes stay in the trash this long, then they are deleted (F2-02 §5).
const int trashDays = 30;

/// Title limit (F1-01: book and note titles 1–200 characters).
const int noteTitleMax = 200;

/// The note card preview: the text on one line, words separated by single spaces.
String previewOf(String? plain) => (plain ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();

/// A note with no title and no text (F2-02 §3: a new one is deleted silently).
bool isBlankNote(String? title, String? plain) => (title ?? '').trim().isEmpty && (plain ?? '').trim().isEmpty;

/// Days left in the trash: 30 − whole days since it was trashed, at least 1 (F2-02 §5).
int trashDaysLeft(int trashedAtMs, int nowMs) {
  final days = (nowMs - trashedAtMs) ~/ Duration.millisecondsPerDay;
  return (trashDays - days).clamp(1, trashDays);
}

/// Notes trashed before this moment are purged (F2-02 §5).
int purgeCutoff(int nowMs) => nowMs - trashDays * Duration.millisecondsPerDay;

/// A tag as typed (`#Travel`, ` trip-2026 `) → stored form (`travel`, `trip-2026`).
/// F1-01: lower case without `#`; letters, digits, `-` and `_`; 1–40 characters.
Validation<String> parseTag(String typed) {
  var s = typed.trim();
  while (s.startsWith('#')) {
    s = s.substring(1);
  }
  s = s.toLowerCase();
  if (s.isEmpty) return const Invalid('Type a tag name');
  if (s.length > 40) return const Invalid('Use 40 characters or fewer');
  if (!RegExp(r'^[\p{L}\p{N}_-]+$', unicode: true).hasMatch(s)) {
    return const Invalid('Use letters, numbers, - and _ only (no spaces)');
  }
  return Ok(s);
}

/// A folder name: trimmed, 1–80 characters, unique ignoring case among [others].
Validation<String> parseFolderName(String typed, Iterable<String> others) {
  final s = typed.trim();
  if (s.isEmpty) return const Invalid('Type a folder name');
  if (s.length > 80) return const Invalid('Use 80 characters or fewer');
  if (others.any((o) => o.toLowerCase() == s.toLowerCase())) return const Invalid('A folder with this name already exists');
  return Ok(s);
}

/// The title as stored: trimmed, at most 200 characters, null when empty.
String? normaliseTitle(String typed) {
  final s = typed.trim();
  if (s.isEmpty) return null;
  return s.length > noteTitleMax ? s.substring(0, noteTitleMax) : s;
}
