import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/library.dart';
import '../state/library_providers.dart';
import 'library_home.dart';
import 'library_parts.dart';

/// Book detail (W3 · Book detail): status and rating change in place; Edit
/// opens the form; the menu deletes with Undo.
class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final data = ref.watch(booksDataProvider).value;
    final b = data?.byId(bookId);
    if (b == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(children: [
            const DetailTopBar(title: 'Book', overline: 'Library'),
            if (data != null) Padding(padding: const EdgeInsets.all(Space.xl), child: Text('This book no longer exists.', style: text.bodyLarge)),
          ]),
        ),
      );
    }
    final repo = ref.read(booksRepoProvider);
    final acq = Acquisition.of(b.acquisition);

    Future<void> delete() async {
      final undo = ref.read(undoControllerProvider);
      Navigator.of(context).pop();
      final row = await repo.delete(b.id);
      await undo.run(
        message: '${row.title} deleted',
        hideNow: () {},
        commit: () => repo.recordDeleted(row.id),
        restore: () => unawaited(repo.restore(row)),
      );
    }

    Widget fact(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 13),
          child: Row(children: [
            Text(label, style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.inkMuted)),
            const SizedBox(width: Space.m),
            Expanded(child: Text(value, textAlign: TextAlign.right, style: text.bodyLarge!.copyWith(fontWeight: strong ? FontWeight.w800 : FontWeight.w700))),
          ]),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            DetailTopBar(title: 'Book', overline: 'Library', trailing: [
              FilledButton(
                onPressed: () => context.push('/library/books/${b.id}/edit'),
                style: FilledButton.styleFrom(
                  backgroundColor: c.surfaceSunken,
                  foregroundColor: c.ink,
                  minimumSize: const Size(48, 40),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              PopupMenuButton<int>(
                tooltip: 'Book options',
                icon: Icon(Icons.more_vert_rounded, color: c.ink),
                color: c.surface,
                onSelected: (_) => delete(),
                itemBuilder: (_) => [PopupMenuItem(value: 0, child: Text('Delete', style: TextStyle(color: c.danger)))],
              ),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const BookTile(large: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: Space.xs),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Semantics(header: true, child: Text(b.title, style: text.headlineSmall!.copyWith(height: 1.2))),
                          if (b.author != null) ...[
                            const SizedBox(height: Space.xs),
                            Text(b.author!, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
                          ],
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: Space.m),
                Container(
                  padding: const EdgeInsets.fromLTRB(Space.l, 14, Space.l, Space.s),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Status', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted)),
                    const SizedBox(height: 10),
                    LibraryChoice<BookStatus>(
                      label: 'Status',
                      grid: true,
                      options: [for (final s in BookStatus.values) (s, s.label)],
                      selected: BookStatus.of(b.status),
                      onSelected: (s) => repo.setStatus(b.id, s),
                    ),
                    const SizedBox(height: Space.m),
                    Divider(height: 1, color: c.surfaceSunken),
                    const SizedBox(height: 10),
                    Text('Rating', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted)),
                    const SizedBox(height: Space.xs),
                    RatingStepper(half: b.ratingHalf, onChanged: (v) => repo.setRating(b.id, v)),
                  ]),
                ),
                const SizedBox(height: Space.m),
                GroupCard(children: [
                  fact('On Kindle', b.onKindle ? (b.sizeKb == null ? 'Yes · no size' : 'Yes · ${formatStorage(b.sizeKb!)}') : 'No'),
                  fact('Acquired', '${acq.label} · ${acquiredText(b.acquiredDate, today)}'),
                  if (acq == Acquisition.purchased && b.amount != null) fact('Amount', money(context, b.amount!), strong: true),
                  if (b.remarks != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Remarks', style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.inkMuted)),
                        const SizedBox(height: Space.xs),
                        Text(b.remarks!, style: text.bodyLarge!.copyWith(fontSize: 14.5, height: 1.5)),
                      ]),
                    ),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
