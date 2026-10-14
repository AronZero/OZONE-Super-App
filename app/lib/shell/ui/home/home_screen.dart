import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../dashboard/widget_catalog.dart';

/// Home (W1 · Home). M1: the top bar and the dashboard frame, following the
/// "Home dashboard" arrangement. Each widget's content arrives with its tool.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgets = ref.watch(dashboardWidgetsProvider).value ?? const [];
    final shown = [for (final w in widgets) if (w.on && widgetCatalog.containsKey(w.id)) w.id];
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final b = Theme.of(context).brightness;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxxl),
        children: [
          MainTopBar(title: 'Home', actions: [
            RoundIconButton(
              icon: Icons.search_rounded,
              label: 'Search (arrives in M7)',
              onPressed: null,
            ),
            RoundIconButton(
              icon: Icons.settings_rounded,
              label: 'Settings',
              onPressed: () => context.push('/settings'),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (shown.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(Space.xl),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                    child: Text('All widgets are hidden. Show them in Settings › Home dashboard.', style: text.bodyLarge),
                  ),
                for (final id in shown) ...[
                  _WidgetFrame(info: widgetCatalog[id]!, brightness: b),
                  const SizedBox(height: Space.m),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A dashboard widget's frame. Until its tool is built it says when it arrives.
class _WidgetFrame extends StatelessWidget {
  const _WidgetFrame({required this.info, required this.brightness});

  final WidgetInfo info;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final bg = info.tint?.tile(brightness) ?? c.attentionBg;
    final fg = info.tint?.accent(brightness) ?? c.attentionInk;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.l + 2, Space.l, Space.l, Space.l),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info.name, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: Space.xs),
            Text('Arrives with milestone ${info.milestone}', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
          ],
        ),
      ),
    );
  }
}
