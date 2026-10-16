import 'package:flutter/material.dart';

import '../../core/ui/theme/app_theme.dart';
import '../../core/ui/theme/tokens.dart';
import '../../core/ui/motion.dart';

/// A main screen with a large title and a one-sentence empty state.
/// Used until each screen is built in its milestone (docs/spec/F3-04).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
    this.tint,
    this.icon,
    this.footer,
  });

  final String title;
  final String message;
  final ToolTint? tint;
  final IconData? icon;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.screen, Space.xxxl),
        children: staggered([
          Semantics(header: true, child: Text(title, style: text.headlineMedium)),
          const SizedBox(height: Space.xxl),
          Container(
            padding: const EdgeInsets.all(Space.xl),
            decoration: BoxDecoration(
              color: tint?.tileOf(context) ?? c.surface,
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: tint?.accentOf(context) ?? c.ink, size: 28),
                  const SizedBox(width: Space.l),
                ],
                Expanded(child: Text(message, style: text.bodyLarge)),
              ],
            ),
          ),
          if (footer != null) ...[const SizedBox(height: Space.l), footer!],
        ]),
      ),
    );
  }
}
