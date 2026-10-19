import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/theme/oz_icons.dart';
import '../../core/ui/theme/tokens.dart';
import '../../shell/tool_registry.dart';
import 'recipe_search.dart';
import 'ui/recipe_detail_screen.dart';
import 'ui/recipe_form_screen.dart';
import 'ui/recipes_home.dart';

/// Recipe tool definition (M11, docs/spec/F4-02 §1). Not in the bar by default.
const ToolDefinition recipeTool = ToolDefinition(
  id: 'recipe',
  name: 'Recipes',
  tint: ToolTint.recipe,
  icon: OzIcons.cooking,
  routeBase: '/recipe',
  home: _home,
  routes: _routes,
  searchSources: recipeSearch,
  quickAdd: recipeQuickAdd,
);

Widget _home(BuildContext context) => const RecipesHome();

/// Detail and form open above the bar, like the other tools' records.
List<RouteBase> _routes(GlobalKey<NavigatorState> root) {
  GoRoute full(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, parentNavigatorKey: root, builder: (context, state) => build(state));
  return [
    full('new', (_) => const RecipeFormScreen()),
    full(':id', (s) => RecipeDetailScreen(recipeId: s.pathParameters['id']!)),
    full(':id/edit', (s) => RecipeFormScreen(recipeId: s.pathParameters['id']!)),
  ];
}
