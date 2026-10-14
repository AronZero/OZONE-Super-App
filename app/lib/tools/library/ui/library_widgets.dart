import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/library.dart';
import '../state/library_providers.dart';
import 'library_parts.dart';

/// Home widget W7 · Currently reading (W1 · Home): up to 3 books being read.
class CurrentlyReadingWidget extends ConsumerWidget {
  const CurrentlyReadingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final reading = [...?ref.watch(booksDataProvider).value?.rows.where((b) => b.status == BookStatus.reading.key)]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Container(
      decoration: BoxDecoration(color: libraryTile(context), borderRadius: BorderRadius.circular(Radii.card)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: () => context.go('/library?status=reading'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, Space.l, Space.m, Space.s),
            child: Row(children: [
              Expanded(child: Text('Currently reading', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800))),
              Text(reading.isEmpty ? '' : '${reading.length} ${reading.length == 1 ? 'book' : 'books'}',
                  style: text.bodyMedium!.copyWith(color: c.inkMuted)),
              Icon(Icons.chevron_right_rounded, color: c.inkMuted),
            ]),
          ),
        ),
        if (reading.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, Space.l),
            child: Text('Nothing being read. Set a book to Reading to see it here.', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
          )
        else ...[
          for (final b in reading.take(3))
            InkWell(
              onTap: () {
                context.go('/library');
                context.push('/library/books/${b.id}');
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, Space.s, 18, Space.s),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: b.title, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                    if (b.author != null) TextSpan(text: ' · ${b.author}', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          const SizedBox(height: Space.s),
        ],
      ]),
    );
  }
}

/// Home widget W8 · Library snapshot (off by default). Opens Library stats.
class LibrarySnapshotWidget extends ConsumerWidget {
  const LibrarySnapshotWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final s = ref.watch(booksDataProvider).value?.stats;
    Widget fig(String value, String label) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: text.titleMedium!.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: text.bodyMedium!.copyWith(color: c.inkMuted)),
          ]),
        );
    return Semantics(
      button: true,
      child: Material(
        color: libraryTile(context),
        borderRadius: BorderRadius.circular(Radii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.card),
          onTap: () {
            context.go('/library');
            context.push('/library/stats');
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, Space.l, 18, Space.l),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Library snapshot', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: Space.s),
              if (s == null || s.total == 0)
                Text('No books yet.', style: text.bodyLarge!.copyWith(color: c.inkMuted))
              else
                Row(children: [
                  fig('${s.total}', s.total == 1 ? 'book' : 'books'),
                  fig('${s.byStatus[BookStatus.finished]}', 'finished'),
                  fig(formatStorage(s.kindleKb), 'on Kindle'),
                ]),
            ]),
          ),
        ),
      ),
    );
  }
}
