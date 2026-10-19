import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/notes_repo.dart';
import '../domain/notes.dart';
import '../state/notes_providers.dart';
import 'notes_parts.dart';
import 'vault/vault_unlock.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/motion.dart';

/// A locked note from Home: unlock first (UX3 board: "asks to unlock if locked").
Future<void> _openLocked(BuildContext context, WidgetRef ref, String id) async {
  if (await ensureVaultOpen(context, ref) && context.mounted) openNote(context, id, fromOtherTab: true);
}

/// The violet frame of the Notes Home widgets, with a title that opens Notes.
class _Frame extends StatelessWidget {
  const _Frame({required this.title, required this.child, this.trailing});
  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(color: notesCard(context), borderRadius: BorderRadius.circular(Radii.card)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PressScale(scale: PressScale.card, child: InkWell(
          onTap: () => context.go('/notes'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, Space.l, Space.m, Space.s),
            child: Row(children: [
              Expanded(child: Text(title, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800))),
              if (trailing != null) Text(trailing!, style: text.bodyMedium!.copyWith(color: c.inkMuted)),
              Icon(OzIcons.chevronRight, color: c.inkMuted),
            ]),
          ),
        )),
        Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: child),
      ]),
    );
  }
}

/// A small white note tile (W1 · Home "Pinned notes").
class _MiniNote extends ConsumerWidget {
  const _MiniNote(this.note);
  final NoteRow note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final locked = note.isLocked;
    return Semantics(
      button: true,
      label: spokenAmounts(locked ? 'Locked note' : (note.title ?? 'Untitled')),
      onTap: locked ? () => _openLocked(context, ref, note.id) : () => openNote(context, note.id, fromOtherTab: true),
      excludeSemantics: true,
      child: PressScale(scale: PressScale.card, child: Material(
        color: c.onCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: locked ? () => _openLocked(context, ref, note.id) : () => openNote(context, note.id, fromOtherTab: true),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.all(Space.m),
              child: locked
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(OzIcons.lock, size: 22, color: notesAccent(context)),
                      const SizedBox(height: 6),
                      Text('Locked note', style: text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800, color: notesAccent(context))),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(note.title ?? 'Untitled', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: Space.xs),
                      Text(previewOf(note.plainText), maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyMedium!.copyWith(fontSize: 12.5, height: 1.4, color: c.inkMuted)),
                    ]),
            ),
          ),
        ),
      )),
    );
  }
}

/// Home widget W9 · Pinned notes: up to 4, locked ones as "Locked note".
class PinnedNotesWidget extends ConsumerWidget {
  const PinnedNotesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final pinned = [...?ref.watch(notesDataProvider).value?.live.where((n) => n.isPinned)]..sort(NotesData.listOrder);
    return _Frame(
      title: 'Pinned notes',
      trailing: pinned.length > 4 ? '${pinned.length} pinned' : null,
      child: pinned.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
              child: Text('No pinned notes. Pin a note from its menu to keep it here.', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
            )
          : NoteGrid(gap: Space.s, children: [for (final n in pinned.take(4)) _MiniNote(n)]),
    );
  }
}

/// Home widget W10 · Recent notes (off by default): the 3 last edited.
class RecentNotesWidget extends ConsumerWidget {
  const RecentNotesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final recent = [...?ref.watch(notesDataProvider).value?.live]..sort((a, b) => b.editedAt.compareTo(a.editedAt));
    return _Frame(
      title: 'Recent notes',
      child: recent.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
              child: Text('No notes yet.', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final n in recent.take(3))
                PressScale(scale: PressScale.card, child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.tile),
                  onTap: n.isLocked ? () => _openLocked(context, ref, n.id) : () => openNote(context, n.id, fromOtherTab: true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: Space.s),
                    child: Row(children: [
                      Expanded(
                        child: Text(n.isLocked ? 'Locked note' : (n.title ?? 'Untitled'),
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700, color: n.isLocked ? notesAccent(context) : c.ink)),
                      ),
                      const SizedBox(width: Space.s),
                      Text(localDateOf(n.editedAt).format(today), style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                    ]),
                  ),
                )),
            ]),
    );
  }
}
