import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell/tool_registry.dart';
import 'shell/ui/home/home_screen.dart';
import 'shell/ui/shell_scaffold.dart';
import 'shell/ui/tools_launcher/tools_screen.dart';

/// Builds the router: one branch (with its own back stack) per bar tab.
GoRouter buildRouter({List<String> barToolIds = defaultBarTools}) {
  final barTools = [
    for (final id in barToolIds.take(3)) toolRegistry.firstWhere((t) => t.id == id),
  ];
  final items = [
    const BarItem(label: 'Home', icon: Icons.home_rounded),
    for (final t in barTools) BarItem(label: t.name, icon: t.icon, tint: t.tint),
    const BarItem(label: 'Tools', icon: Icons.grid_view_rounded),
  ];
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScaffold(shell: shell, items: items),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ]),
          for (final t in barTools)
            StatefulShellBranch(routes: [
              GoRoute(path: t.routeBase, builder: (context, state) => t.home(context)),
            ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tools', builder: (context, state) => const ToolsScreen()),
          ]),
        ],
      ),
    ],
  );
}
