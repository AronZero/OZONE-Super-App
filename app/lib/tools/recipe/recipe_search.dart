import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/theme/oz_icons.dart';
import '../../shell/tool_registry.dart';
import 'domain/recipe.dart';
import 'state/recipe_providers.dart';

/// Recipes in global search (docs/spec/F4-01 §7).
const List<SearchSource> recipeSearch = [
  SearchSource(entity: 'recipe', group: 'Recipes', chip: 'Recipes', open: _open, describe: _recipe),
];

void _open(BuildContext context, WidgetRef ref, String id) => context.push('/recipe/$id');

SearchRowInfo? _recipe(BuildContext context, WidgetRef ref, String id) {
  final r = ref.watch(recipesDataProvider).value?.byId(id)?.row;
  if (r == null) return null;
  return SearchRowInfo([?r.category, ?durationText(r.prepMin, r.cookMin)].join(' · '));
}

/// Recipe's entry in Home's quick-add menu ("Scan a recipe" arrives with M12).
const List<QuickAddAction> recipeQuickAdd = [
  QuickAddAction(label: 'Add recipe', icon: OzIcons.cooking, run: _addRecipe),
];

void _addRecipe(BuildContext context) => context.push('/recipe/new');
