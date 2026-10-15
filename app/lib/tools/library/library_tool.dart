import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/theme/tokens.dart';
import '../../shell/tool_registry.dart';
import 'library_search.dart';
import 'ui/book_detail_screen.dart';
import 'ui/book_form_screen.dart';
import 'ui/library_home.dart';
import 'ui/library_stats_screen.dart';
import 'ui/library_widgets.dart';
import '../../core/ui/theme/oz_icons.dart';

/// Library tool definition (M4, docs/spec/F3-04).
const ToolDefinition libraryTool = ToolDefinition(
  id: 'library',
  name: 'Library',
  tint: ToolTint.library,
  icon: OzIcons.menuBook,
  routeBase: '/library',
  home: _home,
  routes: _routes,
  widgets: {'currently_reading': _currentlyReading, 'library_snapshot': _snapshot},
  searchSources: librarySearch,
  quickAdd: libraryQuickAdd,
);

Widget _home(BuildContext context) => const LibraryHome();
Widget _currentlyReading(BuildContext context) => const CurrentlyReadingWidget();
Widget _snapshot(BuildContext context) => const LibrarySnapshotWidget();

/// Library screens open above the bar (the form and detail boards have no bar).
List<RouteBase> _routes(GlobalKey<NavigatorState> root) {
  GoRoute full(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, parentNavigatorKey: root, builder: (context, state) => build(state));
  return [
    full('add', (_) => const BookFormScreen()),
    full('stats', (_) => const LibraryStatsScreen()),
    full('books/:id', (s) => BookDetailScreen(bookId: s.pathParameters['id']!)),
    full('books/:id/edit', (s) => BookFormScreen(bookId: s.pathParameters['id']!)),
  ];
}
