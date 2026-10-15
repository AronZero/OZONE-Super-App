import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shell/tool_registry.dart';
import 'state/notes_providers.dart';
import '../../core/ui/theme/oz_icons.dart';

/// Notes in global search (F2-02 §1). Locked and trashed notes are never
/// indexed, so they can't appear here.
const List<SearchSource> notesSearch = [
  SearchSource(entity: 'note', group: 'Notes', chip: 'Notes', open: _open, describe: _note),
];

void _open(BuildContext context, WidgetRef ref, String id) => context.push('/notes/n/$id');

/// The search snippet already shows the matching text; the second line names the folder.
SearchRowInfo? _note(BuildContext context, WidgetRef ref, String id) {
  final d = ref.watch(notesDataProvider).value;
  final n = d?.byId(id);
  if (d == null || n == null) return null;
  return SearchRowInfo(d.folder(n.folderId)?.name ?? 'Unfiled');
}

/// Notes' entry in Home's quick-add menu: a new note opens straight away.
const List<QuickAddAction> notesQuickAdd = [
  QuickAddAction(label: 'New note', icon: OzIcons.editNote, run: _newNote),
];

Future<void> _newNote(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final id = await container.read(notesRepoProvider).create();
  if (!context.mounted) return;
  context.go('/notes');
  await context.push('/notes/n/$id?new=1');
}
