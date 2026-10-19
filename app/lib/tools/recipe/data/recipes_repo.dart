import 'package:drift/drift.dart';

import '../../../core/data/database.dart';
import '../../../core/data/deletions_repo.dart';
import '../../../core/data/photo_store.dart';
import '../../../core/data/watch.dart';
import '../../../core/domain/ids.dart';
import '../domain/amounts.dart';
import '../domain/cook.dart';
import '../domain/recipe.dart';

const String recipeEntity = 'recipe';

/// One recipe with its ingredients and steps, in position order.
class RecipeFull {
  const RecipeFull(this.row, this.ingredients, this.steps);
  final RecipeRow row;
  final List<RecipeIngredientRow> ingredients;
  final List<RecipeStepRow> steps;

  String get id => row.id;

  static Amount? amountOf(RecipeIngredientRow i) => i.amountMilli == null ? null : Amount(i.amountMilli!, i.amountMaxMilli);

  /// The recipe as form input (also used to compare an edit with what's saved).
  RecipeInput toInput() => RecipeInput(
        title: row.title,
        category: row.category,
        servings: row.servings,
        prepMin: row.prepMin,
        cookMin: row.cookMin,
        source: row.source,
        notes: row.notes,
        isFavourite: row.isFavourite,
        photoFile: row.photoFile,
        ingredients: [
          for (final i in ingredients)
            IngredientInput(section: i.section, amount: amountOf(i), unit: i.unit, name: i.name, keyName: i.keyName),
        ],
        steps: [for (final s in steps) s.body],
      );
}

/// All recipes, loaded together (a phone holds hundreds, not thousands).
class RecipesData {
  RecipesData(this.recipes);
  final List<RecipeFull> recipes;

  late final Map<String, RecipeFull> _byId = {for (final r in recipes) r.id: r};

  RecipeFull? byId(String id) => _byId[id];

  /// Categories in use, most used first, then A–Z.
  late final List<String> categories = () {
    final n = <String, int>{};
    for (final r in recipes) {
      final c = r.row.category;
      if (c != null) n[c] = (n[c] ?? 0) + 1;
    }
    return n.keys.toList()..sort((a, b) => n[b]!.compareTo(n[a]!) != 0 ? n[b]!.compareTo(n[a]!) : a.toLowerCase().compareTo(b.toLowerCase()));
  }();

  /// Each recipe's key names, for What can I cook? (F4-02 §5).
  late final List<CookRecipe> cookRecipes = [
    for (final r in recipes) CookRecipe(r.id, r.row.title, [for (final i in r.ingredients) i.keyName]),
  ];

  /// Photo file names in use (for the orphan sweep).
  Set<String> get photos => {for (final r in recipes) ?r.row.photoFile};
}

/// The only code that reads and writes recipes (F3-01 §1).
class RecipesRepo {
  RecipesRepo(this._db, this._deletions, this._photos);

  final AppDatabase _db;
  final DeletionsRepo _deletions;
  final PhotoStore _photos;

  static int _now() => DateTime.now().toUtc().millisecondsSinceEpoch;

  PhotoStore get photos => _photos;

  Future<RecipesData> load() async {
    final rows = await _db.select(_db.recipes).get();
    final ings = await (_db.select(_db.recipeIngredients)..orderBy([(i) => OrderingTerm.asc(i.position)])).get();
    final steps = await (_db.select(_db.recipeSteps)..orderBy([(s) => OrderingTerm.asc(s.position)])).get();
    final ingBy = <String, List<RecipeIngredientRow>>{};
    for (final i in ings) {
      (ingBy[i.recipeId] ??= []).add(i);
    }
    final stepBy = <String, List<RecipeStepRow>>{};
    for (final s in steps) {
      (stepBy[s.recipeId] ??= []).add(s);
    }
    return RecipesData([for (final r in rows) RecipeFull(r, ingBy[r.id] ?? const [], stepBy[r.id] ?? const [])]);
  }

  Stream<RecipesData> watch() => watchTables(_db, [_db.recipes, _db.recipeIngredients, _db.recipeSteps], load);

  RecipesCompanion _fields(RecipeInput f) => RecipesCompanion(
        title: Value(f.title),
        category: Value(f.category),
        servings: Value(f.servings),
        prepMin: Value(f.prepMin),
        cookMin: Value(f.cookMin),
        source: Value(f.source),
        notes: Value(f.notes),
        isFavourite: Value(f.isFavourite),
        photoFile: Value(f.photoFile),
      );

  /// Children are deleted and written again after the recipe row, so the
  /// search triggers on them index the final state (F4-01 §1, §7).
  Future<void> _writeChildren(String id, RecipeInput f) async {
    await (_db.delete(_db.recipeIngredients)..where((i) => i.recipeId.equals(id))).go();
    await (_db.delete(_db.recipeSteps)..where((s) => s.recipeId.equals(id))).go();
    for (var p = 0; p < f.steps.length; p++) {
      await _db.into(_db.recipeSteps).insert(RecipeStepsCompanion.insert(recipeId: id, position: p, body: f.steps[p]));
    }
    // Ingredients last: a recipe always has one, so their triggers see the steps too.
    for (var p = 0; p < f.ingredients.length; p++) {
      final i = f.ingredients[p];
      await _db.into(_db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
            recipeId: id,
            position: p,
            section: Value(i.section),
            amountMilli: Value(i.amount?.milli),
            amountMaxMilli: Value(i.amount?.maxMilli),
            unit: Value(i.unit),
            name: i.name,
            keyName: i.keyName,
          ));
    }
  }

  Future<String> add(RecipeInput f) async {
    final id = newId();
    final now = _now();
    await _db.transaction(() async {
      await _db.into(_db.recipes).insert(_fields(f).copyWith(id: Value(id), createdAt: Value(now), updatedAt: Value(now)));
      await _writeChildren(id, f);
    });
    return id;
  }

  /// Saves the form; `updated_at` moves only on a real change (children included).
  /// A replaced photo's old file is deleted once the save is done.
  Future<void> edit(String id, RecipeInput f) async {
    final cur = (await load()).byId(id);
    if (cur == null) throw StateError('Recipe $id no longer exists');
    if (_same(cur.toInput(), f)) return;
    await _db.transaction(() async {
      await (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(_fields(f).copyWith(updatedAt: Value(_now())));
      await _writeChildren(id, f);
    });
    final old = cur.row.photoFile;
    if (old != null && old != f.photoFile) await _photos.delete(old);
  }

  static bool _same(RecipeInput a, RecipeInput b) {
    bool list<T>(List<T> x, List<T> y) {
      if (x.length != y.length) return false;
      for (var i = 0; i < x.length; i++) {
        if (x[i] != y[i]) return false;
      }
      return true;
    }

    return a.title == b.title &&
        a.category == b.category &&
        a.servings == b.servings &&
        a.prepMin == b.prepMin &&
        a.cookMin == b.cookMin &&
        a.source == b.source &&
        a.notes == b.notes &&
        a.isFavourite == b.isFavourite &&
        a.photoFile == b.photoFile &&
        list(a.ingredients, b.ingredients) &&
        list(a.steps, b.steps);
  }

  Future<void> setFavourite(String id, bool on) => (_db.update(_db.recipes)..where((r) => r.id.equals(id)))
      .write(RecipesCompanion(isFavourite: Value(on), updatedAt: Value(_now())));

  /// Deletes the recipe (its children go with it); the photo stays until the Undo expires.
  Future<RecipeFull> delete(String id) async {
    final full = (await load()).byId(id)!;
    await (_db.delete(_db.recipes)..where((r) => r.id.equals(id))).go();
    return full;
  }

  /// Undo: the recipe comes back exactly as it was.
  Future<void> restore(RecipeFull r) => _db.transaction(() async {
        await _db.into(_db.recipes).insertOnConflictUpdate(r.row);
        await (_db.delete(_db.recipeIngredients)..where((i) => i.recipeId.equals(r.id))).go();
        await (_db.delete(_db.recipeSteps)..where((s) => s.recipeId.equals(r.id))).go();
        for (final s in r.steps) {
          await _db.into(_db.recipeSteps).insert(s);
        }
        for (final i in r.ingredients) {
          await _db.into(_db.recipeIngredients).insert(i);
        }
      });

  /// After the Undo expires: the tombstone, then the photo file (F4-01 §8).
  Future<void> recordDeleted(RecipeFull r) async {
    await _deletions.record(recipeEntity, r.id);
    if (r.row.photoFile != null) await _photos.delete(r.row.photoFile!);
  }

  // Kitchen (F4-01 §1): a row means "I have it".

  Stream<Set<String>> watchKitchen() =>
      watchTables(_db, [_db.kitchen], () async => {for (final k in await _db.select(_db.kitchen).get()) k.keyName});

  /// Ticking writes at once (F4-02 §5).
  Future<void> setHave(String key, bool have) async {
    if (have) {
      await _db.into(_db.kitchen).insertOnConflictUpdate(KitchenCompanion.insert(keyName: key, updatedAt: _now()));
    } else {
      await (_db.delete(_db.kitchen)..where((k) => k.keyName.equals(key))).go();
    }
  }

  /// Empties the kitchen and returns what was there, for Undo.
  Future<List<KitchenRow>> clearKitchen() async {
    final rows = await _db.select(_db.kitchen).get();
    await _db.delete(_db.kitchen).go();
    return rows;
  }

  Future<void> restoreKitchen(List<KitchenRow> rows) => _db.batch((b) => b.insertAllOnConflictUpdate(_db.kitchen, rows));

  /// Orphan sweep on start and resume (F4-01 §3).
  Future<void> sweepPhotos() async => _photos.sweep((await load()).photos);
}
