import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../dashboard/widget_catalog.dart';

/// Home dashboard arrange (W3 · Home dashboard arrange): reorder, show/hide,
/// reset. Preset widgets only, no sizes (docs/03 N4).
class DashboardArrangeScreen extends ConsumerWidget {
  const DashboardArrangeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final b = Theme.of(context).brightness;
    final repo = ref.read(settingsRepoProvider);
    final list = ref.watch(dashboardWidgetsProvider).value ?? defaultDashboard;
    final shown = list.where((w) => w.on).length;

    Future<void> save(List<WidgetSetting> l) => repo.set(SettingKeys.dashboardWidgets, l);
    void move(int from, int to) {
      final l = [...list];
      final w = l.removeAt(from);
      l.insert(to.clamp(0, l.length), w);
      save(l);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailTopBar(title: 'Home dashboard', overline: 'Settings', trailing: [
              Padding(
                padding: const EdgeInsets.only(right: Space.s),
                child: TextButton(
                  onPressed: () => repo.reset(SettingKeys.dashboardWidgets),
                  style: TextButton.styleFrom(backgroundColor: c.surfaceSunken, foregroundColor: c.ink, minimumSize: const Size(64, 44)),
                  child: const Text('Reset'),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l + Space.xs, 0, Space.l + Space.xs, Space.s),
              child: Row(children: [
                Expanded(child: Text('Drag to reorder. Switch off to hide.', style: text.bodyMedium!.copyWith(color: c.inkMuted))),
                Text('$shown of ${list.length} shown', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.xxxl),
                buildDefaultDragHandles: false,
                itemCount: list.length,
                onReorderItem: move,
                footer: Padding(
                  padding: const EdgeInsets.all(Space.xs),
                  child: Text('A new tool’s widgets start hidden. Reset restores the original order and choices.',
                      style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                ),
                itemBuilder: (context, i) {
                  final w = list[i];
                  final info = widgetCatalog[w.id];
                  final tint = info?.tint?.accent(b) ?? c.attentionInk;
                  return Padding(
                    key: ValueKey(w.id),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: Semantics(
                        customSemanticsActions: {
                          if (i > 0) const CustomSemanticsAction(label: 'Move up'): () => move(i, i - 1),
                          if (i < list.length - 1) const CustomSemanticsAction(label: 'Move down'): () => move(i, i + 1),
                        },
                        child: Row(children: [
                          ReorderableDragStartListener(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.l),
                              child: Icon(Icons.drag_indicator_rounded, color: c.inkMuted, semanticLabel: 'Drag to move ${info?.name}'),
                            ),
                          ),
                          Container(width: 6, height: 30, decoration: BoxDecoration(color: w.on ? tint : c.outline, borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: Space.m),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(info?.name ?? w.id,
                                  style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700, color: w.on ? c.ink : c.inkMuted)),
                              Text(info?.detail ?? '', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                            ]),
                          ),
                          OzoneSwitch(
                            label: 'Show ${info?.name}',
                            value: w.on,
                            onChanged: (v) => save([for (final x in list) x.id == w.id ? WidgetSetting(x.id, v) : x]),
                          ),
                          const SizedBox(width: Space.s),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
