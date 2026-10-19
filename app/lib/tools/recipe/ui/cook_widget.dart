import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/cook.dart';
import '../domain/recipe.dart';
import '../state/recipe_providers.dart';
import 'cook_screen.dart';
import 'recipe_parts.dart';

/// Home widget "What can I cook?" (board R7, F4-02 §7): up to 3 recipes,
/// Ready first, then Missing 1–2. Starts hidden on the dashboard.
class CookWidget extends ConsumerWidget {
  const CookWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final result = ref.watch(cookResultProvider);
    final data = ref.watch(recipesDataProvider).value;
    void openCook() => context.push('/recipe/cook');
    final rows = result == null ? const <CookMatch>[] : [...result.ready, ...result.missing].take(3).toList();

    Widget badgeIcon() => Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: recipeAccent(context), borderRadius: BorderRadius.circular(10)),
          child: Icon(OzIcons.shoppingBasket, size: 18, color: c.onAccent),
        );
    final title = Text('What can I cook?', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800));

    if (result == null || rows.isEmpty) {
      final empty = result == null || result.kitchenEmpty;
      // Its own node, so TalkBack doesn't read it with the widget above.
      return Semantics(
        container: true,
        child: Container(
        padding: const EdgeInsets.fromLTRB(18, Space.l, 18, Space.l),
        decoration: BoxDecoration(color: recipeCard(context), borderRadius: BorderRadius.circular(Radii.card)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [badgeIcon(), const SizedBox(width: 10), Expanded(child: title)]),
          const SizedBox(height: 10),
          Text(
            empty
                ? 'Tap what’s in your kitchen, and OZONE shows which of your recipes you can make.'
                : 'None of your recipes fit what’s in your kitchen yet.',
            style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted),
          ),
          const SizedBox(height: Space.m),
          OzoneButton(label: 'Pick ingredients', height: 48, color: recipeAccent(context), foreground: c.onAccent, onPressed: openCook),
        ]),
        ),
      );
    }

    final n = result.kitchen.length;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: recipeCard(context), borderRadius: BorderRadius.circular(Radii.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          button: true,
          label: 'What can I cook?${result.ready.isEmpty ? '' : ', ${result.ready.length} ready'}',
          onTap: openCook,
          excludeSemantics: true,
          child: PressScale(
            scale: PressScale.card,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: openCook,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(children: [
                    badgeIcon(),
                    const SizedBox(width: 10),
                    Expanded(child: title),
                    if (result.ready.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: recipeAccent(context), borderRadius: BorderRadius.circular(999)),
                        child: Text('${result.ready.length} ready', style: text.labelMedium!.copyWith(fontWeight: FontWeight.w800, color: c.onAccent)),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
        for (final m in rows) ...[
          const SizedBox(height: 6),
          CookRow(
            match: m,
            compact: true,
            background: c.onCard,
            photoFile: data?.byId(m.id)?.row.photoFile,
            duration: _duration(data?.byId(m.id)?.row),
          ),
        ],
        Semantics(
          button: true,
          label: 'From $n ${n == 1 ? 'ingredient' : 'ingredients'} in your kitchen. Update',
          onTap: openCook,
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: openCook,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  Expanded(
                    child: Text('From $n ${n == 1 ? 'ingredient' : 'ingredients'} in your kitchen',
                        style: text.labelLarge!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
                  ),
                  Text('Update ›', style: text.labelLarge!.copyWith(fontWeight: FontWeight.w800, color: recipeAccent(context))),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

String? _duration(RecipeRow? r) => r == null ? null : durationText(r.prepMin, r.cookMin);

/// The card at the top of Recipes (board R1): "N ready with what you have".
class CookCard extends ConsumerWidget {
  const CookCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final result = ref.watch(cookResultProvider);
    final sub = result == null || result.kitchenEmpty ? 'Pick what’s in your kitchen' : '${result.ready.length} ready with what you have';
    void open() => context.push('/recipe/cook');
    return Semantics(
      button: true,
      label: 'What can I cook?, $sub',
      onTap: open,
      excludeSemantics: true,
      child: PressScale(
        scale: PressScale.card,
        child: Material(
          color: recipeCard(context),
          borderRadius: BorderRadius.circular(Radii.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 14, Space.l, 14),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: recipeAccent(context), borderRadius: BorderRadius.circular(14)),
                  child: Icon(OzIcons.shoppingBasket, size: 24, color: c.onAccent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('What can I cook?', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(sub, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
                  ]),
                ),
                Icon(OzIcons.chevronRight, color: recipeAccent(context)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
