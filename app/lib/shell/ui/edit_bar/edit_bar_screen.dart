import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../tool_registry.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../shell_bar.dart';
import '../../../core/ui/motion.dart';

/// Edit bar (W3 · Edit bar): choose and order up to 3 tools. Home and Tools
/// are always in the bar (docs/03). Changes apply at once.
class EditBarScreen extends ConsumerWidget {
  const EditBarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final bar = ref.watch(barToolsProvider).value ?? const <String>[];
    final repo = ref.read(settingsRepoProvider);
    Future<void> save(List<String> l) => repo.set(SettingKeys.barTools, l);

    final inBar = [for (final id in bar) ...toolRegistry.where((t) => t.id == id)];
    final out = [for (final t in toolRegistry) if (!bar.contains(t.id)) t];
    final full = bar.length >= 3;

    Widget toolTile(ToolDefinition t) => Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: t.tint.tileOf(context), borderRadius: BorderRadius.circular(12)),
          child: Icon(t.icon, size: 20, color: t.tint.accentOf(context)),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: staggered([
            DetailTopBar(title: 'Edit bar', overline: 'Tools', trailing: [
              Padding(
                padding: const EdgeInsets.only(right: Space.s),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(backgroundColor: c.ink, foregroundColor: c.canvas, minimumSize: const Size(64, 44)),
                  child: const Text('Done'),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Preview', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted)),
                  const SizedBox(height: Space.s),
                  Semantics(
                    label: spokenAmounts('Bar preview: ${['Home', ...inBar.map((t) => t.name), 'Tools'].join(', ')}'),
                    excludeSemantics: true,
                    // The real bar, static: you are on Tools.
                    child: OzoneBar(
                      keyPrefix: 'preview',
                      items: [
                        const BarItem(label: 'Home', icon: OzIcons.home, branch: 0),
                        for (final t in inBar) BarItem(label: t.name, icon: t.icon, tint: t.tint, branch: 0),
                        const BarItem(label: 'Tools', icon: OzIcons.gridView, branch: 0),
                      ],
                      current: inBar.length + 1,
                    ),
                  ),
                  const SizedBox(height: Space.s),
                  Text('Home and Tools are always in the bar.', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                  const SizedBox(height: Space.l),
                  Row(children: [
                    Expanded(child: Text('In the bar', style: text.titleMedium)),
                    Text('${bar.length} of 3', style: text.bodyMedium!.copyWith(color: c.inkMuted, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: Space.s),
                  GroupCard(children: [
                    if (inBar.isEmpty)
                      const SettingsRow(title: 'No tools in the bar', subtitle: 'Open them from Tools, or add one below.'),
                    for (var i = 0; i < inBar.length; i++)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(Space.m, 6, Space.s, 6),
                        child: Row(children: [
                          toolTile(inBar[i]),
                          const SizedBox(width: Space.m),
                          Expanded(child: Text(inBar[i].name, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700))),
                          IconButton(
                            tooltip: 'Move ${inBar[i].name} left in the bar',
                            onPressed: i == 0
                                ? null
                                : () {
                                    final l = [...bar];
                                    final t = l.removeAt(i);
                                    l.insert(i - 1, t);
                                    save(l);
                                  },
                            icon: const Icon(OzIcons.arrowUpward),
                          ),
                          TextButton(
                            onPressed: () => save([...bar]..remove(inBar[i].id)),
                            style: TextButton.styleFrom(backgroundColor: c.surfaceSunken, foregroundColor: c.ink, minimumSize: const Size(48, 48)),
                            child: Text('Remove', semanticsLabel: 'Remove ${inBar[i].name} from the bar'),
                          ),
                        ]),
                      ),
                  ]),
                  if (out.isNotEmpty) ...[
                    const SizedBox(height: Space.l),
                    Text('Not in the bar', style: text.titleMedium),
                    const SizedBox(height: Space.s),
                    GroupCard(children: [
                      for (final t in out)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(Space.m, 6, Space.s, 6),
                          child: Row(children: [
                            toolTile(t),
                            const SizedBox(width: Space.m),
                            Expanded(child: Text(t.name, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700))),
                            FilledButton(
                              onPressed: full ? null : () => save([...bar, t.id]),
                              style: FilledButton.styleFrom(backgroundColor: c.ink, foregroundColor: c.canvas, minimumSize: const Size(48, 48)),
                              child: Text('Add', semanticsLabel: 'Add ${t.name} to the bar'),
                            ),
                          ]),
                        ),
                    ]),
                  ],
                  const SizedBox(height: Space.m),
                  Text('Up to 3 tools fit. Remove one to make room for another.',
                      style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
