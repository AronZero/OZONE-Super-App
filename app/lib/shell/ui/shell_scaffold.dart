import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../core/state/providers.dart';
import '../../core/ui/theme/app_theme.dart';
import '../../core/ui/theme/tokens.dart';
import '../tool_registry.dart';
import '../../core/ui/amounts.dart';

/// One entry in the bottom bar.
class BarItem {
  const BarItem({required this.label, required this.icon, required this.branch, this.tint});

  final String label;
  final IconData icon;
  final int branch;

  /// Null for Home and Tools (shell screens: neutral active pill).
  final ToolTint? tint;
}

/// The app shell: the current tab's screen plus the bottom bar
/// (Home · up to 3 tools from settings · Tools; docs/04 navigation rules).
class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barIds = ref.watch(barToolsProvider).value ?? const ['finance', 'library', 'notes'];
    final items = [
      const BarItem(label: 'Home', icon: Icons.home_rounded, branch: 0),
      for (final id in barIds)
        for (final t in toolRegistry.where((t) => t.id == id))
          BarItem(label: t.name, icon: t.icon, tint: t.tint, branch: branchOfTool(t.id)),
      BarItem(label: 'Tools', icon: Icons.grid_view_rounded, branch: toolsBranch),
    ];
    // A tool opened from the launcher but not in the bar keeps "Tools" active.
    var current = items.indexWhere((i) => i.branch == shell.currentIndex);
    if (current < 0) current = items.length - 1;

    return Scaffold(
      body: shell,
      bottomNavigationBar: _Bar(
        items: items,
        current: current,
        onTap: (i) => shell.goBranch(items[i].branch, initialLocation: items[i].branch == shell.currentIndex),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.items, required this.current, required this.onTap});

  final List<BarItem> items;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final b = Theme.of(context).brightness;
    final label = Theme.of(context).textTheme.labelSmall!;
    return Material(
      color: c.bar,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    key: ValueKey('bar-${items[i].label}'),
                    selected: i == current,
                    button: true,
                    label: spokenAmounts(items[i].label),
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
                            width: 52,
                            height: 32,
                            decoration: BoxDecoration(
                              color: i == current ? (items[i].tint?.tile(b) ?? c.barActive) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              items[i].icon,
                              size: 22,
                              color: i == current ? (items[i].tint?.accent(b) ?? c.ink) : c.inkMuted,
                            ),
                          ),
                          const SizedBox(height: Space.xs),
                          Text(
                            items[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: label.copyWith(
                              color: i == current ? c.ink : c.inkMuted,
                              fontWeight: i == current ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
