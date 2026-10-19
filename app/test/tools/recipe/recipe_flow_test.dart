import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/photo_store.dart';
import 'package:ozone/tools/recipe/data/recipes_repo.dart';

import '../../helpers/harness.dart';
import 'recipes_repo_test.dart' show adobo;

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await settle(tester);
}

/// Recipes isn't in the bar by default: it opens from Tools (F4-02 §1).
Future<void> openRecipes(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('bar-Tools')));
  await settle(tester);
  await tapVisible(tester, find.text('Recipes').first);
}

void main() {
  testWidgets('empty Recipes → Add recipe → save → detail', (tester) async {
    final (db, _) = await pumpApp(tester);
    await openRecipes(tester);
    expect(find.text('No recipes yet'), findsOneWidget);
    // Opened from Tools, Recipes offers itself for the bar once (E4 rule).
    expect(find.text('Add Recipes to your bar?'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await settle(tester);
    expect(find.text('Add Recipes to your bar?'), findsNothing);
    await tester.tap(find.byTooltip('Add recipe'));
    await settle(tester);
    await tester.tap(find.text('Type it in'));
    await settle(tester);
    expect(find.text('New recipe'), findsOneWidget);

    // Save without a title or ingredient: reasons in words.
    await tapVisible(tester, find.text('Save recipe'));
    expect(find.text('Check the fields marked in red'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Add at least one ingredient'), 200, scrollable: find.byType(Scrollable).first);
    await tester.scrollUntilVisible(find.text('Give the recipe a title'), -200, scrollable: find.byType(Scrollable).first);

    await tester.enterText(find.byKey(const ValueKey('recipe-title')), 'Garlic fried rice');
    await tester.enterText(find.byKey(const ValueKey('recipe-servings')), '2');
    await tester.scrollUntilVisible(find.widgetWithText(TextField, 'Amount'), 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '3 cups');
    await tester.enterText(find.widgetWithText(TextField, 'Ingredient'), 'cooked rice, day-old');
    await settle(tester);
    expect(find.text('Matches as: rice'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Describe step 1'), 'Fry the garlic, then the rice.');
    await tapVisible(tester, find.text('Save recipe'));

    // The new recipe opens.
    expect(find.text('Garlic fried rice'), findsOneWidget);
    expect(find.text('As written'), findsOneWidget);
    expect(find.textContaining('cooked rice, day-old'), findsOneWidget);
    final saved = await tester.runAsync(() => db.select(db.recipeIngredients).getSingle());
    expect(saved!.amountMilli, 3000);
    expect(saved.unit, 'cup');
    expect(saved.keyName, 'rice');
    await closeApp(tester, db);
  });

  testWidgets('servings scale amounts; Steps tab; delete and Undo', (tester) async {
    final db = memoryDb();
    await tester.runAsync(() => RecipesRepo(db, DeletionsRepo(db), PhotoStore(() async => throw UnimplementedError(), (a, b, {required maxSide, required quality}) async {}))
        .add(adobo()));
    await pumpApp(tester, db: db);
    await openRecipes(tester);
    expect(find.text('1 h 10 min · 4 servings'), findsOneWidget);
    await tester.tap(find.text('Chicken adobo'));
    await settle(tester);

    expect(find.textContaining('½ cup'), findsOneWidget);
    await tester.tap(find.byTooltip('More servings'));
    await settle(tester);
    await tester.tap(find.byTooltip('More servings'));
    await settle(tester);
    expect(find.text('Amounts scaled from 4'), findsOneWidget);
    expect(find.textContaining('¾ cup'), findsOneWidget, reason: '½ cup × 6/4');
    expect(find.text('For the sauce'), findsOneWidget);

    await tester.tap(find.text('Steps · 2'));
    await settle(tester);
    expect(find.text('Simmer for 30 minutes.'), findsOneWidget);

    await tester.tap(find.byTooltip('Recipe options'));
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.text('Chicken adobo deleted'), findsOneWidget);
    expect(find.text('No recipes yet'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('Chicken adobo'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('TalkBack can activate the photo area, category pills and recipe cards', (tester) async {
    final handle = tester.ensureSemantics();
    final db = memoryDb();
    await tester.runAsync(() => RecipesRepo(db, DeletionsRepo(db), PhotoStore(() async => throw UnimplementedError(), (a, b, {required maxSide, required quality}) async {}))
        .add(adobo()));
    await pumpApp(tester, db: db);
    await openRecipes(tester);
    expect(tester.getSemantics(find.bySemanticsLabel(RegExp('^Chicken adobo'))), isSemantics(isButton: true, hasTapAction: true));
    expect(tester.getSemantics(find.bySemanticsLabel('Favourites')), isSemantics(hasTapAction: true));
    await tester.tap(find.byTooltip('Add recipe'));
    await settle(tester);
    await tester.tap(find.text('Type it in'));
    await settle(tester);
    expect(tester.getSemantics(find.bySemanticsLabel('Add photo')), isSemantics(isButton: true, hasTapAction: true));
    expect(tester.getSemantics(find.bySemanticsLabel('New category')), isSemantics(hasTapAction: true));
    handle.dispose();
    await closeApp(tester, db);
  });
}
