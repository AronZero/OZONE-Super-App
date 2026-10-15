import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/domain/validation.dart';
import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/notes_repo.dart';
import '../domain/notes.dart';
import '../state/notes_providers.dart';
import 'notes_parts.dart';

/// A one-field dialog ("New folder", "Rename tag"). Returns the parsed value,
/// or null when cancelled. [parse] gives the error in words.
Future<String?> promptName(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  String initial = '',
  String? hint,
  required Validation<String> Function(String) parse,
}) =>
    showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _NameDialog(title: title, label: label, action: action, initial: initial, hint: hint, parse: parse),
    );

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.label, required this.action, required this.initial, required this.hint, required this.parse});
  final String title, label, action, initial;
  final String? hint;
  final Validation<String> Function(String) parse;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _ctl = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _submit() {
    switch (widget.parse(_ctl.text)) {
      case Ok(:final value):
        Navigator.of(context).pop(value);
      case Invalid(:final reason):
        setState(() => _error = reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return AlertDialog(
      backgroundColor: c.surface,
      title: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
      content: OzoneTextField(
        label: widget.label,
        controller: _ctl,
        hint: widget.hint,
        error: _error,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() => _error = null),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: TextStyle(color: c.ink, fontWeight: FontWeight.w800))),
        TextButton(onPressed: _submit, child: Text(widget.action, style: TextStyle(color: notesAccent(context), fontWeight: FontWeight.w800))),
      ],
    );
  }
}

/// "New folder" with the F1-01 name rules. Returns the new folder's ID.
Future<String?> newFolder(BuildContext context, WidgetRef ref) async {
  final names = [for (final f in ref.read(notesDataProvider).value?.folders ?? const <FolderRow>[]) f.name];
  final name = await promptName(context, title: 'New folder', label: 'Name', action: 'Create', parse: (s) => parseFolderName(s, names));
  if (name == null) return null;
  return ref.read(notesRepoProvider).addFolder(name);
}

/// Sheet chrome shared by the note sheets: handle, title, optional subtitle.
class _SheetHead extends StatelessWidget {
  const _SheetHead({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.outline, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: Space.m),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleMedium!.copyWith(fontSize: 18, fontWeight: FontWeight.w800))),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
          ],
        ]),
      ),
      const SizedBox(height: Space.s),
    ]);
  }
}

/// One 56 dp row of a note sheet: icon, label (and a second line), value.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.detail, this.value, this.onTap, this.danger = false, this.iconColor});
  final IconData icon;
  final String label;
  final String? detail;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final fg = danger ? c.danger : c.ink;
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              Icon(icon, size: 22, color: iconColor ?? fg),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: text.bodyLarge!.copyWith(fontSize: 15.5, fontWeight: danger ? FontWeight.w800 : FontWeight.w700, color: fg)),
                  if (detail != null) ...[
                    const SizedBox(height: 3),
                    Text(detail!, style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
                  ],
                ]),
              ),
              if (value != null) ...[
                const SizedBox(width: Space.s),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
                  child: Text('$value ›',
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: text.bodyMedium!.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: c.inkMuted)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

Future<T?> _sheet<T>(BuildContext context, Widget child) => showOzoneSheet<T>(
      context,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 10, 12, 20), child: child),
      ),
    );

/// What the note menu asks the editor to do.
enum NoteMenuResult { trash }

/// W3 · Note menu sheet: pin, folder, tags, lock, move to trash.
Future<NoteMenuResult?> showNoteMenu(BuildContext context, String noteId) => _sheet(context, _NoteMenu(noteId: noteId));

class _NoteMenu extends ConsumerWidget {
  const _NoteMenu({required this.noteId});
  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final data = ref.watch(notesDataProvider).value;
    final n = data?.byId(noteId);
    if (data == null || n == null) return const SizedBox(height: 120);
    final repo = ref.read(notesRepoProvider);
    final tags = data.tagsOf(n.id);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      _SheetHead(
        title: n.title ?? 'Untitled',
        subtitle: 'Created ${localDateOf(n.createdAt).format(ref.watch(todayProvider))} · edited ${dateTimeText(n.editedAt)}',
      ),
      _MenuRow(
        icon: n.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
        iconColor: notesAccent(context),
        label: n.isPinned ? 'Unpin' : 'Pin to top',
        onTap: () => repo.setPinned(n.id, !n.isPinned),
      ),
      _MenuRow(
        icon: Icons.folder_outlined,
        label: 'Move to folder',
        value: data.folder(n.folderId)?.name ?? 'Unfiled',
        onTap: () => showFolderPicker(context, n.id),
      ),
      _MenuRow(
        icon: Icons.tag_rounded,
        label: 'Tags',
        value: tags.isEmpty ? 'None' : tags.map((t) => '#${t.name}').join(' '),
        onTap: () => showTagsSheet(context, n.id),
      ),
      const _MenuRow(
        icon: Icons.lock_outline_rounded,
        label: 'Lock note',
        detail: 'Moves it into the vault. Locked notes aren\'t searched. The vault arrives in M6.',
      ),
      Divider(height: 9, indent: 10, endIndent: 10, color: c.surfaceSunken),
      _MenuRow(
        icon: Icons.delete_outline_rounded,
        label: 'Move to trash',
        detail: 'Kept for 30 days, then deleted',
        danger: true,
        onTap: () => Navigator.of(context).pop(NoteMenuResult.trash),
      ),
      const SizedBox(height: Space.s),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: OzoneButton(label: 'Close', primary: false, height: 48, onPressed: () => Navigator.of(context).pop()),
      ),
    ]);
  }
}

/// Move to folder: Unfiled, every folder, and "New folder" (F2-02 §4).
Future<void> showFolderPicker(BuildContext context, String noteId) => _sheet(context, _FolderPicker(noteId: noteId));

class _FolderPicker extends ConsumerWidget {
  const _FolderPicker({required this.noteId});
  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(notesDataProvider).value;
    final n = data?.byId(noteId);
    if (data == null || n == null) return const SizedBox(height: 120);
    final repo = ref.read(notesRepoProvider);
    Future<void> pick(String? id) async {
      await repo.moveToFolder(noteId, id);
      if (context.mounted) Navigator.of(context).pop();
    }

    Widget row(String? id, String name) => _MenuRow(
          icon: n.folderId == id ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
          iconColor: n.folderId == id ? notesAccent(context) : null,
          label: name,
          onTap: () => pick(id),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      const _SheetHead(title: 'Move to folder'),
      row(null, 'Unfiled'),
      for (final f in data.folders) row(f.id, f.name),
      const SizedBox(height: Space.s),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: OzoneButton(
          label: 'New folder',
          color: notesAccent(context),
          foreground: OzoneThemeColors.of(context).onAccent,
          height: 48,
          onPressed: () async {
            final id = await newFolder(context, ref);
            if (id != null) await pick(id);
          },
        ),
      ),
    ]);
  }
}

/// Tags: pick existing ones or type a new one (F1-01 tag rules).
Future<void> showTagsSheet(BuildContext context, String noteId) => _sheet(context, _TagsSheet(noteId: noteId));

class _TagsSheet extends ConsumerStatefulWidget {
  const _TagsSheet({required this.noteId});
  final String noteId;

  @override
  ConsumerState<_TagsSheet> createState() => _TagsSheetState();
}

class _TagsSheetState extends ConsumerState<_TagsSheet> {
  final _ctl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _add(NotesData data) async {
    switch (parseTag(_ctl.text)) {
      case Invalid(:final reason):
        setState(() => _error = reason);
      case Ok(:final value):
        final repo = ref.read(notesRepoProvider);
        final id = await repo.ensureTag(value);
        await repo.setTags(widget.noteId, {...data.tagsOf(widget.noteId).map((t) => t.id), id});
        _ctl.clear();
        setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final data = ref.watch(notesDataProvider).value;
    if (data == null || data.byId(widget.noteId) == null) return const SizedBox(height: 120);
    final mine = {for (final t in data.tagsOf(widget.noteId)) t.id};
    final repo = ref.read(notesRepoProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      const _SheetHead(title: 'Tags'),
      if (data.tags.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Wrap(spacing: Space.s, runSpacing: Space.s, children: [
            for (final t in data.tags)
              FilterChip(
                label: Text('#${t.name}'),
                selected: mine.contains(t.id),
                showCheckmark: false,
                onSelected: (on) => repo.setTags(widget.noteId, on ? {...mine, t.id} : (mine.toSet()..remove(t.id))),
                labelStyle: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: mine.contains(t.id) ? c.onAccent : notesAccent(context)),
                backgroundColor: notesTile(context),
                selectedColor: notesAccent(context),
                side: BorderSide.none,
                shape: const StadiumBorder(),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
          ]),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('No tags yet. Type one below.', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
        ),
      const SizedBox(height: Space.l),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: OzoneTextField(
              label: 'New tag',
              hint: 'e.g. travel',
              prefix: '#',
              controller: _ctl,
              error: _error,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          const SizedBox(width: Space.s),
          Padding(
            padding: EdgeInsets.only(bottom: _error == null ? 0 : 28),
            child: SizedBox(width: 88, child: OzoneButton(label: 'Add', color: notesAccent(context), foreground: c.onAccent, onPressed: () => _add(data))),
          ),
        ]),
      ),
      const SizedBox(height: Space.l),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: OzoneButton(label: 'Done', primary: false, height: 48, onPressed: () => Navigator.of(context).pop()),
      ),
    ]);
  }
}

/// Trash a note with "Moved to trash · Undo" (F2-02 §5).
Future<void> trashWithUndo(WidgetRef ref, NoteRow n) async {
  final repo = ref.read(notesRepoProvider);
  final undo = ref.read(undoControllerProvider);
  await repo.trash(n.id);
  await undo.run(
    message: '${n.title ?? 'Note'} moved to trash',
    hideNow: () {},
    commit: () async {},
    restore: () => repo.restore(n.id),
  );
}
