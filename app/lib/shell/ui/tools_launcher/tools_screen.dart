import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../tool_registry.dart';

/// Tools launcher (W3 · Tools launcher): every tool, with the ones in the bar first.
class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final bar = ref.watch(barToolsProvider).value ?? const <String>[];
    bool matches(ToolDefinition t) => _query.isEmpty || t.name.toLowerCase().contains(_query.toLowerCase());
    final inBar = [for (final id in bar) ...toolRegistry.where((t) => t.id == id && matches(t))];
    final others = [for (final t in toolRegistry) if (!bar.contains(t.id) && matches(t)) t];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxxl),
        children: [
          MainTopBar(title: 'Tools', actions: [
            FilledButton.icon(
              onPressed: () => context.push('/edit-bar'),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit bar'),
              style: FilledButton.styleFrom(
                backgroundColor: c.surfaceSunken,
                foregroundColor: c.ink,
                minimumSize: const Size(48, 48),
                textStyle: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Find a tool',
                    filled: true,
                    fillColor: c.surfaceSunken,
                    prefixIcon: Icon(Icons.search_rounded, color: c.inkMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: Space.l),
                _Label('In your bar · ${bar.length} of 3'),
                _Grid(tools: inBar),
                if (inBar.isEmpty)
                  Text('No tools in the bar. Add them with Edit bar.', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                const SizedBox(height: Space.l),
                const _Label('More tools'),
                if (others.isNotEmpty) _Grid(tools: others),
                Container(
                  margin: EdgeInsets.only(top: others.isEmpty ? 0 : Space.m),
                  padding: const EdgeInsets.all(Space.l + 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.card),
                    border: Border.all(color: c.outline, width: 2),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('New tools will appear here', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: Space.xs),
                    Text('Up to 3 tools sit in the bar. The rest live here, and you can swap them with Edit bar.',
                        style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.s),
        child: Text(text,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: OzoneThemeColors.of(context).inkMuted,
                )),
      );
}

class _Grid extends StatelessWidget {
  const _Grid({required this.tools});
  final List<ToolDefinition> tools;

  static const _subtitles = {
    'finance': 'Savings · Gold · Expenses',
    'library': 'Books and reading',
    'notes': 'Notes, folders and the vault',
  };

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      // Taller tiles as text grows (200% text, docs/04).
      childAspectRatio: 1.45 / (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 2.0),
      children: [
        for (final t in tools)
          Material(
            color: t.tint.tile(b),
            borderRadius: BorderRadius.circular(Radii.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.card),
              onTap: () => context.go(t.routeBase),
              child: Padding(
                padding: const EdgeInsets.all(Space.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.tile)),
                      child: Icon(t.icon, color: t.tint.accent(b), size: 22),
                    ),
                    const Spacer(),
                    Text(t.name, style: text.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                    Text(_subtitles[t.id] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
