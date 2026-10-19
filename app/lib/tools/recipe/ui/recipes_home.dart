import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/states.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/shell_bar_scope.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/recipes_repo.dart';
import '../domain/recipe.dart';
import '../state/recipe_providers.dart';
import 'recipe_parts.dart';

/// Recipes list order (F4-02 §2, setting `recipe.list_sort`).
enum RecipeSort {
  recent('recent', 'Recently added'),
  title('title', 'Title A–Z'),
  favourites('favourites', 'Favourites first');

  const RecipeSort(this.key, this.label);
  final String key;
  final String label;

  static RecipeSort of(String key) => values.firstWhere((s) => s.key == key, orElse: () => recent);
}

final _recipeSortProvider = StreamProvider<String>((ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.recipeListSort));

/// Whether the one-time "Add it to your bar?" tip was answered.
final _barTipDoneProvider = StreamProvider<bool>((ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.recipeBarTipDone));

/// The filter chip: null = All, '\u0000fav' = Favourites, else a category.
const _favourites = '\u0000fav';

/// Recipes (board R1): category chips, a 2-column grid of cards, Add recipe.
class RecipesHome extends ConsumerStatefulWidget {
  const RecipesHome({super.key});

  @override
  ConsumerState<RecipesHome> createState() => _RecipesHomeState();
}

class _RecipesHomeState extends ConsumerState<RecipesHome> {
  String? _filter;

  static int _cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final async = ref.watch(recipesDataProvider);
    final data = async.value;
    final sort = RecipeSort.of(ref.watch(_recipeSortProvider).value ?? 'recent');
    final cats = data?.categories ?? const <String>[];
    // A category that no longer exists falls back to All.
    if (_filter != null && _filter != _favourites && !cats.contains(_filter)) _filter = null;
    final rows = [
      ...?data?.recipes.where((r) => _filter == null || (_filter == _favourites ? r.row.isFavourite : r.row.category == _filter)),
    ];
    switch (sort) {
      case RecipeSort.recent:
        rows.sort((a, b) => b.row.createdAt.compareTo(a.row.createdAt));
      case RecipeSort.title:
        rows.sort((a, b) => _cmp(a.row.title, b.row.title));
      case RecipeSort.favourites:
        rows.sort((a, b) => a.row.isFavourite != b.row.isFavourite ? (a.row.isFavourite ? -1 : 1) : _cmp(a.row.title, b.row.title));
    }
    final total = data?.recipes.length ?? 0;
    // E4 rule: a tool opened from Tools offers itself for the bar, once.
    final inBar = ref.watch(barToolsProvider).value?.contains('recipe') ?? true;
    final showTip = !inBar && ref.watch(_barTipDoneProvider).value == false;
    void tipDone() => ref.read(settingsRepoProvider).set(SettingKeys.recipeBarTipDone, true);

    final pairs = <Widget>[
      for (var i = 0; i < rows.length; i += 2)
        Padding(
          key: ValueKey('${rows[i].id}|${i + 1 < rows.length ? rows[i + 1].id : ''}'),
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: RecipeCard(recipe: rows[i])),
              const SizedBox(width: 10),
              Expanded(child: i + 1 < rows.length ? RecipeCard(recipe: rows[i + 1]) : const SizedBox.shrink()),
            ]),
          ),
        ),
    ];

    return Stack(children: [
      SafeArea(
        bottom: false,
        child: AnimatedRows(
          scope: (_filter, sort),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.screen, Space.xs),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Semantics(header: true, child: Text('Recipes', style: text.headlineMedium)),
                    if (total > 0) Text('$total ${total == 1 ? 'recipe' : 'recipes'}', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                  ]),
                ),
                RoundIconButton(icon: OzIcons.search, label: 'Search', onPressed: () => context.push('/search?scope=recipe')),
              ]),
            ),
            if (total > 0)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(Space.screen, Space.s, Space.screen, 6),
                child: RecipeChoice<String?>(
                  label: 'Filter by category',
                  wrap: false,
                  options: [(null, 'All'), (_favourites, 'Favourites'), for (final k in cats) (k, k)],
                  selected: _filter,
                  onSelected: (v) => setState(() => _filter = v),
                ),
              ),
            if (total > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.xl, 2, Space.s, 6),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      _filter == null ? 'All recipes · ${rows.length}' : '${_filter == _favourites ? 'Favourites' : _filter} · ${rows.length}',
                      style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted),
                    ),
                  ),
                  PopupMenuButton<RecipeSort>(
                    tooltip: 'Sort',
                    initialValue: sort,
                    color: c.surface,
                    onSelected: (s) => ref.read(settingsRepoProvider).set(SettingKeys.recipeListSort, s.key),
                    itemBuilder: (_) => [for (final s in RecipeSort.values) PopupMenuItem(value: s, child: Text(s.label))],
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: Space.s),
                      alignment: Alignment.center,
                      child: Text('${sort.label} ⇅', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
            for (final w in <Widget>[
              if (showTip)
                Container(
                  key: const ValueKey('bar-tip'),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(Space.l, 14, Space.s, Space.s),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Add Recipes to your bar?', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('It opens from Tools for now. Edit bar can put it next to Home.', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(onPressed: tipDone, child: Text('Not now', style: TextStyle(color: c.ink, fontWeight: FontWeight.w800))),
                      TextButton(
                        onPressed: () {
                          tipDone();
                          context.push('/edit-bar');
                        },
                        child: Text('Edit bar', style: TextStyle(color: recipeAccent(context), fontWeight: FontWeight.w800)),
                      ),
                    ]),
                  ]),
                ),
              if (data == null)
                async.hasError
                    ? LoadError(what: 'Recipes', error: async.error!, stack: async.stackTrace, onRetry: () => ref.invalidate(recipesDataProvider))
                    : const DelayedSkeleton()
              else if (total == 0)
                Container(
                  padding: const EdgeInsets.all(Space.xl),
                  decoration: BoxDecoration(color: recipeCard(context), borderRadius: BorderRadius.circular(Radii.card)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('No recipes yet', style: text.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: Space.xs),
                    Text('Write down a dish’s ingredients and how to cook it, with a photo of how it looks.',
                        style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                    const SizedBox(height: Space.m),
                    OzoneButton(label: 'Add recipe', color: recipeAccent(context), foreground: c.onAccent, onPressed: () => context.push('/recipe/new')),
                  ]),
                )
              else if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(Space.l),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_filter == _favourites ? 'No favourites yet' : 'No recipes match this filter', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: Space.xs),
                    Text(_filter == _favourites ? 'Tap the heart on a recipe to keep it here.' : 'Show all recipes to see the rest.',
                        style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                    const SizedBox(height: Space.m),
                    OzoneButton(label: 'Clear filter', primary: false, height: 48, onPressed: () => setState(() => _filter = null)),
                  ]),
                ),
              ...pairs,
            ])
              Padding(key: w.key, padding: const EdgeInsets.symmetric(horizontal: Space.screen), child: w),
          ],
          builder: (rows) => ListView(padding: EdgeInsets.only(bottom: shellListBottom(context)), children: staggered(rows)),
        ),
      ),
      ShellAddButtonSlot(
        child: ToolAddButton(label: 'Add recipe', accent: recipeAccent(context), onPressed: () => context.push('/recipe/new')),
      ),
    ]);
  }
}

/// One recipe in the grid: photo, title, "1 h 10 min · 4 servings".
class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe});
  final RecipeFull recipe;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final r = recipe.row;
    final meta = [?durationText(r.prepMin, r.cookMin), if (r.servings != null) '${r.servings} ${r.servings == 1 ? 'serving' : 'servings'}'].join(' · ');
    return Semantics(
      button: true,
      label: spokenAmounts([r.title, if (r.isFavourite) 'favourite', if (meta.isNotEmpty) meta].join(', ')),
      onTap: () => context.push('/recipe/${r.id}'),
      excludeSemantics: true,
      child: PressScale(
        scale: PressScale.card,
        child: Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/recipe/${r.id}'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Stack(children: [
                RecipePhoto(file: r.photoFile, height: 116, width: double.infinity),
                if (r.isFavourite)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
                      child: Icon(OzIcons.favorite, fill: 1, size: 16, color: recipeAccent(context)),
                    ),
                  ),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyLarge!.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.25)),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(meta, style: text.labelLarge!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
