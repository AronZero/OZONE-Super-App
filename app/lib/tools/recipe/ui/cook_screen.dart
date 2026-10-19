import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/providers.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/states.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/cook.dart';
import '../state/recipe_providers.dart';
import 'recipe_parts.dart';

/// Empties the kitchen with "Kitchen cleared · Undo" (F4-02 §5).
Future<void> clearKitchen(WidgetRef ref) async {
  final repo = ref.read(recipesRepoProvider);
  final undo = ref.read(undoControllerProvider);
  final rows = await repo.clearKitchen();
  if (rows.isEmpty) return;
  await undo.run(
    message: 'Kitchen cleared',
    hideNow: () {},
    commit: () async {},
    restore: () => unawaited(repo.restoreKitchen(rows)),
  );
}

/// What can I cook? (board R6): tick what's in the kitchen, see which recipes fit.
class CookScreen extends ConsumerStatefulWidget {
  const CookScreen({super.key});

  @override
  ConsumerState<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends ConsumerState<CookScreen> {
  final _find = TextEditingController();
  bool _moreOpen = false;

  @override
  void initState() {
    super.initState();
    _find.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _find.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final async = ref.watch(recipesDataProvider);
    final data = async.value;
    final staples = ref.watch(staplesProvider).value ?? const <String>[];
    final kitchen = ref.watch(kitchenProvider).value ?? const <String>{};
    final result = ref.watch(cookResultProvider);
    final repo = ref.read(recipesRepoProvider);

    // Ticked first (also ticked ones no recipe uses any more, so they can be unticked), then the rest.
    final choices = data == null ? const <String>[] : kitchenChoices(data.cookRecipes, staples.toSet());
    final q = _find.text.trim().toLowerCase();
    final chips = [
      ...[...kitchen]..sort(),
      for (final k in choices)
        if (!kitchen.contains(k)) k,
    ].where((k) => q.isEmpty || k.contains(q)).toList();

    Widget group(String label, List<CookMatch> items) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xs, Space.l, Space.xs, Space.s),
            child: Semantics(
              header: true,
              container: true,
              child: Text.rich(TextSpan(children: [
                TextSpan(text: label, style: text.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                TextSpan(text: ' · ${items.length}', style: text.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: c.inkMuted)),
              ])),
            ),
          ),
          for (final m in items) ...[
            CookRow(match: m, photoFile: data?.byId(m.id)?.row.photoFile, background: c.surface),
            const SizedBox(height: Space.s),
          ],
        ]);

    final staplesLine = staples.isEmpty ? '' : ' ${_cap(andList(staples))} ${staples.length == 1 ? 'counts' : 'count'} as always there.';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: staggered([
            DetailTopBar(
              title: 'What can I cook?',
              overline: 'Recipes',
              trailing: [
                if (kitchen.isNotEmpty)
                  TextButton(
                    onPressed: () => clearKitchen(ref),
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    child: Text('Clear', style: TextStyle(color: recipeAccent(context), fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Expanded(child: Semantics(header: true, child: Text('In my kitchen', style: text.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w800)))),
                    Text('${kitchen.length} picked', style: text.labelLarge!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
                  ]),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _find,
                    textInputAction: TextInputAction.search,
                    style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
                    cursorColor: c.ink,
                    decoration: InputDecoration(
                      hintText: 'Find an ingredient',
                      filled: true,
                      fillColor: c.surfaceSunken,
                      prefixIcon: Icon(OzIcons.search, color: c.inkMuted),
                      suffixIcon: _find.text.isEmpty
                          ? null
                          : IconButton(tooltip: 'Clear search', onPressed: _find.clear, icon: Icon(OzIcons.close, color: c.inkMuted)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.ink, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (data == null)
                    async.hasError
                        ? LoadError(what: 'Recipes', error: async.error!, stack: async.stackTrace, onRetry: () => ref.invalidate(recipesDataProvider))
                        : const DelayedSkeleton()
                  else if (choices.isEmpty && kitchen.isEmpty)
                    Text('Ingredients from your recipes show here once you add a recipe.', style: text.bodyMedium!.copyWith(color: c.inkMuted))
                  else if (chips.isEmpty)
                    Text('No ingredient matches “${_find.text.trim()}”.', style: text.bodyMedium!.copyWith(color: c.inkMuted))
                  else
                    Semantics(
                      container: true,
                      label: 'Ingredients from your recipes',
                      child: Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final k in chips) KitchenChip(label: k, on: kitchen.contains(k), onTap: () => repo.setHave(k, !kitchen.contains(k))),
                      ]),
                    ),
                  const SizedBox(height: 10),
                  Text('Only ingredients from your saved recipes are listed.$staplesLine',
                      style: text.labelLarge!.copyWith(height: 1.45, fontWeight: FontWeight.w600, color: c.inkMuted)),
                ]),
              ),
            ),
            if (result != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (result.kitchenEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Space.xl, Space.xxl, Space.xl, 0),
                      child: Text('Tap the ingredients you have to see which recipes fit.',
                          textAlign: TextAlign.center, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
                    )
                  else if (result.ready.isEmpty && result.missing.isEmpty && result.more.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Space.xl, Space.xxl, Space.xl, 0),
                      child: Text('None of your recipes use these ingredients yet.',
                          textAlign: TextAlign.center, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
                    ),
                  if (result.ready.isNotEmpty) group('Ready to cook', result.ready),
                  if (result.missing.isNotEmpty) group('Missing 1–2', result.missing),
                  if (result.more.isNotEmpty) ...[
                    const SizedBox(height: Space.l),
                    Semantics(
                      expanded: _moreOpen,
                      child: OzoneButton(
                        label: _moreOpen ? 'Hide recipes that need more' : 'Show ${result.more.length} more that need 3+ items',
                        primary: false,
                        height: 48,
                        onPressed: () => setState(() => _moreOpen = !_moreOpen),
                      ),
                    ),
                    if (_moreOpen) group('Needs more', result.more),
                  ],
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// One ingredient to tick (board R6): olive with a tick when it's in the kitchen.
class KitchenChip extends StatelessWidget {
  const KitchenChip({super.key, required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      checked: on,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: PressScale(
        scale: PressScale.button,
        child: FadeMaterial(
          color: on ? recipeAccent(context) : c.surfaceSunken,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (on) ...[Icon(OzIcons.check, size: 15, color: c.onAccent), const SizedBox(width: 4)],
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: on ? c.onAccent : c.ink)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A recipe in a group: photo, title, "Uses …" and "Missing: …".
class CookRow extends StatelessWidget {
  const CookRow({super.key, required this.match, required this.photoFile, required this.background, this.compact = false, this.duration});
  final CookMatch match;
  final String? photoFile;
  final Color background;

  /// The Home widget's smaller row: "Ready · 15 min" or "Missing: …" only.
  final bool compact;
  /// "15 min", for "Ready · 15 min".
  final String? duration;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final m = match;
    final missing = m.missing.isEmpty ? null : 'Missing: ${m.missing.join(', ')}';
    final lines = compact
        ? [missing ?? (duration == null ? 'Ready' : 'Ready · $duration')]
        : ['Uses ${m.uses.join(', ')}', ?missing];
    void open() => context.push('/recipe/${m.id}');
    final size = compact ? 44.0 : 60.0;
    return Semantics(
      container: true,
      button: true,
      label: spokenAmounts([m.title, ...lines].join(', ')),
      onTap: open,
      excludeSemantics: true,
      child: PressScale(
        scale: PressScale.card,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: open,
            child: Padding(
              padding: EdgeInsets.fromLTRB(compact ? 8 : 10, compact ? 8 : 10, 14, compact ? 8 : 10),
              child: Row(children: [
                RecipePhoto(file: photoFile, width: size, height: size, radius: compact ? 12 : 14, iconSize: compact ? 22 : 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyLarge!.copyWith(fontSize: compact ? 14.5 : 15, fontWeight: FontWeight.w800)),
                    for (final l in lines) ...[
                      const SizedBox(height: 3),
                      Text(l,
                          maxLines: compact ? 1 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge!.copyWith(
                            height: 1.35,
                            fontWeight: l == missing ? FontWeight.w700 : FontWeight.w600,
                            color: l == missing ? c.attentionInk : c.inkMuted,
                          )),
                    ],
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

