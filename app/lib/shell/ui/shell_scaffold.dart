import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/theme/app_theme.dart';
import '../../core/ui/theme/tokens.dart';

/// One entry in the bottom bar.
class BarItem {
  const BarItem({required this.label, required this.icon, this.tint});

  final String label;
  final IconData icon;

  /// Null for Home and Tools (shell screens: neutral active pill).
  final ToolTint? tint;
}

/// The app shell: the current tab's screen plus the bottom bar
/// (Home · up to 3 tools · Tools; docs/04 navigation rules).
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.shell, required this.items});

  final StatefulNavigationShell shell;
  final List<BarItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _Bar(
        items: items,
        current: shell.currentIndex,
        // Tapping the active tab returns to its main screen.
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
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
                    label: items[i].label,
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            width: 52,
                            height: 32,
                            decoration: BoxDecoration(
                              color: i == current
                                  ? (items[i].tint?.tile(b) ?? c.barActive)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              items[i].icon,
                              size: 22,
                              color: i == current
                                  ? (items[i].tint?.accent(b) ?? c.ink)
                                  : c.inkMuted,
                            ),
                          ),
                          const SizedBox(height: Space.xs),
                          Text(
                            items[i].label,
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
