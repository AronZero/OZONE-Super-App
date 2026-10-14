import '../../../core/domain/dates.dart';
import '../../../core/domain/validation.dart';

// Field rules for savings accounts and balance updates (docs/spec/F1-01).

/// Account names: 1–80 characters after trimming.
Validation<String> validateAccountName(String input) {
  final s = input.trim();
  if (s.isEmpty) return const Invalid('Enter a name');
  if (s.length > 80) return const Invalid('Use 80 characters or fewer');
  return Ok(s);
}

/// Platform and type: optional, up to 80 characters. Empty is stored as null.
Validation<String?> validateOptionalShort(String input) {
  final s = input.trim();
  if (s.isEmpty) return const Ok(null);
  if (s.length > 80) return const Invalid('Use 80 characters or fewer');
  return Ok(s);
}

/// Remarks: optional, up to 1,000 characters. Empty is stored as null.
Validation<String?> validateRemarks(String input) {
  final s = input.trim();
  if (s.isEmpty) return const Ok(null);
  if (s.length > 1000) return const Invalid('Use 1,000 characters or fewer');
  return Ok(s);
}

/// Business dates can be in the past but never after today.
Validation<LocalDate> validateNotFuture(LocalDate d, LocalDate today) =>
    d.isAfter(today) ? const Invalid('Pick today or an earlier date') : Ok(d);

/// Two open accounts can't share a name, ignoring case (F1-01 decision 2).
/// [openNames] are the names of the other open accounts.
bool nameTaken(String name, Iterable<String> openNames) {
  final n = name.trim().toLowerCase();
  return openNames.any((o) => o.trim().toLowerCase() == n);
}

/// Two-letter tile initials, as on W1 · Savings: "Emergency Fund" → "EF";
/// a leading code like "MP2 Savings" → "MP"; one word → its first two letters.
String accountInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  final w0 = words.first;
  if (words.length == 1 || RegExp(r'^[A-Z0-9]{2,}$').hasMatch(w0)) {
    return w0.substring(0, w0.length.clamp(1, 2)).toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}
