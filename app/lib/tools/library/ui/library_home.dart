import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database.dart';
import '../../../core/domain/dates.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/states.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/library.dart';
import '../state/library_providers.dart';
import 'library_parts.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/shell_bar_scope.dart';

/// Library sorts (decision M4-1).
enum BookSort {
  recent('Recently acquired'),
  title('Title A–Z'),
  author('Author A–Z'),
  rating('Highest rated');

  const BookSort(this.label);
  final String label;
}

/// Library (W2 · Library): status filter, sort, list → Book detail, Add book.
/// A link can preselect the filter: `/library?status=reading` (Home widget).
class LibraryHome extends ConsumerStatefulWidget {
  const LibraryHome({super.key});

  @override
  ConsumerState<LibraryHome> createState() => _LibraryHomeState();
}

class _LibraryHomeState extends ConsumerState<LibraryHome> {
  BookStatus? _status;
  BookSort _sort = BookSort.recent;
  String? _linked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = GoRouterState.of(context).uri.queryParameters['status'];
    if (s != _linked) {
      _linked = s;
      _status = s == null || s == 'all' ? null : BookStatus.values.where((b) => b.key == s).firstOrNull;
    }
  }

  void _pick(BookStatus? s) => context.go('/library?status=${s?.key ?? 'all'}');

  static int _cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final books = ref.watch(booksDataProvider);
    final data = books.value;
    final rows = [...?data?.rows.where((b) => _status == null || b.status == _status!.key)];
    switch (_sort) {
      case BookSort.recent:
        rows.sort((a, b) {
          if (a.acquiredDate == null || b.acquiredDate == null) {
            return a.acquiredDate == b.acquiredDate ? b.createdAt.compareTo(a.createdAt) : (a.acquiredDate == null ? 1 : -1);
          }
          final d = b.acquiredDate!.compareTo(a.acquiredDate!);
          return d != 0 ? d : b.createdAt.compareTo(a.createdAt);
        });
      case BookSort.title:
        rows.sort((a, b) => _cmp(a.title, b.title));
      case BookSort.author:
        rows.sort((a, b) {
          if ((a.author == null) != (b.author == null)) return a.author == null ? 1 : -1;
          final d = _cmp(a.author ?? '', b.author ?? '');
          return d != 0 ? d : _cmp(a.title, b.title);
        });
      case BookSort.rating:
        rows.sort((a, b) {
          if ((a.ratingHalf == null) != (b.ratingHalf == null)) return a.ratingHalf == null ? 1 : -1;
          final d = (b.ratingHalf ?? 0).compareTo(a.ratingHalf ?? 0);
          return d != 0 ? d : _cmp(a.title, b.title);
        });
    }
    final stats = data?.stats;

    return Stack(children: [
      SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: shellListBottom(context)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.screen, Space.xs),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Semantics(header: true, child: Text('Library', style: text.headlineMedium)),
                    if (stats != null && stats.total > 0)
                      Text('${stats.total} ${stats.total == 1 ? 'book' : 'books'} · ${stats.onKindle} on Kindle',
                          style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                  ]),
                ),
                Material(
                  color: libraryTile(context),
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => context.push('/library/stats'),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      child: Text('Stats', style: text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800, color: libraryAccent(context))),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                RoundIconButton(icon: OzIcons.search, label: 'Search', onPressed: () => context.push('/search?scope=book')),
              ]),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(Space.screen, Space.s, Space.screen, 6),
              child: LibraryChoice<BookStatus?>(
                label: 'Filter by status',
                options: [
                  (null, 'All'),
                  for (final s in [BookStatus.reading, BookStatus.notStarted, BookStatus.finished, BookStatus.abandoned]) (s, s.label),
                ],
                selected: _status,
                onSelected: _pick,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xl, 2, Space.s, 6),
              child: Row(children: [
                Expanded(
                  child: Text(_status == null ? 'All books · ${rows.length}' : '${_status!.label} · ${rows.length}',
                      style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
                ),
                PopupMenuButton<BookSort>(
                  tooltip: 'Sort',
                  initialValue: _sort,
                  color: c.surface,
                  onSelected: (s) => setState(() => _sort = s),
                  itemBuilder: (_) => [for (final s in BookSort.values) PopupMenuItem(value: s, child: Text(s.label))],
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: Space.s),
                    alignment: Alignment.center,
                    child: Text('${_sort.label} ⇅', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
            // One list item per book, so a long library builds only the rows on screen.
            for (final w in <Widget>[
                if (data == null)
                  books.hasError
                      ? LoadError(what: 'Library', error: books.error!, stack: books.stackTrace, onRetry: () => ref.invalidate(booksDataProvider))
                      : const DelayedSkeleton()
                else if (data.rows.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(Space.xl),
                    decoration: BoxDecoration(color: libraryTile(context), borderRadius: BorderRadius.circular(Radii.card)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('No books yet', style: text.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: Space.xs),
                      Text('Add the books you own or read, with their status, rating and Kindle size.',
                          style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                    ]),
                  )
                else if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Space.l),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('No books match this filter', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: Space.xs),
                      Text('Show all books to see the rest of your library.', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                      const SizedBox(height: Space.m),
                      OzoneButton(label: 'Clear filter', primary: false, height: 48, onPressed: () => setState(() => _status = null)),
                    ]),
                  ),
                for (final b in rows) Padding(padding: const EdgeInsets.only(bottom: 6), child: BookRowTile(book: b)),
              ])
                Padding(padding: const EdgeInsets.symmetric(horizontal: Space.screen), child: w),
          ],
        ),
      ),
      ShellAddButtonSlot(child: ToolAddButton(label: 'Add book', accent: libraryAccent(context), onPressed: () => context.push('/library/add')),
      ),
    ]);
  }
}

/// One book: tile, title, author, status and rating, Kindle and acquisition.
class BookRowTile extends StatelessWidget {
  const BookRowTile({super.key, required this.book});
  final BookRow book;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final status = BookStatus.of(book.status);
    final kindle = book.onKindle ? (book.sizeKb == null ? 'On Kindle' : 'Kindle · ${formatStorage(book.sizeKb!)}') : 'Not on Kindle';
    final acq = Acquisition.of(book.acquisition).label;
    return Semantics(
      button: true,
      label: spokenAmounts('${book.title}${book.author == null ? '' : ', by ${book.author}'}, ${status.label}, ${ratingSpoken(book.ratingHalf)}, $kindle, $acq'),
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/library/books/${book.id}'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                const BookTile(),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                    if (book.author != null) ...[
                      const SizedBox(height: 2),
                      Text(book.author!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium!.copyWith(fontSize: 12.5, color: c.inkMuted)),
                    ],
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      StatusPill(status),
                      if (book.ratingHalf != null)
                        Text(ratingText(book.ratingHalf), style: text.labelLarge!.copyWith(fontWeight: FontWeight.w800, color: libraryAccent(context))),
                    ]),
                  ]),
                ),
                const SizedBox(width: Space.s),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(kindle, style: text.labelSmall!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
                  const SizedBox(height: 4),
                  Text(acq, style: text.labelSmall!.copyWith(color: c.inkMuted)),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// "18 Sep" or "18 Sep 2025"; "No date" when missing.
String acquiredText(String? iso, LocalDate today) => iso == null ? 'No date' : LocalDate.parseIso(iso).valueOrNull!.format(today);
