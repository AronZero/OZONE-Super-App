import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/money.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/charts/month_bars.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/library.dart';
import '../state/library_providers.dart';
import 'library_parts.dart';

/// Library stats (W2 · Library stats, F1-04 §6).
class LibraryStatsScreen extends ConsumerStatefulWidget {
  const LibraryStatsScreen({super.key});

  @override
  ConsumerState<LibraryStatsScreen> createState() => _LibraryStatsScreenState();
}

class _LibraryStatsScreenState extends ConsumerState<LibraryStatsScreen> {
  BookStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final data = ref.watch(booksDataProvider).value;
    final s = data?.stats;
    final perYear = booksPerYear(data?.facts ?? const [], today, status: _filter);

    Widget tile(String label, String value, String note, {bool tinted = false, Color? valueColor}) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, Space.m, 14, Space.m),
            decoration: BoxDecoration(color: tinted ? libraryTile(context) : c.surface, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: text.labelLarge!.copyWith(fontWeight: FontWeight.w800, color: tinted ? libraryAccent(context) : c.inkMuted)),
              const SizedBox(height: 2),
              Text(value, style: text.headlineSmall!.copyWith(fontSize: 22, color: valueColor)),
              Text(note, style: text.labelLarge!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
            ]),
          ),
        );

    final statusOrder = [BookStatus.finished, BookStatus.notStarted, BookStatus.abandoned, BookStatus.reading];
    final statusColors = {
      BookStatus.finished: libraryAccent(context),
      BookStatus.notStarted: libraryAccent(context).withValues(alpha: 0.45),
      BookStatus.abandoned: c.outline,
      BookStatus.reading: c.inkMuted,
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            const DetailTopBar(title: 'Library stats', overline: 'Library'),
            if (s != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    tile(
                      'Kindle storage',
                      formatStorage(s.kindleKb),
                      '${s.onKindle} ${s.onKindle == 1 ? 'book' : 'books'} on Kindle'
                          '${s.kindleNoSize == 0 ? '' : ' · ${s.kindleNoSize} ${s.kindleNoSize == 1 ? 'has' : 'have'} no size'}',
                      tinted: true,
                    ),
                    const SizedBox(width: 10),
                    tile('Spent on books', money(context, s.spent), '${s.purchased} purchased', tinted: true),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    tile(
                      'Finished',
                      '${s.byStatus[BookStatus.finished]} of ${s.total}',
                      s.total == 0 ? 'No books yet' : '${Money.percent(s.byStatus[BookStatus.finished]!, s.total)} of the library',
                    ),
                    const SizedBox(width: 10),
                    tile(
                      'Average rating',
                      s.averageRating == null ? '—' : '★ ${s.averageRating}',
                      '${s.rated} rated · ${s.notRated} not rated',
                      valueColor: libraryAccent(context),
                    ),
                  ]),
                  const SizedBox(height: Space.m),
                  Container(
                    padding: const EdgeInsets.fromLTRB(Space.l, 14, Space.l, 14),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text('Books per year', style: text.titleMedium!.copyWith(fontSize: 15, fontWeight: FontWeight.w800))),
                        Text('by acquired date', style: text.labelLarge!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
                      ]),
                      const SizedBox(height: 10),
                      LibraryChoice<BookStatus?>(
                        label: 'Status filter',
                        options: [(null, 'All'), for (final st in BookStatus.values) (st, st.label)],
                        selected: _filter,
                        onSelected: (v) => setState(() => _filter = v),
                      ),
                      const SizedBox(height: Space.m),
                      MonthBars(
                        data: [for (final (y, n) in perYear.years) BarDatum('$y', n, highlight: y == today.year)],
                        valueLabels: [for (final (_, n) in perYear.years) '$n'],
                        labelEvery: 1,
                        height: 120,
                        accent: libraryAccent(context),
                        labelColor: c.inkMuted,
                        semanticLabel: 'Books acquired per year, ${_filter?.label ?? 'all'}: '
                            '${perYear.years.map((e) => '${e.$1} ${e.$2}').join(', ')}.',
                      ),
                      if (perYear.noDate > 0) ...[
                        const SizedBox(height: Space.s),
                        Text('${perYear.noDate} ${perYear.noDate == 1 ? 'book has' : 'books have'} no acquired date and ${perYear.noDate == 1 ? 'isn’t' : 'aren’t'} shown.',
                            style: text.labelLarge!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
                      ],
                    ]),
                  ),
                  const SizedBox(height: Space.m),
                  Container(
                    padding: const EdgeInsets.fromLTRB(Space.l, 14, Space.l, 14),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('By status', style: text.titleMedium!.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      if (s.total > 0)
                        ExcludeSemantics(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: SizedBox(
                              height: 14,
                              child: Row(children: [
                                for (final st in statusOrder)
                                  if (s.byStatus[st]! > 0)
                                    Expanded(
                                      flex: s.byStatus[st]!,
                                      child: Container(margin: const EdgeInsets.only(right: 2), color: statusColors[st]),
                                    ),
                              ]),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Wrap(spacing: 14, runSpacing: 6, children: [
                        for (final st in statusOrder)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: statusColors[st], borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(width: Space.s),
                            Text('${st.label} · ${s.byStatus[st]}', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700)),
                          ]),
                      ]),
                      const SizedBox(height: 10),
                      Text(
                        'How books were acquired: ${Acquisition.values.map((a) => '${a.label} ${s.byAcquisition[a]}').join(' · ')}',
                        style: text.bodyMedium!.copyWith(fontSize: 12.5, color: c.inkMuted),
                      ),
                    ]),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
