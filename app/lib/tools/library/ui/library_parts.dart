import 'package:flutter/material.dart';

import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/library.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/components/components.dart';

/// Library accent and tile for the current theme (docs/05 tool tints).
Color libraryAccent(BuildContext context) => ToolTint.library.accentOf(context);
Color libraryTile(BuildContext context) => ToolTint.library.tileOf(context);
Color libraryCard(BuildContext context) => ToolTint.library.cardOf(context);

/// The blue book tile in rows (40 × 52) and on Book detail (64 × 88).
class BookTile extends StatelessWidget {
  const BookTile({super.key, this.large = false});
  final bool large;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: large ? 64 : 40,
          height: large ? 88 : 52,
          decoration: BoxDecoration(color: libraryTile(context), borderRadius: BorderRadius.circular(large ? 10 : 8)),
          child: Icon(OzIcons.menuBook, size: large ? 28 : 20, color: libraryAccent(context)),
        ),
      );
}

/// Status pill: Finished is filled; Reading is tinted; the rest are neutral (W2 · Library).
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final (bg, fg) = switch (status) {
      BookStatus.finished => (libraryAccent(context), c.onAccent),
      BookStatus.reading => (libraryTile(context), libraryAccent(context)),
      _ => (c.surfaceSunken, c.inkMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status == BookStatus.finished ? '✓ Finished' : status.label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

/// One-choice pills in the Library accent (status and acquisition chips).
class LibraryChoice<T> extends StatelessWidget {
  const LibraryChoice({super.key, required this.label, required this.options, required this.selected, required this.onSelected, this.grid = false});
  final String label;
  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  /// Two equal columns, as on Book detail.
  final bool grid;

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
        excludeSemantics: true,
        child: PressScale(scale: PressScale.button, child: FadeMaterial(
          color: on ? libraryAccent(context) : c.surfaceSunken,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => onSelected(o.$1),
            // widthFactor 1: a pill is as wide as its label (in a grid, Expanded stretches it).
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: PillSize.minWidth, minHeight: 48, maxHeight: 48),
              child: Center(
                widthFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  // The tick grows in when the chip is picked (step 3, moment 6).
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
        )),
      );
    }

    return Semantics(
      label: spokenAmounts(label),
      container: true,
      child: grid
          ? Column(children: [
              for (var i = 0; i < options.length; i += 2)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                  child: Row(children: [
                    Expanded(child: pill(options[i])),
                    const SizedBox(width: 6),
                    Expanded(child: i + 1 < options.length ? pill(options[i + 1]) : const SizedBox.shrink()),
                  ]),
                ),
            ])
          : Wrap(spacing: Space.s, runSpacing: Space.s, children: [for (final o in options) pill(o)]),
    );
  }
}

/// Rating: five stars showing the value, − / + in half-star steps, and
/// "Clear rating" back to Not rated (decision M4-2). Not rated ≠ 0 stars.
class RatingStepper extends StatelessWidget {
  const RatingStepper({super.key, required this.half, required this.onChanged});

  /// 0–10, or null for Not rated.
  final int? half;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final v = half ?? 0;
    IconData star(int i) => v == 2 * i + 1 ? OzIcons.starHalf : OzIcons.star;
    Widget step(String label, IconData icon, int? next) => IconButton(
          tooltip: label,
          onPressed: next == null
              ? null
              : () {
                  Haptics.toggle();
                  onChanged(next);
                },
          style: IconButton.styleFrom(backgroundColor: c.surfaceSunken, disabledBackgroundColor: c.surfaceSunken, fixedSize: const Size(48, 48)),
          icon: Icon(icon, color: next == null ? c.outline : c.ink),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Semantics(
            label: spokenAmounts(ratingSpoken(half)),
            excludeSemantics: true,
            child: Row(children: [
              // Lit stars fill and pop, each 40 ms after the one before (step 3, moment 9).
              for (var i = 0; i < 5; i++)
                FillIcon(star(i),
                    filled: v > 2 * i,
                    popWhen: v > 2 * i ? half : null,
                    delay: Duration(milliseconds: 40 * i),
                    size: 24,
                    color: half == null ? c.outline : libraryAccent(context)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(half == null ? 'Not rated' : (half! / 2).toStringAsFixed(1),
                    style: text.bodyMedium!.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: half == null ? c.inkMuted : libraryAccent(context))),
              ),
            ]),
          ),
        ),
        // From Not rated, + starts at ½ and − at 0 stars.
        step('Lower rating by half a star', OzIcons.remove, half == null ? 0 : (v > 0 ? v - 1 : null)),
        const SizedBox(width: 6),
        step('Raise rating by half a star', OzIcons.add, half == null ? 1 : (v < 10 ? v + 1 : null)),
      ]),
      if (half != null)
        TextButton(
          onPressed: () => onChanged(null),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 40)),
          child: Text('Clear rating',
              style: text.bodyMedium!.copyWith(color: c.ink, decoration: TextDecoration.underline, decorationColor: c.ink)),
        ),
    ]);
  }
}
