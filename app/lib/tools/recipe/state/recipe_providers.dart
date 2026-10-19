import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/state/providers.dart';
import '../data/recipes_repo.dart';
import '../domain/cook.dart';

final recipesRepoProvider = Provider<RecipesRepo>(
    (ref) => RecipesRepo(ref.watch(databaseProvider), ref.watch(deletionsRepoProvider), ref.watch(photoStoreProvider)));

/// All recipes; screens rebuild whenever one changes.
final recipesDataProvider = StreamProvider<RecipesData>((ref) => ref.watch(recipesRepoProvider).watch());

/// The ticked key names (table `kitchen`).
final kitchenProvider = StreamProvider<Set<String>>((ref) => ref.watch(recipesRepoProvider).watchKitchen());

/// Key names that always count as present (setting `recipe.staples`).
final staplesProvider = StreamProvider<List<String>>((ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.recipeStaples));

/// What can I cook? groups, recomputed in memory whenever recipes, the
/// kitchen or the staples change (F4-02 §5). Null until all three have loaded.
final cookResultProvider = Provider<CookResult?>((ref) {
  final data = ref.watch(recipesDataProvider).value;
  final kitchen = ref.watch(kitchenProvider).value;
  final staples = ref.watch(staplesProvider).value;
  if (data == null || kitchen == null || staples == null) return null;
  return matchRecipes(data.cookRecipes, kitchen, staples.toSet());
});
