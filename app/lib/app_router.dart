import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell/tool_registry.dart';
import 'shell/ui/edit_bar/edit_bar_screen.dart';
import 'shell/ui/home/home_screen.dart';
import 'shell/ui/settings/about_screen.dart';
import 'shell/ui/settings/appearance_screen.dart';
import 'shell/ui/settings/dashboard_arrange_screen.dart';
import 'shell/ui/settings/security_screen.dart';
import 'shell/ui/settings/settings_screen.dart';
import 'shell/ui/shell_scaffold.dart';
import 'shell/ui/tools_launcher/tools_screen.dart';

/// Branch order: Home, then every registered tool, then Tools. Every tool has
/// its own branch (and back stack) whether or not it sits in the bar; the bar
/// only chooses which branches get a tab (docs/04 navigation rules).
int branchOfTool(String id) => 1 + toolRegistry.indexWhere((t) => t.id == id);
int get toolsBranch => 1 + toolRegistry.length;

final _rootKey = GlobalKey<NavigatorState>();

/// Settings and Edit bar open above the bar (docs/04: the bar is hidden in
/// editors and forms; the W3 boards show these screens without it).
GoRoute _full(String path, Widget child) =>
    GoRoute(path: path, parentNavigatorKey: _rootKey, builder: (context, state) => child);

GoRouter buildRouter() => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => ShellScaffold(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            ]),
            for (final t in toolRegistry)
              StatefulShellBranch(routes: [
                GoRoute(path: t.routeBase, builder: (context, state) => t.home(context)),
              ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/tools', builder: (context, state) => const ToolsScreen()),
            ]),
          ],
        ),
        _full('/settings', const SettingsScreen()),
        _full('/settings/appearance', const AppearanceScreen()),
        _full('/settings/dashboard', const DashboardArrangeScreen()),
        _full('/settings/security', const SecurityScreen()),
        _full('/settings/about', const AboutScreen()),
        _full('/edit-bar', const EditBarScreen()),
      ],
    );
