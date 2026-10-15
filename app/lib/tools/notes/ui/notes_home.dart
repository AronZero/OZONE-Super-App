import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database.dart';
import '../../../core/data/settings_repo.dart';
import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/states.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/notes_repo.dart';
import '../state/notes_providers.dart';
import 'notes_parts.dart';
import 'vault/vault_unlock.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/shell_bar_scope.dart';

/// Folder filter: all notes, Unfiled, or one folder.
sealed class FolderFilter {
  const FolderFilter();
}

class AllFolders extends FolderFilter {
  const AllFolders();
}

class InFolder extends FolderFilter {
  const InFolder(this.id);

  /// Null = Unfiled.
  final String? id;

  @override
  bool operator ==(Object other) => other is InFolder && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// Whether the vault is open, for the "Lock notes now" button.
final _vaultOpenProvider = Provider.autoDispose<bool>((ref) {
  final v = ref.watch(vaultServiceProvider).isOpen;
  void changed() => ref.invalidateSelf();
  v.addListener(changed);
  ref.onDispose(() => v.removeListener(changed));
  return v.value;
});

/// Notes home (W2 · Notes home): folder chips, tag chips, pinned first,
/// grid or list, and the New note button.
class NotesHome extends ConsumerStatefulWidget {
  const NotesHome({super.key});

  @override
  ConsumerState<NotesHome> createState() => _NotesHomeState();
}

class _NotesHomeState extends ConsumerState<NotesHome> {
  FolderFilter _folder = const AllFolders();
  String? _tag;

  bool _match(NotesData data, NoteRow n) {
    final f = _folder;
    if (f is InFolder && n.folderId != f.id) return false;
    if (_tag != null && !data.tagsOf(n.id).any((t) => t.id == _tag)) return false;
    return true;
  }

  /// A locked note opens after the vault unlocks (W1 · Vault unlock).
  Future<void> _openLocked(String id) async {
    if (await ensureVaultOpen(context, ref) && mounted) openNote(context, id);
  }

  Future<void> _newNote() async {
    final data = ref.read(notesDataProvider).value;
    final f = _folder;
    // A filter in use becomes the new note's folder and tag (decision M5-3).
    final folderId = f is InFolder ? f.id : null;
    final tagId = _tag != null && data?.tags.any((t) => t.id == _tag) == true ? _tag : null;
    final id = await ref.read(notesRepoProvider).create(folderId: folderId, tagIds: [?tagId]);
    if (mounted) unawaited(context.push('/notes/n/$id?new=1'));
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final notes = ref.watch(notesDataProvider);
    final data = notes.value;
    final view = ref.watch(notesViewProvider).value ?? NotesView.grid;
    final vaultOpen = ref.watch(_vaultOpenProvider);

    // A folder or tag deleted elsewhere drops out of the filter.
    final f = _folder;
    if (data != null && f is InFolder && f.id != null && data.folder(f.id) == null) _folder = const AllFolders();
    if (data != null && _tag != null && !data.tags.any((t) => t.id == _tag)) _tag = null;

    final all = [...?data?.live.where((n) => _match(data, n))]..sort(NotesData.listOrder);
    final pinned = [for (final n in all) if (n.isPinned) n];
    final rest = [for (final n in all) if (!n.isPinned) n];
    final usedTags = [...?data?.tags.where((t) => data.tagUse(t.id) > 0 || t.id == _tag)];

    Widget card(NoteRow n) => NoteCard(
          note: n,
          today: today,
          tags: data!.tagsOf(n.id),
          folderName: data.folder(n.folderId)?.name,
          list: view == NotesView.list,
          onTap: () {
            if (n.isLocked) {
              unawaited(_openLocked(n.id));
            } else {
              openNote(context, n.id);
            }
          },
        );

    // A flat list (one item per row of cards) so the list builds only what is on screen.
    List<Widget> section(String? label, List<NoteRow> notes) => [
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xs, 6, Space.xs, Space.s),
              child: Semantics(header: true, child: Text(label, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800))),
            ),
          if (view == NotesView.grid)
            ...NoteGrid.rows([for (final n in notes) card(n)])
          else
            for (final n in notes) Padding(padding: const EdgeInsets.only(bottom: Space.s), child: card(n)),
        ];

    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: Space.s),
          child: Semantics(
            inMutuallyExclusiveGroup: true,
            checked: selected,
            button: true,
            label: spokenAmounts(label),
            excludeSemantics: true,
            child: Material(
              color: selected ? notesAccent(context) : c.surfaceSunken,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: Text(label,
                      style: text.bodyMedium!.copyWith(fontSize: 13, fontWeight: selected ? FontWeight.w800 : FontWeight.w700, color: selected ? c.onAccent : c.ink)),
                ),
              ),
            ),
          ),
        );

    final liveCount = data?.live.length ?? 0;
    final emptyAll = data != null && data.live.isEmpty;

    return Stack(children: [
      SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: shellListBottom(context)),
          children: [
            MainTopBar(title: 'Notes', actions: [
              // While the vault is open: lock it again now (F2-01 §4 "Lock button").
              if (vaultOpen)
                RoundIconButton(icon: OzIcons.lockOpen, label: 'Lock notes now', onPressed: () => ref.read(vaultServiceProvider).lock()),
              RoundIconButton(
                icon: view == NotesView.grid ? OzIcons.viewAgenda : OzIcons.gridView,
                label: view == NotesView.grid ? 'Switch to list view' : 'Switch to grid view',
                onPressed: () => ref.read(settingsRepoProvider).set(SettingKeys.notesView, view == NotesView.grid ? NotesView.list : NotesView.grid),
              ),
              RoundIconButton(icon: OzIcons.search, label: 'Search', onPressed: () => context.push('/search?scope=note')),
              RoundIconButton(icon: OzIcons.moreVert, label: 'Notes options: folders, tags, trash', onPressed: () => context.push('/notes/manage')),
            ]),
            if (!emptyAll) ...[
              Semantics(
                label: 'Folder',
                container: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(Space.screen, Space.s, Space.screen, 6),
                  child: Row(children: [
                    chip('All · $liveCount', _folder is AllFolders, () => setState(() => _folder = const AllFolders())),
                    chip('Unfiled', _folder == const InFolder(null), () => setState(() => _folder = const InFolder(null))),
                    for (final fo in [...?data?.folders]) chip(fo.name, _folder == InFolder(fo.id), () => setState(() => _folder = InFolder(fo.id))),
                  ]),
                ),
              ),
              if (usedTags.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(Space.screen, 2, Space.screen, Space.s),
                  child: Row(children: [
                    Text('Tags', style: text.labelLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: c.inkMuted)),
                    const SizedBox(width: Space.s),
                    for (final t in usedTags)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Semantics(
                          button: true,
                          toggled: _tag == t.id,
                          label: spokenAmounts('Tag ${t.name}'),
                          excludeSemantics: true,
                          child: Material(
                            color: _tag == t.id ? notesAccent(context) : notesTile(context),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => setState(() => _tag = _tag == t.id ? null : t.id),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 48),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                alignment: Alignment.center,
                                child: Text('#${t.name}',
                                    style: text.labelLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: _tag == t.id ? c.onAccent : notesAccent(context))),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
            ],
            for (final w in <Widget>[
                if (data == null)
                  notes.hasError
                      ? LoadError(what: 'Notes', error: notes.error!, stack: notes.stackTrace, onRetry: () => ref.invalidate(notesDataProvider))
                      : const DelayedSkeleton(),
                if (emptyAll)
                  Container(
                    margin: const EdgeInsets.only(top: Space.s),
                    padding: const EdgeInsets.all(Space.xl),
                    decoration: BoxDecoration(color: notesTile(context), borderRadius: BorderRadius.circular(Radii.card)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('No notes yet', style: text.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: Space.xs),
                      Text('Write lists, plans and ideas. Notes save as you type.', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                    ]),
                  )
                else if (data != null && all.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Space.l),
                    child: Text(_tag != null ? 'No notes with this tag here.' : 'No notes in this folder.', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                  ),
                if (pinned.isNotEmpty) ...section('Pinned', pinned),
                if (rest.isNotEmpty) ...[
                  if (pinned.isNotEmpty) const SizedBox(height: 6),
                  ...section(pinned.isEmpty ? null : 'All notes', rest),
                ],
              ])
              Padding(padding: const EdgeInsets.symmetric(horizontal: Space.screen), child: w),
          ],
        ),
      ),
      ShellAddButtonSlot(child: ToolAddButton(label: 'New note', accent: notesAccent(context), onPressed: _newNote),
      ),
    ]);
  }
}
