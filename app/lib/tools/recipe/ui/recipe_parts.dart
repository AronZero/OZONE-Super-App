import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/providers.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/theme/tokens.dart';

/// Recipe accent, tile and card for the current theme (olive, decision R-1).
Color recipeAccent(BuildContext context) => ToolTint.recipe.accentOf(context);
Color recipeTile(BuildContext context) => ToolTint.recipe.tileOf(context);
Color recipeCard(BuildContext context) => ToolTint.recipe.cardOf(context);

/// The photo folder, resolved once.
final photoFolderProvider = FutureProvider<Directory>((ref) => ref.watch(photoStoreProvider).folder());

/// A recipe's photo, or the pot on the olive tile when there is none (or the
/// file is missing, for example after an import without photos).
class RecipePhoto extends ConsumerWidget {
  const RecipePhoto({super.key, required this.file, this.height, this.width, this.radius = 0, this.iconSize = 32, this.label});

  /// `<uuid>.jpg`, or null.
  final String? file;
  final double? height;
  final double? width;
  final double radius;
  final double iconSize;

  /// Shown under the icon in the placeholder ("Add photo"). [width] may be
  /// [double.infinity] to fill the parent.
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(photoFolderProvider).value;
    Widget placeholder() => Container(
          height: height,
          width: width,
          color: recipeTile(context),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(OzIcons.cooking, size: iconSize, color: recipeAccent(context)),
            if (label != null) ...[
              const SizedBox(height: Space.xs),
              Text(label!, style: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700, color: recipeAccent(context))),
            ],
          ]),
        );
    Widget body;
    if (file == null || dir == null) {
      body = placeholder();
    } else {
      final px = MediaQuery.devicePixelRatioOf(context);
      // Full-width photos are as wide as the screen at most.
      final w = width == null || !width!.isFinite ? MediaQuery.sizeOf(context).width : width!;
      body = Image.file(
        File('${dir.path}/$file'),
        height: height,
        width: width,
        fit: BoxFit.cover,
        // Decode at the size it's shown, so a long list stays light.
        cacheWidth: (w * px).round(),
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => placeholder(),
      );
    }
    return ExcludeSemantics(child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: body));
  }
}

/// One-choice pills in the Recipe accent (categories), as Library's chips.
class RecipeChoice<T> extends StatelessWidget {
  const RecipeChoice({super.key, required this.label, required this.options, required this.selected, required this.onSelected, this.wrap = true});
  final String label;
  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  /// Wrap onto more lines (form) or stay in one scrolling row (list).
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    Widget pill((T, String) o) {
      final on = o.$1 == selected;
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: on,
        button: true,
        label: spokenAmounts(o.$2),
        onTap: () => onSelected(o.$1),
        excludeSemantics: true,
        child: PressScale(
          scale: PressScale.button,
          child: FadeMaterial(
            color: on ? recipeAccent(context) : c.surfaceSunken,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onSelected(o.$1),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: PillSize.minWidth, minHeight: 48, maxHeight: 48),
                child: Center(
                  widthFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedContainer(
                        duration: Motion.of(context).tabs,
                        curve: Motion.settle,
                        width: on ? 19 : 0,
                        child: ClipRect(
                          child: OverflowBox(alignment: Alignment.centerLeft, minWidth: 0, maxWidth: 19, child: Icon(OzIcons.check, size: 15, color: c.onAccent)),
                        ),
                      ),
                      Flexible(
                        child: Text(o.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800, color: on ? c.onAccent : c.ink)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final pills = [for (final o in options) pill(o)];
    return Semantics(
      label: spokenAmounts(label),
      container: true,
      child: wrap
          ? Wrap(spacing: Space.s, runSpacing: Space.s, children: pills)
          : Row(children: [
              for (var i = 0; i < pills.length; i++) ...[if (i > 0) const SizedBox(width: 6), pills[i]],
            ]),
    );
  }
}
