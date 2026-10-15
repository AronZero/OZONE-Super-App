import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/theme/tokens.dart';
import '../../shell/tool_registry.dart';
import 'notes_search.dart';
import 'ui/folders_tags_screen.dart';
import 'ui/note_editor_screen.dart';
import 'ui/notes_home.dart';
import 'ui/notes_widgets.dart';
import 'ui/trash_screen.dart';
import 'ui/vault/vault_screens.dart';
import '../../core/ui/theme/oz_icons.dart';

/// Notes tool definition (M5 notes, M6 vault; docs/spec/F3-04).
const ToolDefinition notesTool = ToolDefinition(
  id: 'notes',
  name: 'Notes',
  tint: ToolTint.notes,
  icon: OzIcons.description,
  routeBase: '/notes',
  home: _home,
  routes: _routes,
  widgets: {'pinned_notes': _pinned, 'recent_notes': _recent},
  searchSources: notesSearch,
  quickAdd: notesQuickAdd,
);

Widget _home(BuildContext context) => const NotesHome();
Widget _pinned(BuildContext context) => const PinnedNotesWidget();
Widget _recent(BuildContext context) => const RecentNotesWidget();

/// The editor, Folders & tags and Trash open above the bar (docs/04).
List<RouteBase> _routes(GlobalKey<NavigatorState> root) {
  GoRoute full(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, parentNavigatorKey: root, builder: (context, state) => build(state));
  return [
    full('n/:id', (s) => NoteEditorScreen(
          key: ValueKey(s.pathParameters['id']),
          noteId: s.pathParameters['id']!,
          isNew: s.uri.queryParameters['new'] == '1',
        )),
    full('manage', (_) => const FoldersTagsScreen()),
    full('trash', (_) => const TrashScreen()),
    // The notes vault (M6, F2-01 §4); Settings › Security opens these too.
    full('vault/setup', (s) => VaultSetupScreen(forLocking: s.uri.queryParameters['lock'] == '1')),
    full('vault/forgot', (_) => const VaultForgotScreen()),
    full('vault/reset', (_) => const VaultResetScreen()),
    full('vault/password', (_) => const VaultChangePasswordScreen()),
    full('vault/code', (_) => const VaultNewCodeScreen()),
  ];
}
