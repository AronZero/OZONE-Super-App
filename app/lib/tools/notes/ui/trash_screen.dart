import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/notes.dart';
import '../state/notes_providers.dart';
import 'notes_parts.dart';
import '../../../core/ui/motion.dart';

/// W3 · Trash: days left, Restore (with Undo), Delete forever and Empty trash
/// (both confirmed). Purging after 30 days runs on start and resume (F2-02 §5).
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key, this.now});

  /// Fixed "now" for tests.
  final int Function()? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final data = ref.watch(notesDataProvider).value;
    final repo = ref.read(notesRepoProvider);
    final items = data?.trashed ?? const <NoteRow>[];
    final nowMs = (now ?? () => DateTime.now().toUtc().millisecondsSinceEpoch)();

    Future<void> restore(NoteRow n) async {
      final undo = ref.read(undoControllerProvider);
      await repo.restore(n.id);
      await undo.run(
        message: n.isLocked ? 'Locked note restored' : '${n.title ?? 'Note'} restored',
        hideNow: () {},
        commit: () async {},
        restore: () => repo.trash(n.id, at: n.trashedAt),
      );
    }

    Future<void> deleteForever(NoteRow n) async {
      final ok = await confirmDialog(
        context,
        title: n.isLocked ? 'Delete this locked note forever?' : 'Delete "${n.title ?? 'Untitled'}" forever?',
        body: 'This can’t be undone.',
        confirm: 'Delete forever',
        danger: true,
      );
      if (ok == true) await repo.deleteForever(n.id);
    }

    Future<void> emptyAll() async {
      final ok = await confirmDialog(
        context,
        title: 'Empty the trash?',
        body: 'All ${items.length} ${items.length == 1 ? 'note' : 'notes'} in the trash will be deleted. This can’t be undone.',
        confirm: 'Delete forever',
        danger: true,
      );
      if (ok == true) await repo.emptyTrash();
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 104),
          children: staggered([
            DetailTopBar(title: 'Trash', overline: 'Folders & tags', trailing: [
              if (items.isNotEmpty)
                TextButton(
                  onPressed: emptyAll,
                  style: TextButton.styleFrom(foregroundColor: c.danger, minimumSize: const Size(48, 48)),
                  child: const Text('Empty trash', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, 0),
              child: AnimatedRows(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.m),
                  child: Text('Notes here are deleted for good 30 days after they were moved. They don’t show up in search.',
                      style: text.bodyMedium!.copyWith(fontSize: 14, height: 1.55, color: c.inkMuted)),
                ),
                if (data != null && items.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                    child: Column(children: [
                      Text('Trash is empty', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('Notes you delete wait here for 30 days.', textAlign: TextAlign.center, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
                    ]),
                  ),
                for (final n in items)
                  Padding(
                    key: ValueKey(n.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TrashCard(note: n, daysLeft: trashDaysLeft(n.trashedAt!, nowMs), onRestore: () => restore(n), onDelete: () => deleteForever(n)),
                  ),
              ], builder: (rows) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TrashCard extends StatelessWidget {
  const _TrashCard({required this.note, required this.daysLeft, required this.onRestore, required this.onDelete});
  final NoteRow note;
  final int daysLeft;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final locked = note.isLocked;
    final soon = daysLeft <= 3;
    final preview = locked ? 'Title and text stay hidden until you unlock' : previewOf(note.plainText);
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.l, 14, Space.l, 14),
      decoration: BoxDecoration(color: locked ? notesTile(context) : c.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(locked ? 'Locked note' : (note.title ?? 'Untitled'),
                  style: text.bodyLarge!.copyWith(fontSize: 15, fontWeight: FontWeight.w800, color: locked ? notesAccent(context) : c.ink)),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyMedium!.copyWith(fontSize: 13, height: 1.45, color: c.inkMuted)),
              ],
            ]),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: soon ? c.attentionBg : c.surfaceSunken, borderRadius: BorderRadius.circular(999)),
            child: Text('$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
                style: text.labelSmall!.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800, color: soon ? c.attentionInk : c.inkMuted)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OzoneButton(label: 'Restore', height: 44, color: notesAccent(context), foreground: c.onAccent, onPressed: onRestore)),
          const SizedBox(width: Space.s),
          Expanded(child: OzoneButton(label: 'Delete forever', height: 44, primary: false, foreground: c.danger, onPressed: onDelete)),
        ]),
      ]),
    );
  }
}
