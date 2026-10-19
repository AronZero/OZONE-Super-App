import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/providers.dart';
import '../data/recipes_repo.dart';

final recipesRepoProvider = Provider<RecipesRepo>(
    (ref) => RecipesRepo(ref.watch(databaseProvider), ref.watch(deletionsRepoProvider), ref.watch(photoStoreProvider)));

/// All recipes; screens rebuild whenever one changes.
final recipesDataProvider = StreamProvider<RecipesData>((ref) => ref.watch(recipesRepoProvider).watch());
