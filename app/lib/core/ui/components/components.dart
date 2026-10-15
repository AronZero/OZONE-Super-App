import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../amounts.dart';
import '../theme/oz_icons.dart';

/// Detail top bar (back arrow, optional overline, title, trailing actions)
/// as on the W3 Settings boards.
class DetailTopBar extends StatelessWidget {
  const DetailTopBar({super.key, required this.title, this.overline, this.trailing = const [], this.onBack});

  final String title;
  final String? overline;
  final List<Widget> trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.s, Space.s),
      child: Row(
        children: [
          IconButton(
            tooltip: overline == null ? 'Back' : 'Back to $overline',
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: Icon(OzIcons.arrowBack, color: c.ink),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (overline != null) Text(overline!, style: text.labelLarge!.copyWith(color: c.inkMuted, fontWeight: FontWeight.w600)),
                Semantics(header: true, child: Text(title, style: text.titleLarge)),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

/// Main-screen top bar: large title and round icon actions.
class MainTopBar extends StatelessWidget {
  const MainTopBar({super.key, required this.title, this.actions = const [], this.leading});

  final String title;
  final List<Widget> actions;

  /// Shown before the title (Home: the OZONE mark).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.screen, Space.s),
      child: Row(
        children: [
          if (leading != null) Padding(padding: const EdgeInsets.only(right: Space.m), child: leading),
          Expanded(child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.headlineMedium))),
          for (final a in actions) Padding(padding: const EdgeInsets.only(left: 6), child: a),
        ],
      ),
    );
  }
}

/// Round 44 dp sunken icon button used in top bars.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: c.surfaceSunken,
        disabledBackgroundColor: c.surfaceSunken,
        fixedSize: const Size(48, 48),
      ),
      icon: Icon(icon, color: c.ink, size: 22),
    );
  }
}

/// Small uppercase section label above a group.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.xs, Space.l, Space.xs, Space.s),
        child: Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: OzoneThemeColors.of(context).inkMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                )),
      );
}

/// A white rounded card holding rows separated by thin lines.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      clipBehavior: Clip.antiAlias,
      // Stretch: every row is full width, whatever its content (free text included).
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.surfaceSunken.withValues(alpha: 0.7)),
            children[i],
          ],
        ],
      ),
    );
  }

  /// The same card as one widget per row (rounded at the ends), so a long list
  /// in a ListView builds only the rows on screen (F2-03 §8 scrolling).
  static List<Widget> rows(BuildContext context, List<Widget> children) {
    final c = OzoneThemeColors.of(context);
    const r = Radius.circular(Radii.card);
    return [
      for (var i = 0; i < children.length; i++)
        Material(
          color: c.surface,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.vertical(top: i == 0 ? r : Radius.zero, bottom: i == children.length - 1 ? r : Radius.zero),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (i > 0) Divider(height: 1, thickness: 1, color: c.surfaceSunken.withValues(alpha: 0.7)),
            children[i],
          ]),
        ),
    ];
  }
}

/// A settings row: optional icon tile, title, subtitle, trailing (chevron by default).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconBg,
    this.iconFg,
    this.onTap,
    this.trailing,
    this.titleColor,
    this.subtitleColor,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconBg;
  final Color? iconFg;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? titleColor;
  final Color? subtitleColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg ?? c.surfaceSunken, borderRadius: BorderRadius.circular(Radii.tile)),
                child: Icon(icon, size: 20, color: iconFg ?? c.ink),
              ),
              const SizedBox(width: Space.m),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700, color: titleColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, semanticsLabel: spokenAmounts(subtitle!), style: text.bodyMedium!.copyWith(color: subtitleColor ?? c.inkMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Space.s),
            trailing ?? (onTap != null ? Icon(OzIcons.chevronRight, color: c.inkMuted) : const SizedBox.shrink()),
          ],
        ),
      ),
    );
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: onTap == null || !enabled ? row : InkWell(onTap: onTap, child: row),
    );
  }
}

/// Ink-coloured switch for shell screens (tool screens pass their accent).
class OzoneSwitch extends StatelessWidget {
  const OzoneSwitch({super.key, required this.value, required this.onChanged, required this.label, this.accent});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return Semantics(
      label: spokenAmounts(label),
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: c.canvas,
        activeTrackColor: accent ?? c.ink,
        inactiveThumbColor: c.surface,
        inactiveTrackColor: c.outline,
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}

/// Single-choice chips (radio group), as on the Security and Appearance boards.
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({super.key, required this.label, required this.options, required this.selected, required this.onSelected});

  final String label;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: spokenAmounts(label),
      container: true,
      child: Row(
        children: [
          for (final (v, name) in options)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: v == selected,
                  button: true,
                  label: spokenAmounts(name),
                  excludeSemantics: true,
                  child: Material(
                    color: v == selected ? c.ink : c.surfaceSunken,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => onSelected(v),
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: Text(name,
                              style: text.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w800,
                                color: v == selected ? c.canvas : c.ink,
                              )),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-width shell button: ink (primary) or sunken (secondary).
class OzoneButton extends StatelessWidget {
  const OzoneButton({super.key, required this.label, required this.onPressed, this.primary = true, this.icon, this.color, this.foreground, this.height = 52});

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;
  final Color? color;

  /// Text colour on [color] (tool accents use `onAccent`).
  final Color? foreground;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final bg = color ?? (primary ? c.ink : c.surfaceSunken);
    final fg = foreground ?? (primary ? c.canvas : c.ink);
    return SizedBox(
      // Never under the 48 dp touch target (docs/04 › Accessibility).
      height: height < 48 ? 48 : height,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: Space.m),
          textStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
        ),
        // Half-width buttons ("Save & add another") scale a long label down rather than overflow.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: Space.s)],
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

/// Attention / warning banner (attention tokens, docs/05).
class AttentionBanner extends StatelessWidget {
  const AttentionBanner({super.key, required this.title, required this.body, this.action});

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Space.l),
      decoration: BoxDecoration(color: c.attentionBg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800, color: c.attentionInk)),
          const SizedBox(height: Space.xs),
          Text(body, style: text.bodyMedium!.copyWith(color: c.attentionInk)),
          if (action != null) ...[const SizedBox(height: Space.m), action!],
        ],
      ),
    );
  }
}

/// The 60 dp add button of a tool's main screen (one per screen, docs/04),
/// in the tool's accent.
class ToolAddButton extends StatelessWidget {
  const ToolAddButton({super.key, required this.label, required this.accent, required this.onPressed});
  final String label;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return Tooltip(
      message: label,
      child: Material(
        color: accent,
        borderRadius: BorderRadius.circular(Radii.addButton),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.addButton),
          onTap: onPressed,
          child: SizedBox(width: 60, height: 60, child: Icon(OzIcons.add, size: 28, color: c.onAccent)),
        ),
      ),
    );
  }
}
