import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/notes_repo.dart';
import '../domain/notes.dart';
import '../state/notes_providers.dart';
import 'note_sheets.dart';
import 'notes_parts.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/motion.dart';

String _count(int n) => '$n ${n == 1 ? 'note' : 'notes'}';

/// W3 · Folders & tags: rename and delete folders; rename, merge and delete
/// tags (F2-02 §4). The Trash button opens W3 · Trash.
class FoldersTagsScreen extends ConsumerStatefulWidget {
  const FoldersTagsScreen({super.key});

  @override
  ConsumerState<FoldersTagsScreen> createState() => _FoldersTagsScreenState();
}

class _FoldersTagsScreenState extends ConsumerState<FoldersTagsScreen> {
  bool _tags = false;

  NotesRepo get _repo => ref.read(notesRepoProvider);

  Future<void> _renameFolder(NotesData data, FolderRow f) async {
    final others = [for (final o in data.folders) if (o.id != f.id) o.name];
    final name = await promptName(context, title: 'Rename folder', label: 'Name', action: 'Rename', initial: f.name, parse: (s) => parseFolderName(s, others));
    if (name != null && name != f.name) await _repo.renameFolder(f.id, name);
  }

  Future<void> _deleteFolder(NotesData data, FolderRow f) async {
    final n = data.folderUse(f.id);
    final ok = await confirmDialog(
      context,
      title: 'Delete the folder "${f.name}"?',
      body: n == 0 ? 'The folder is empty.' : 'Its ${_count(n)} move to Unfiled. No note is deleted.',
      confirm: 'Delete folder',
      danger: true,
    );
    if (ok == true) await _repo.deleteFolder(f.id);
  }

  Future<void> _renameTag(NotesData data, TagRow t) async {
    final name = await promptName(
      context,
      title: 'Rename #${t.name}',
      label: 'Tag',
      action: 'Rename',
      initial: t.name,
      parse: parseTag,
    );
    if (name == null || name == t.name || !mounted) return;
    final other = data.tags.where((o) => o.name == name && o.id != t.id).firstOrNull;
    if (other != null) {
      // Renaming onto an existing tag merges them, after a confirmation (F2-02 §4).
      final ok = await confirmDialog(
        context,
        title: 'Merge into #$name?',
        body: '#$name already exists. Its notes and the ${_count(data.tagUse(t.id))} tagged #${t.name} will all be tagged #$name.',
        confirm: 'Merge',
      );
      if (ok != true) return;
    }
    await _repo.renameTag(t.id, name);
  }

  Future<void> _mergeTag(NotesData data, TagRow t) async {
    final into = await showOzoneSheet<TagRow>(
      context,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.xl, Space.m, Space.xl, Space.xl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Semantics(header: true, child: Text('Merge #${t.name} into…', style: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: Space.m),
            GroupCard(children: [
              for (final o in data.tags)
                if (o.id != t.id) SettingsRow(title: '#${o.name}', subtitle: _count(data.tagUse(o.id)), onTap: () => Navigator.of(context).pop(o)),
            ]),
            const SizedBox(height: Space.m),
            OzoneButton(label: 'Cancel', primary: false, height: 48, onPressed: () => Navigator.of(context).pop()),
          ]),
        ),
      ),
    );
    if (into == null || !mounted) return;
    final ok = await confirmDialog(
      context,
      title: 'Merge #${t.name} into #${into.name}?',
      body: 'Every note tagged #${t.name} will be tagged #${into.name}, and #${t.name} goes.',
      confirm: 'Merge',
    );
    if (ok == true) await _repo.mergeTag(t.id, into.id);
  }

  Future<void> _deleteTag(NotesData data, TagRow t) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete #${t.name}?',
      body: 'The label is removed from ${_count(data.tagUse(t.id))}. The notes stay.',
      confirm: 'Delete tag',
      danger: true,
    );
    if (ok == true) await _repo.deleteTag(t.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final data = ref.watch(notesDataProvider).value;
    final trashCount = data?.trashed.length ?? 0;

    Widget hint(String s) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xs),
          child: Text(s, style: text.bodyMedium!.copyWith(fontSize: 13, height: 1.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
        );

    Widget iconAction(IconData icon, String label, VoidCallback onTap, {bool danger = false}) =>
        IconButton(tooltip: label, onPressed: onTap, icon: Icon(icon, size: 20, color: danger ? c.danger : c.ink), constraints: const BoxConstraints(minWidth: 44, minHeight: 44));

    Widget small(String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(left: 6),
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: c.surfaceSunken,
              foregroundColor: c.ink,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const StadiumBorder(),
              textStyle: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
            child: Text(label),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: staggered([
            DetailTopBar(title: 'Folders & tags', overline: 'Notes', trailing: [
              Padding(
                padding: const EdgeInsets.only(right: Space.s),
                child: FilledButton.icon(
                  onPressed: () => context.push('/notes/trash'),
                  icon: const Icon(OzIcons.delete, size: 17),
                  label: Text(trashCount == 0 ? 'Trash' : 'Trash · $trashCount'),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.surfaceSunken,
                    foregroundColor: c.ink,
                    minimumSize: const Size(48, 48),
                    shape: const StadiumBorder(),
                    textStyle: text.bodyMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ]),
            if (data != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SegmentTabs(
                    labels: ['Folders · ${data.folders.length}', 'Tags · ${data.tags.length}'],
                    selected: _tags ? 1 : 0,
                    onSelected: (i) => setState(() => _tags = i == 1),
                  ),
                  const SizedBox(height: Space.m),
                  if (!_tags) ...[
                    GroupCard(children: [
                      SettingsRow(title: 'Unfiled', subtitle: '${_count(data.folderUse(null))} · default, can\'t be removed'),
                      for (final f in data.folders)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.s, Space.s),
                          child: Row(children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(f.name, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(_count(data.folderUse(f.id)), style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
                              ]),
                            ),
                            iconAction(OzIcons.edit, 'Rename ${f.name}', () => _renameFolder(data, f)),
                            iconAction(OzIcons.delete, 'Delete folder ${f.name}', () => _deleteFolder(data, f), danger: true),
                          ]),
                        ),
                    ]),
                    const SizedBox(height: Space.m),
                    OzoneButton(label: 'New folder', color: notesAccent(context), foreground: c.onAccent, height: 48, onPressed: () => newFolder(context, ref)),
                    const SizedBox(height: Space.m),
                    hint('Folders are one level deep. Deleting a folder moves its notes to Unfiled; no note is deleted.'),
                  ] else ...[
                    if (data.tags.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(Space.xl),
                        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                        child: Text('No tags yet.', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                      )
                    else
                      GroupCard(children: [
                        for (final t in data.tags)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.xs, Space.s),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  TagChip(t.name),
                                  const SizedBox(height: Space.xs),
                                  Text(_count(data.tagUse(t.id)), style: text.bodyMedium!.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: c.inkMuted)),
                                ]),
                              ),
                              small('Rename', () => _renameTag(data, t)),
                              if (data.tags.length > 1) small('Merge', () => _mergeTag(data, t)),
                              iconAction(OzIcons.delete, 'Delete tag ${t.name}', () => _deleteTag(data, t), danger: true),
                            ]),
                          ),
                      ]),
                    const SizedBox(height: Space.m),
                    hint('Add tags from inside a note. Merge moves every note from one tag to another. Deleting a tag only removes the label; the notes stay.'),
                  ],
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

