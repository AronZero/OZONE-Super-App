import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database.dart';
import '../../../core/domain/dates.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/notes.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/motion.dart';

/// Notes accent and tile for the current theme (docs/05 tool tints).
Color notesAccent(BuildContext context) => ToolTint.notes.accentOf(context);
Color notesTile(BuildContext context) => ToolTint.notes.tileOf(context);
Color notesCard(BuildContext context) => ToolTint.notes.cardOf(context);

/// A stored timestamp (UTC ms) as the phone's local date.
LocalDate localDateOf(int ms) => LocalDate.fromDateTime(DateTime.fromMillisecondsSinceEpoch(ms));

/// "12 Oct 2026, 9:41 pm" (W1 · Note editor).
String dateTimeText(int ms) {
  final t = DateTime.fromMillisecondsSinceEpoch(ms);
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '${LocalDate.fromDateTime(t).formatLong()}, $h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'am' : 'pm'}';
}

/// Opens a note: the Notes tab first, so Back returns to the list.
void openNote(BuildContext context, String id, {bool fromOtherTab = false}) {
  if (fromOtherTab) context.go('/notes');
  context.push('/notes/n/$id');
}

/// `#travel` in the Notes tint.
class TagChip extends StatelessWidget {
  const TagChip(this.name, {super.key, this.small = false});
  final String name;
  final bool small;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: small ? 3 : 7),
        decoration: BoxDecoration(color: notesTile(context), borderRadius: BorderRadius.circular(999)),
        // One line only: a long tag ends in "…" instead of wrapping.
        child: Text('#$name',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(fontSize: small ? 11 : 12.5, fontWeight: FontWeight.w800, color: notesAccent(context))),
      );
}

/// One note in the grid or list (W2 · Notes home, Components "Note cards").
class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, required this.today, this.tags = const [], this.folderName, this.list = false, required this.onTap});

  final NoteRow note;
  final LocalDate today;
  final List<TagRow> tags;

  /// Shown on locked notes ("Personal · 9 Oct").
  final String? folderName;
  final bool list;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final date = localDateOf(note.editedAt).format(today);
    final shape = BorderRadius.circular(18);

    if (note.isLocked) {
      final where = '${folderName ?? 'Unfiled'} · $date';
      return Semantics(
        button: true,
        label: spokenAmounts('Locked note in ${folderName ?? 'Unfiled'}, edited $date'),
        excludeSemantics: true,
        child: PressScale(scale: PressScale.card, child: Material(
          color: notesTile(context),
          borderRadius: shape,
          child: InkWell(
            borderRadius: shape,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: list ? 64 : 148),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: list
                    ? Row(children: [
                        Icon(OzIcons.lock, color: notesAccent(context)),
                        const SizedBox(width: Space.m),
                        Expanded(child: Text('Locked note', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800, color: notesAccent(context)))),
                        Text(where, style: text.labelSmall!.copyWith(fontWeight: FontWeight.w600, color: notesAccent(context))),
                      ])
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(OzIcons.lock, size: 26, color: notesAccent(context)),
                        const SizedBox(height: Space.s),
                        Text('Locked note', style: text.bodyLarge!.copyWith(fontSize: 15, fontWeight: FontWeight.w800, color: notesAccent(context))),
                        const SizedBox(height: Space.xs),
                        Text(where, textAlign: TextAlign.center, style: text.labelSmall!.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, color: notesAccent(context))),
                      ]),
              ),
            ),
          ),
        )),
      );
    }

    final title = note.title ?? 'Untitled';
    final preview = previewOf(note.plainText);
    final pin = note.isPinned ? Icon(OzIcons.pushPin, fill: 1, size: 16, color: notesAccent(context), semanticLabel: 'Pinned') : null;
    // Tags take the space left of the date, so the date always sits at the right edge.
    final footer = Row(children: [
      Expanded(
        child: Row(children: [
          if (tags.isNotEmpty) Flexible(child: TagChip(tags.first.name, small: true)),
          if (tags.length > 1) ...[
            const SizedBox(width: 4),
            Text('+${tags.length - 1}', style: text.labelSmall!.copyWith(fontWeight: FontWeight.w800, color: notesAccent(context))),
          ],
        ]),
      ),
      const SizedBox(width: Space.s),
      Text(date, style: text.labelSmall!.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
    ]);

    return Semantics(
      button: true,
      label: spokenAmounts('$title${note.isPinned ? ', pinned' : ''}, edited $date${tags.isEmpty ? '' : ', tags ${tags.map((t) => '#${t.name}').join(' ')}'}'),
      excludeSemantics: true,
      child: PressScale(scale: PressScale.card, child: Material(
        color: c.surface,
        borderRadius: shape,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: list ? 0 : 148),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: list ? MainAxisSize.min : MainAxisSize.max, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyLarge!.copyWith(fontSize: 15, fontWeight: FontWeight.w800, color: note.title == null ? c.inkMuted : c.ink)),
                  ),
                  if (pin != null) ...[const SizedBox(width: Space.xs), pin],
                ]),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(preview, maxLines: list ? 1 : 3, overflow: TextOverflow.ellipsis, style: text.bodyMedium!.copyWith(fontSize: 13, height: 1.45, color: c.inkMuted)),
                ],
                if (list) const SizedBox(height: Space.s) else const Spacer(),
                if (!list) const SizedBox(height: Space.s),
                footer,
              ]),
            ),
          ),
        ),
      )),
    );
  }
}

/// Two-column grid whose rows take the height of their taller card, so cards
/// grow with large text instead of overflowing (docs/04: 200% text).
class NoteGrid extends StatelessWidget {
  const NoteGrid({super.key, required this.children, this.gap = 10});
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows(children, gap: gap));

  /// One widget per row of two cards, so a long list can build only the rows on screen.
  static List<Widget> rows(List<Widget> children, {double gap = 10}) => [
        for (var i = 0; i < children.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i > 0 ? gap : 0),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: children[i]),
                SizedBox(width: gap),
                Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox.shrink()),
              ]),
            ),
          ),
      ];
}
