import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/states.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/recipes_repo.dart';
import '../domain/amounts.dart';
import '../domain/recipe.dart';
import '../state/recipe_providers.dart';
import 'recipe_parts.dart';

/// Recipe detail (board R2): photo, favourite, servings scaling, Ingredients ·
/// Steps tabs; ingredients tick off while cooking (in memory only).
class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});
  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  int? _servings;
  int _tab = 0;
  final Set<int> _ticked = {};

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final async = ref.watch(recipesDataProvider);
    final data = async.value;
    final full = data?.byId(widget.recipeId);
    if (full == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(children: [
            const DetailTopBar(title: 'Recipe', overline: 'Recipes'),
            if (data != null)
              Padding(padding: const EdgeInsets.all(Space.xl), child: Text('This recipe no longer exists.', style: text.bodyLarge))
            else
              Expanded(
                child: async.hasError
                    ? LoadError(what: 'Recipe', error: async.error!, stack: async.stackTrace, onRetry: () => ref.invalidate(recipesDataProvider))
                    : const DelayedSkeleton(),
              ),
          ]),
        ),
      );
    }
    final r = full.row;
    final repo = ref.read(recipesRepoProvider);
    final servings = r.servings == null ? null : (_servings ?? r.servings!);
    final factor = r.servings == null ? 1.0 : servings! / r.servings!;

    Future<void> delete() async {
      final undo = ref.read(undoControllerProvider);
      Navigator.of(context).pop();
      final gone = await repo.delete(r.id);
      await undo.run(
        message: '${gone.row.title} deleted',
        hideNow: () {},
        commit: () => repo.recordDeleted(gone),
        restore: () => unawaited(repo.restore(gone)),
      );
    }

    Widget roundButton({required IconData icon, required String label, required VoidCallback onPressed, bool filled = false}) => Semantics(
          button: true,
          label: label,
          onTap: onPressed,
          excludeSemantics: true,
          child: Material(
            color: c.surface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(width: 48, height: 48, child: Center(child: FillIcon(icon, filled: filled, size: 22, color: filled ? recipeAccent(context) : c.ink))),
            ),
          ),
        );

    final chips = [
      ?r.category,
      if (r.prepMin != null) 'Prep ${minutesText(r.prepMin!)}',
      if (r.cookMin != null) 'Cook ${minutesText(r.cookMin!)}',
    ];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: Space.xxxl + MediaQuery.paddingOf(context).bottom),
        children: [
          Stack(children: [
            RecipePhoto(file: r.photoFile, height: 280 + MediaQuery.paddingOf(context).top, width: double.infinity, iconSize: 64),
            // A band behind the status bar keeps its clock and icons readable over any photo.
            if (r.photoFile != null)
              Positioned(top: 0, left: 0, right: 0, height: MediaQuery.paddingOf(context).top, child: const ColoredBox(color: Color(0x66000000))),
            Positioned(
              top: MediaQuery.paddingOf(context).top + Space.m,
              left: Space.m,
              right: Space.m,
              child: Row(children: [
                roundButton(icon: OzIcons.arrowBack, label: 'Back', onPressed: () => Navigator.of(context).maybePop()),
                const Spacer(),
                roundButton(
                  icon: OzIcons.favorite,
                  label: r.isFavourite ? 'Favourite, on' : 'Favourite, off',
                  filled: r.isFavourite,
                  onPressed: () {
                    Haptics.toggle();
                    repo.setFavourite(r.id, !r.isFavourite);
                  },
                ),
                const SizedBox(width: Space.s),
                roundButton(icon: OzIcons.edit, label: 'Edit recipe', onPressed: () => context.push('/recipe/${r.id}/edit')),
                const SizedBox(width: Space.s),
                Material(
                  color: c.surface,
                  shape: const CircleBorder(),
                  child: PopupMenuButton<int>(
                    tooltip: 'Recipe options',
                    icon: Icon(OzIcons.moreVert, color: c.ink),
                    color: c.surface,
                    onSelected: (_) => delete(),
                    itemBuilder: (_) => [PopupMenuItem(value: 0, child: Text('Delete', style: TextStyle(color: c.danger)))],
                  ),
                ),
              ]),
            ),
          ]),
          ...staggered([
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.screen, 18, Space.screen, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(header: true, child: Text(r.title, style: text.headlineMedium!.copyWith(height: 1.2))),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (var i = 0; i < chips.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: i == 0 && r.category != null ? recipeTile(context) : c.surfaceSunken,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(chips[i],
                            style: text.labelLarge!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: i == 0 && r.category != null ? recipeAccent(context) : c.ink,
                            )),
                      ),
                  ]),
                ],
                if (r.source != null) ...[
                  const SizedBox(height: 10),
                  Text('From: ${r.source}', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                ],
              ]),
            ),
            if (servings != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.screen, 14, Space.screen, 0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.s, Space.s),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Servings', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                        Text(servings == r.servings ? 'As written' : 'Amounts scaled from ${r.servings}',
                            style: text.labelLarge!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
                      ]),
                    ),
                    _Step(label: 'Fewer servings', icon: OzIcons.remove, onPressed: servings > 1 ? () => setState(() => _servings = servings - 1) : null),
                    Semantics(
                      liveRegion: true,
                      label: '$servings servings',
                      excludeSemantics: true,
                      child: SizedBox(
                        width: 44,
                        child: Text('$servings', textAlign: TextAlign.center, style: text.titleLarge!.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                    ),
                    _Step(
                      label: 'More servings',
                      icon: OzIcons.add,
                      onPressed: servings < RecipeLimits.maxServings ? () => setState(() => _servings = servings + 1) : null,
                    ),
                  ]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.screen, 14, Space.screen, 0),
              child: SegmentTabs(
                labels: ['Ingredients · ${full.ingredients.length}', 'Steps · ${full.steps.length}'],
                selected: _tab,
                onSelected: (i) => setState(() => _tab = i),
                pill: c.surface,
                pillText: recipeAccent(context),
                spokenSuffix: ' tab',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.screen, Space.m, Space.screen, 0),
              child: _tab == 0 ? _ingredients(context, full, factor) : _steps(context, full),
            ),
            if (r.notes != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.screen, Space.l, Space.screen, 0),
                child: Container(
                  padding: const EdgeInsets.all(Space.l),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Notes', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted)),
                    const SizedBox(height: Space.xs),
                    Text(r.notes!, style: text.bodyLarge!.copyWith(height: 1.5)),
                  ]),
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _ingredients(BuildContext context, RecipeFull full, double factor) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final rows = <Widget>[];
    String? section;
    for (var i = 0; i < full.ingredients.length; i++) {
      final ing = full.ingredients[i];
      if (ing.section != section) {
        section = ing.section;
        if (section != null) {
          rows.add(Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 2),
            child: Semantics(header: true, child: Text(section, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted))),
          ));
        }
      }
      final a = RecipeFull.amountOf(ing)?.scaled(factor);
      final amt = formatAmount(a, ing.unit);
      final done = _ticked.contains(i);
      void tick() {
        Haptics.toggle();
        setState(() => done ? _ticked.remove(i) : _ticked.add(i));
      }
      rows.add(Semantics(
        checked: done,
        label: '${spokenAmount(a, ing.unit)} ${ing.name}'.trim(),
        onTap: tick,
        excludeSemantics: true,
        child: InkWell(
          onTap: tick,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 6),
              child: Row(children: [
                AnimatedContainer(
                  duration: Motion.of(context).fill,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: done ? recipeAccent(context) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: done ? recipeAccent(context) : c.inkMuted, width: 2),
                  ),
                  child: done ? Icon(OzIcons.check, size: 16, color: c.onAccent) : null,
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  child: AnimatedOpacity(
                    duration: Motion.of(context).fill,
                    opacity: done ? 0.55 : 1,
                    child: Text.rich(
                      TextSpan(children: [
                        if (amt.isNotEmpty) TextSpan(text: '$amt ', style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
                        TextSpan(text: ing.name),
                      ]),
                      style: text.bodyLarge!.copyWith(height: 1.35, decoration: done ? TextDecoration.lineThrough : null),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ));
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }

  Widget _steps(BuildContext context, RecipeFull full) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    if (full.steps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Text('No steps yet. Edit the recipe to add how to cook it.', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
      );
    }
    return Column(children: [
      for (final s in full.steps)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.s),
          child: Semantics(
            label: 'Step ${s.position + 1}. ${s.body}',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.all(Space.l),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: recipeTile(context), shape: BoxShape.circle),
                  child: Text('${s.position + 1}', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: recipeAccent(context))),
                ),
                const SizedBox(width: Space.m),
                Expanded(child: Text(s.body, style: text.bodyLarge!.copyWith(height: 1.5))),
              ]),
            ),
          ),
        ),
    ]);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      style: IconButton.styleFrom(backgroundColor: c.surfaceSunken, disabledBackgroundColor: c.surfaceSunken, fixedSize: const Size(48, 48)),
      icon: Icon(icon, color: onPressed == null ? c.outline : c.ink),
    );
  }
}
