import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/tools/recipe/data/recipes_repo.dart';
import 'package:ozone/tools/recipe/domain/amounts.dart';
import 'package:ozone/tools/recipe/domain/cook.dart';
import 'package:ozone/tools/recipe/domain/recipe.dart';

import '../../helpers/harness.dart';
import 'recipe_flow_test.dart' show openRecipes, tapVisible;
import 'recipes_repo_test.dart' show adobo;

const _staples = {'salt', 'pepper', 'water', 'oil'};

/// Sample recipes (canvas board R6), labelled sample.
const _sample = [
  CookRecipe('a', 'Chicken adobo', ['chicken', 'soy sauce', 'vinegar', 'garlic', 'bay leaves', 'sugar', 'pepper']),
  CookRecipe('b', 'Garlic fried rice', ['rice', 'garlic', 'oil', 'salt']),
  CookRecipe('c', 'Tortang talong', ['eggplant', 'egg', 'garlic', 'onion']),
  CookRecipe('d', 'Banana bread', ['banana', 'flour', 'egg', 'sugar', 'butter']),
  CookRecipe('e', 'Boiled egg', ['egg', 'water', 'salt']),
];

RecipeInput _rice() => const RecipeInput(
      title: 'Garlic fried rice',
      servings: 2,
      cookMin: 15,
      ingredients: [
        IngredientInput(amount: Amount(3000), unit: 'cup', name: 'cooked rice', keyName: 'rice'),
        IngredientInput(amount: Amount(4000), unit: 'clove', name: 'garlic', keyName: 'garlic'),
        IngredientInput(name: 'salt', keyName: 'salt'),
      ],
    );

void main() {
  group('matchRecipes (F4-02 §5)', () {
    test('empty kitchen gives no groups, even for staples-only recipes (M13 Q2)', () {
      final r = matchRecipes(_sample, {}, _staples);
      expect(r.kitchenEmpty, isTrue);
      expect([...r.ready, ...r.missing, ...r.more], isEmpty);
    });

    test('groups by missing count; staples count as present', () {
      final r = matchRecipes(_sample, {'rice', 'garlic', 'egg', 'eggplant', 'chicken', 'soy sauce', 'vinegar'}, _staples);
      expect([for (final m in r.ready) m.title], ['Garlic fried rice', 'Boiled egg']);
      expect([for (final m in r.missing) m.title], ['Chicken adobo', 'Tortang talong']);
      expect(r.missing.first.missing, ['bay leaves', 'sugar']);
      expect(r.missing.last.missing, ['onion']);
      expect([for (final m in r.more) m.title], ['Banana bread']);
      expect(r.more.single.missing, ['banana', 'flour', 'sugar', 'butter']);
      // Uses lists what's present, staples included, in recipe order.
      expect(r.ready.firstWhere((m) => m.id == 'b').uses, ['rice', 'garlic', 'oil', 'salt']);
    });

    test('within a group: more ticked key names first, then title', () {
      final r = matchRecipes(_sample, {'egg', 'rice', 'garlic'}, _staples);
      // Fried rice uses 2 ticked, Boiled egg 1: rice first.
      expect([for (final m in r.ready) m.title], ['Garlic fried rice', 'Boiled egg']);
    });

    test('recipes with no ticked or staple key name stay out; duplicates count once', () {
      final r = matchRecipes(const [
        CookRecipe('x', 'Fruit salad', ['mango', 'banana']),
        CookRecipe('y', 'Mango shake', ['mango', 'mango', 'milk']),
      ], {'milk'}, const {});
      expect([for (final m in [...r.ready, ...r.missing, ...r.more]) m.id], ['y']);
      expect(r.missing.single.missing, ['mango']);
    });

    test('1,000 recipes group in under 50 ms', () {
      final many = [
        for (var i = 0; i < 1000; i++) CookRecipe('$i', 'Recipe $i', [for (var k = 0; k < 12; k++) 'ingredient ${(i * 7 + k * 13) % 300}']),
      ];
      final kitchen = {for (var k = 0; k < 120; k++) 'ingredient $k'};
      matchRecipes(many, kitchen, _staples); // warm up
      final sw = Stopwatch()..start();
      matchRecipes(many, kitchen, _staples);
      expect(sw.elapsedMilliseconds, lessThan(50));
    });

    test('kitchen choices: most used first, then A–Z, staples left out', () {
      expect(kitchenChoices(_sample, _staples).take(4), ['egg', 'garlic', 'sugar', 'banana']);
      expect(kitchenChoices(_sample, _staples), isNot(contains('salt')));
      expect(andList(['salt', 'pepper', 'water', 'oil']), 'salt, pepper, water and oil');
    });
  });

  test('kitchen: tick, untick, clear and restore', () async {
    final db = memoryDb();
    final repo = RecipesRepo(db, DeletionsRepo(db), testPhotos());
    final seen = <Set<String>>[];
    final sub = repo.watchKitchen().listen(seen.add);
    await repo.setHave('garlic', true);
    await repo.setHave('rice', true);
    await repo.setHave('garlic', false);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen.last, {'rice'});
    final gone = await repo.clearKitchen();
    await repo.restoreKitchen(gone);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen.last, {'rice'});
    await sub.cancel();
    await db.close();
  });

  testWidgets('ticking updates the groups and the Home widget at once', (tester) async {
    final db = memoryDb();
    await tester.runAsync(() async {
      final repo = RecipesRepo(db, DeletionsRepo(db), testPhotos());
      await repo.add(adobo());
      await repo.add(_rice());
      final s = SettingsRepo(db);
      final d = await s.get(SettingKeys.dashboardWidgets);
      await s.set(SettingKeys.dashboardWidgets, [const WidgetSetting('recipe_cook', true), for (final w in d) if (w.id != 'recipe_cook') WidgetSetting(w.id, false)]);
    });
    await pumpApp(tester, db: db);

    // Empty kitchen: the widget's one sentence and Pick ingredients.
    expect(find.text('What can I cook?'), findsOneWidget);
    expect(find.text('Pick ingredients'), findsOneWidget);
    await tester.tap(find.text('Pick ingredients'));
    await settle(tester);
    expect(find.text('In my kitchen'), findsOneWidget);
    expect(find.text('Tap the ingredients you have to see which recipes fit.'), findsOneWidget);
    // Staples aren't chips; the line names them.
    expect(find.text('salt'), findsNothing);
    expect(find.textContaining('Salt, pepper, water and oil count as always there.'), findsOneWidget);

    await tester.tap(find.text('rice'));
    await settle(tester);
    await tester.tap(find.text('garlic'));
    await settle(tester);
    expect(find.text('2 picked'), findsOneWidget);
    expect(find.textContaining('Ready to cook'), findsOneWidget);
    expect(find.text('Uses rice, garlic, salt'), findsOneWidget);

    await tester.tap(find.text('chicken'));
    await settle(tester);
    expect(find.textContaining('Missing 1–2'), findsOneWidget);
    expect(find.text('Missing: soy sauce, bay leaves'), findsOneWidget);

    // The search field narrows the chips.
    await tester.enterText(find.widgetWithText(TextField, 'Find an ingredient'), 'bay');
    await settle(tester);
    expect(find.text('soy sauce'), findsNothing);
    await tester.tap(find.text('bay leaves'));
    await settle(tester);
    expect(find.text('Missing: soy sauce'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.kitchen).get()).then((r) => r!.length), 4);

    // Home shows the same.
    await tester.tap(find.byTooltip('Back to Recipes'));
    await settle(tester);
    expect(find.text('1 ready'), findsOneWidget);
    expect(find.text('Ready · 15 min'), findsOneWidget);
    expect(find.text('Missing: soy sauce'), findsOneWidget);
    expect(find.text('From 4 ingredients in your kitchen'), findsOneWidget);

    // Clear with Undo.
    await tester.tap(find.text('Update ›'));
    await settle(tester);
    await tester.tap(find.text('Clear'));
    await settle(tester);
    expect(find.text('0 picked'), findsOneWidget);
    expect(find.text('Kitchen cleared'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('4 picked'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('Recipes card and Settings › Recipes staples', (tester) async {
    final db = memoryDb();
    await tester.runAsync(() => RecipesRepo(db, DeletionsRepo(db), testPhotos()).add(adobo()));
    await pumpApp(tester, db: db);
    await openRecipes(tester);
    expect(find.text('Pick what’s in your kitchen'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await settle(tester);

    // Ticking chicken and soy sauce leaves bay leaves missing…
    await tapVisible(tester, find.text('What can I cook?'));
    await tester.tap(find.text('chicken'));
    await settle(tester);
    await tester.tap(find.text('soy sauce'));
    await settle(tester);
    await tester.tap(find.byTooltip('Back to Recipes'));
    await settle(tester);
    expect(find.text('0 ready with what you have'), findsOneWidget);

    // …until bay leaves become an always-there ingredient.
    unawaited(GoRouter.of(tester.element(find.text('Recipes').first)).push('/settings'));
    await settle(tester);
    await tapVisible(tester, find.text('Always-there ingredients · kitchen'));
    expect(find.text('2 ingredients ticked on What can I cook?'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Add ingredient'), 'Black pepper');
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(find.text('“pepper” is already in the list'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Add ingredient'), 'Bay leaves');
    await tester.tap(find.text('Add'));
    await settle(tester);
    expect(await tester.runAsync(() => SettingsRepo(db).get(SettingKeys.recipeStaples)), ['salt', 'pepper', 'water', 'oil', 'bay leaves']);
    await tester.tap(find.bySemanticsLabel('Remove water'));
    await settle(tester);
    expect(await tester.runAsync(() => SettingsRepo(db).get(SettingKeys.recipeStaples)), ['salt', 'pepper', 'oil', 'bay leaves']);

    await tester.tap(find.text('Clear my kitchen'));
    await settle(tester);
    expect(find.text('Nothing is ticked'), findsOneWidget);
    await closeApp(tester, db);
  });
}
