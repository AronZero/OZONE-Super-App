import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/photo_store.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/search/search_repo.dart';
import 'package:ozone/tools/recipe/data/recipes_repo.dart';
import 'package:ozone/tools/recipe/domain/amounts.dart';
import 'package:ozone/tools/recipe/domain/recipe.dart';

import '../../helpers/harness.dart';

/// Sample recipe (canvas board R2), labelled sample.
RecipeInput adobo({String? photo, List<String>? steps, String title = 'Chicken adobo'}) => RecipeInput(
      title: title,
      category: 'Mains',
      servings: 4,
      prepMin: 15,
      cookMin: 55,
      photoFile: photo,
      ingredients: const [
        IngredientInput(amount: Amount(1000), unit: 'kg', name: 'chicken thighs', keyName: 'chicken'),
        IngredientInput(amount: Amount(500), unit: 'cup', name: 'soy sauce', keyName: 'soy sauce'),
        IngredientInput(section: 'For the sauce', amount: Amount(3000), name: 'bay leaves', keyName: 'bay leaves'),
      ],
      steps: steps ?? const ['Marinate the chicken.', 'Simmer for 30 minutes.'],
    );

void main() {
  late AppDatabase db;
  late PhotoStore photos;
  late RecipesRepo repo;
  late Directory dir;

  setUp(() {
    db = memoryDb();
    dir = Directory.systemTemp.createTempSync('ozone_recipe');
    photos = PhotoStore(() async => dir, (from, to, {required maxSide, required quality}) async => File(from).copySync(to));
    repo = RecipesRepo(db, DeletionsRepo(db), photos);
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<String> photo() async {
    final src = File('${dir.path}/pick.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 1, 2, 3]);
    final name = await photos.adopt(src.path);
    src.deleteSync();
    return name;
  }

  test('add writes the recipe, ingredients and steps in order', () async {
    final id = await repo.add(adobo());
    final r = (await repo.load()).byId(id)!;
    expect(r.row.title, 'Chicken adobo');
    expect([for (final i in r.ingredients) i.name], ['chicken thighs', 'soy sauce', 'bay leaves']);
    expect(r.ingredients[2].section, 'For the sauce');
    expect(r.ingredients[1].amountMilli, 500);
    expect([for (final s in r.steps) s.body], ['Marinate the chicken.', 'Simmer for 30 minutes.']);
  });

  test('edit replaces children; updated_at moves only on a real change', () async {
    final id = await repo.add(adobo());
    final before = (await repo.load()).byId(id)!.row.updatedAt;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.edit(id, adobo());
    expect((await repo.load()).byId(id)!.row.updatedAt, before, reason: 'nothing changed');
    await repo.edit(id, adobo(steps: const ['Just one step.']));
    final r = (await repo.load()).byId(id)!;
    expect(r.row.updatedAt, greaterThan(before));
    expect([for (final s in r.steps) s.body], ['Just one step.']);
  });

  test('search finds a recipe by an ingredient, a step and its title, and forgets it when deleted', () async {
    final search = SearchRepo(db, SettingsRepo(db));
    final id = await repo.add(adobo());
    expect((await search.search('soy')).single.hits.single.recordId, id);
    expect((await search.search('marinate')).single.hits.single.recordId, id);
    expect((await search.search('adobo')).single.entity, 'recipe');
    await repo.edit(id, adobo(steps: const ['Braise slowly.']));
    expect(await search.search('marinate'), isEmpty);
    expect((await search.search('braise')).single.hits.single.recordId, id);
    await repo.delete(id);
    expect(await search.search('adobo'), isEmpty);
  });

  test('a replaced photo is deleted when the recipe saves', () async {
    final first = await photo();
    final id = await repo.add(adobo(photo: first));
    final second = await photo();
    await repo.edit(id, adobo(photo: second));
    expect(await photos.has(first), isFalse);
    expect(await photos.has(second), isTrue);
  });

  test('delete + Undo restores everything; after Undo expires: tombstone and photo gone', () async {
    final p = await photo();
    final id = await repo.add(adobo(photo: p));
    final gone = await repo.delete(id);
    expect((await repo.load()).byId(id), isNull);
    expect(await db.select(db.recipeIngredients).get(), isEmpty, reason: 'children go with the recipe');
    await repo.restore(gone);
    final back = (await repo.load()).byId(id)!;
    expect(back.ingredients.length, 3);
    expect(back.steps.length, 2);
    expect(await photos.has(p), isTrue);

    final again = await repo.delete(id);
    await repo.recordDeleted(again);
    expect(await DeletionsRepo(db).isDeleted(recipeEntity, id), isTrue);
    expect(await photos.has(p), isFalse);
  });

  test('the orphan sweep keeps photos in use and young ones', () async {
    final used = await photo();
    await repo.add(adobo(photo: used));
    final young = await photo();
    final old = await photo();
    (await photos.file(old)).setLastModifiedSync(DateTime.now().subtract(const Duration(minutes: 11)));
    (await photos.file(used)).setLastModifiedSync(DateTime.now().subtract(const Duration(minutes: 11)));
    await repo.sweepPhotos();
    expect(await photos.has(used), isTrue);
    expect(await photos.has(young), isTrue, reason: 'a form may still be open');
    expect(await photos.has(old), isFalse);
  });

  test('categories: most used first', () async {
    await repo.add(adobo());
    await repo.add(adobo(title: 'Tortang talong'));
    await repo.add(RecipeInput(title: 'Banana bread', category: 'Baking', ingredients: adobo().ingredients));
    expect((await repo.load()).categories, ['Mains', 'Baking']);
  });
}
