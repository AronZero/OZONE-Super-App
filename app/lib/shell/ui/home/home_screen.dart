import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../dashboard/widget_catalog.dart';
import '../../tool_registry.dart';

/// Home (W1 · Home): the dashboard, following the "Home dashboard" arrangement.
/// Tools supply their widgets through the registry; the rest say when they arrive.
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
                for (final id in shown)
                  if (id == 'needs_attention')
                    const _NeedsAttention()
                  else ...[
                    _toolWidget(id)?.call(context) ?? _WidgetFrame(info: widgetCatalog[id]!, brightness: b),
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

WidgetBuilder? _toolWidget(String id) {
  for (final t in toolRegistry) {
    final w = t.widgets[id];
    if (w != null) return w;
  }
  return null;
}

/// "Needs attention" (W1 · Home): one line per item from every tool, each
/// opening its fix. Hidden when there's nothing to do.
class _NeedsAttention extends ConsumerWidget {
  const _NeedsAttention();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [for (final t in toolRegistry) ...t.attention(ref)];
    if (items.isEmpty) return const SizedBox.shrink();
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.l + 2, Space.m, Space.s, Space.s),
        decoration: BoxDecoration(color: c.attentionBg, borderRadius: BorderRadius.circular(Radii.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Needs attention', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.attentionInk)),
            for (final i in items)
              InkWell(
                borderRadius: BorderRadius.circular(Radii.tile),
                onTap: () => context.push(i.route),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(children: [
                    Expanded(child: Text(i.message, style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: c.attentionInk))),
                    Icon(Icons.chevron_right_rounded, color: c.attentionInk),
                  ]),
                ),
              ),
          ],
        ),
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
