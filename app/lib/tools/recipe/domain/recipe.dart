import '../../../core/domain/validation.dart';
import 'amounts.dart';

/// One ingredient line as the form and the workbook give it (F4-01 §1).
class IngredientInput {
  const IngredientInput({this.section, this.amount, this.unit, required this.name, required this.keyName});

  /// "For the sauce", or null.
  final String? section;
  final Amount? amount;
  final String? unit;
  final String name;
  final String keyName;

  @override
  bool operator ==(Object other) =>
      other is IngredientInput &&
      other.section == section &&
      other.amount == amount &&
      other.unit == unit &&
      other.name == name &&
      other.keyName == keyName;

  @override
  int get hashCode => Object.hash(section, amount, unit, name, keyName);
}

/// Everything the recipe form saves (F4-01 §1).
class RecipeInput {
  const RecipeInput({
    required this.title,
    this.category,
    this.servings,
    this.prepMin,
    this.cookMin,
    this.source,
    this.notes,
    this.isFavourite = false,
    this.photoFile,
    required this.ingredients,
    this.steps = const [],
  });

  final String title;
  final String? category;
  final int? servings;
  final int? prepMin;
  final int? cookMin;
  final String? source;
  final String? notes;
  final bool isFavourite;

  /// `<uuid>.jpg` in the photo folder, or null.
  final String? photoFile;
  final List<IngredientInput> ingredients;
  final List<String> steps;
}

/// Field limits (F4-01 §1).
abstract final class RecipeLimits {
  static const title = 200;
  static const category = 40;
  static const source = 200;
  static const notes = 2000;
  static const name = 200;
  static const section = 60;
  static const keyName = 80;
  static const step = 2000;
  static const maxIngredients = 100;
  static const maxSteps = 60;
  static const maxServings = 100;
  static const maxMinutes = 6000;
}

/// Trimmed text, null when empty, or a reason when longer than [max].
Validation<String?> optionalText(String input, int max) {
  final s = input.trim();
  if (s.length > max) return Invalid('Use ${_n(max)} characters or fewer');
  return Ok(s.isEmpty ? null : s);
}

Validation<String> requiredText(String input, int max, String empty) {
  final s = input.trim();
  if (s.isEmpty) return Invalid(empty);
  if (s.length > max) return Invalid('Use ${_n(max)} characters or fewer');
  return Ok(s);
}

/// Servings: empty, or a whole number from 1 to 100.
Validation<int?> parseServings(String input) {
  final s = input.trim();
  if (s.isEmpty) return const Ok(null);
  final n = int.tryParse(s);
  if (n == null || n < 1 || n > RecipeLimits.maxServings) return const Invalid('Servings is a whole number from 1 to 100');
  return Ok(n);
}

/// Prep or cook time in minutes: empty, or a whole number from 0 to 6,000.
Validation<int?> parseMinutes(String input) {
  final s = input.trim();
  if (s.isEmpty) return const Ok(null);
  final n = int.tryParse(s);
  if (n == null || n < 0 || n > RecipeLimits.maxMinutes) return const Invalid('Minutes is a whole number from 0 to 6,000');
  return Ok(n);
}

/// "1 h 10 min", "45 min", "2 h"; null when both are empty.
String? durationText(int? prepMin, int? cookMin) {
  if (prepMin == null && cookMin == null) return null;
  return minutesText((prepMin ?? 0) + (cookMin ?? 0));
}

String minutesText(int m) {
  final h = m ~/ 60, min = m % 60;
  if (h == 0) return '$min min';
  if (min == 0) return '$h h';
  return '$h h $min min';
}

String _n(int n) => n >= 1000 ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}' : '$n';
