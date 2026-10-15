import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/dates.dart';
import '../../../core/domain/money.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/charts/month_bars.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/savings_history.dart';
import '../state/savings_providers.dart';
import 'savings_parts.dart';
import '../../../core/ui/theme/oz_icons.dart';

/// Savings history (W3 · History): one calendar year at a time, up to 5 years
/// (F1-04 §2), month-on-month or year-on-year, as a table or a chart.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int? _year;
  bool _yoy = false;
  bool _chart = false;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final data = ref.watch(savingsDataProvider).value;
    final all = data?.histories ?? const <AccountHistory>[];

    final firstYear = all.map((h) => h.first?.date.year).whereType<int>().fold<int>(today.year, (a, b) => b < a ? b : a);
    final minYear = firstYear < today.year - 4 ? today.year - 4 : firstYear;
    final year = (_year ?? today.year).clamp(minYear, today.year);
    final lastMonth = year == today.year ? monthOf(today) : LocalDate(year, 12, 1);
    // Months of the year down to the first one with data; earlier months
    // collapse into one "before tracking" row.
    final firstData = all.map((h) => h.first?.date).whereType<LocalDate>().fold<LocalDate?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
    final months = [
      for (var m = lastMonth; m.year == year && (firstData == null || !m.isBefore(monthOf(firstData))); m = m.addMonths(-1)) m,
    ];
    final beforeTracking = firstData != null && firstData.year == year && firstData.month > 1;
    final decBefore = LocalDate(year - 1, 12, 1);
    final yearTotal = monthTotal(all, lastMonth, today, base: decBefore);
    final baseTotal = monthTotal(all, decBefore, today);
    final archivedCount = data?.archived.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            DetailTopBar(title: 'Savings history', trailing: [
              Padding(
                padding: const EdgeInsets.only(right: Space.s),
                child: FilledButton(
                  onPressed: () => context.push('/finance/savings/archived'),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.surfaceSunken,
                    foregroundColor: c.ink,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: Space.m),
                    shape: const StadiumBorder(),
                  ),
                  child: Text('Archived · $archivedCount', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _YearCard(
                    year: year,
                    canBack: year > minYear,
                    canForward: year < today.year,
                    onYear: (y) => setState(() => _year = y),
                    yearTotal: yearTotal,
                    baseTotal: baseTotal,
                  ),
                  const SizedBox(height: Space.m),
                  Row(children: [
                    Expanded(
                      child: SegmentTabs(
                        labels: const ['vs last month', 'vs a year ago'],
                        selected: _yoy ? 1 : 0,
                        onSelected: (i) => setState(() => _yoy = i == 1),
                      ),
                    ),
                    const SizedBox(width: Space.s),
                    RoundIconButton(
                      icon: _chart ? OzIcons.tableRows : OzIcons.barChart,
                      label: _chart ? 'View as table' : 'View as chart',
                      onPressed: () => setState(() => _chart = !_chart),
                    ),
                  ]),
                  const SizedBox(height: Space.m),
                  if (_chart)
                    _YearChart(all: all, year: year)
                  else
                    _MonthTable(all: all, months: months, yoy: _yoy, beforeTracking: beforeTracking),
                  const SizedBox(height: Space.m),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                    child: Text('Changes leave out new and archived accounts. Carried months repeat the last known balance.',
                        style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.5, color: c.inkMuted)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearCard extends StatelessWidget {
  const _YearCard({
    required this.year,
    required this.canBack,
    required this.canForward,
    required this.onYear,
    required this.yearTotal,
    required this.baseTotal,
  });

  final int year;
  final bool canBack;
  final bool canForward;
  final ValueChanged<int> onYear;
  final MonthTotal yearTotal;
  final MonthTotal baseTotal;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium!.copyWith(color: c.inkMuted, fontWeight: FontWeight.w700);
    final hasBase = baseTotal.hasData;
    final end = yearTotal.total;
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 14),
      decoration: BoxDecoration(color: financeCard(context), borderRadius: BorderRadius.circular(Radii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Transform.translate(
              offset: const Offset(-8, 0),
              child: Row(children: [
                IconButton(
                  tooltip: 'Previous year',
                  onPressed: canBack ? () => onYear(year - 1) : null,
                  icon: Icon(OzIcons.chevronLeft, color: canBack ? c.ink : c.outline),
                ),
                Semantics(header: true, child: Text('$year', style: text.titleMedium!.copyWith(fontWeight: FontWeight.w800))),
                IconButton(
                  tooltip: 'Next year',
                  onPressed: canForward ? () => onYear(year + 1) : null,
                  icon: Icon(OzIcons.chevronRight, color: canForward ? c.ink : c.outline),
                ),
              ]),
            ),
            const Spacer(),
            Text('All accounts', style: muted.copyWith(fontSize: 12.5)),
          ]),
          if (!hasBase && end == null)
            Text('No data in $year', style: text.headlineSmall)
          else if (!hasBase) ...[
            Text('Total at the end of ${yearTotal.month.monthName}', style: muted),
            const SizedBox(height: 6),
            Text(money(context, end!), semanticsLabel: spokenAmounts(money(context, end)), style: text.headlineSmall!.copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            Text('Tracking started in $year, so there is no change to show yet.', style: muted.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ] else ...[
            Text('Change since 31 Dec ${year - 1}', style: muted),
            const SizedBox(height: 6),
            Text(moneyChange(context, yearTotal.change), semanticsLabel: spokenAmounts(moneyChange(context, yearTotal.change)), style: text.headlineSmall!.copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              '${money(context, baseTotal.total!)} → ${end == null ? 'no data' : money(context, end)} · '
              '${yearTotal.change >= 0 ? '+' : '−'}${Money.percent(yearTotal.change.abs(), baseTotal.total!)}', semanticsLabel: spokenAmounts('${money(context, baseTotal.total!)} → ${end == null ? 'no data' : money(context, end)} · '
              '${yearTotal.change >= 0 ? '+' : '−'}${Money.percent(yearTotal.change.abs(), baseTotal.total!)}'),
              style: muted.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthTable extends ConsumerWidget {
  const _MonthTable({required this.all, required this.months, required this.yoy, required this.beforeTracking});
  final List<AccountHistory> all;
  final List<LocalDate> months;
  final bool yoy;

  /// Adds one "No data (before tracking)" row for the year's earlier months.
  final bool beforeTracking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final head = text.labelSmall!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted);
    Widget row(Widget a, Widget b, Widget d, {bool top = true, Color? bg, double minH = 46}) => Container(
          constraints: BoxConstraints(minHeight: minH),
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 6),
          decoration: BoxDecoration(color: bg, border: top ? Border(top: BorderSide(color: c.surfaceSunken.withValues(alpha: 0.7))) : null),
          child: Row(children: [
            SizedBox(width: 48, child: a),
            const SizedBox(width: Space.s),
            Expanded(child: b),
            const SizedBox(width: Space.s),
            SizedBox(width: 122, child: Align(alignment: Alignment.centerRight, child: d)),
          ]),
        );
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        row(Text('Month', style: head), Text('Month-end total', style: head), Text(yoy ? 'vs a year ago' : 'vs last month', style: head),
            top: false, minH: 0, bg: Color.alphaBlend(c.surfaceSunken.withValues(alpha: 0.35), c.surface)),
        for (final m in months)
          () {
            final t = monthTotal(all, m, today, base: yoy ? m.addMonths(-12) : null);
            final muted = !t.hasData || t.allCarried;
            final fg = muted ? c.inkMuted : c.ink;
            final tag = t.hasData && t.recorded > 0 && m == monthOf(today) && t.carried == 0 ? 'Recorded · so far' : t.carriedLabel;
            final changeStyle = text.bodyMedium!.copyWith(fontWeight: FontWeight.w800);
            return row(
              Text(m.monthShort, style: text.bodyMedium!.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
              t.hasData
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(money(context, t.total!), semanticsLabel: spokenAmounts(money(context, t.total!)), style: text.bodyLarge!.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800, color: fg)),
                      if (tag != null) ...[const SizedBox(height: 3), DashedPill(tag)],
                    ])
                  : Text('— No data', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
              !t.hasData
                  ? Text('—', style: changeStyle.copyWith(color: c.inkMuted))
                  : t.countedAccounts == 0
                      ? Text(t.newAccounts > 0 ? 'Start' : 'Not counted', style: changeStyle.copyWith(color: c.inkMuted))
                      : Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(moneyChange(context, t.change), semanticsLabel: spokenAmounts(moneyChange(context, t.change)), style: changeStyle.copyWith(color: changeColor(c, t.change))),
                          if (t.newAccounts > 0)
                            Text('+${t.newAccounts} new, not counted', style: text.labelSmall!.copyWith(fontSize: 11, color: c.inkMuted)),
                        ]),
            );
          }(),
        if (beforeTracking)
          row(
            const SizedBox.shrink(),
            Text(
              months.last.month == 2
                  ? 'Jan: no data (before tracking)'
                  : 'Jan–${months.last.addMonths(-1).monthShort}: no data (before tracking)',
              style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted),
            ),
            Text('—', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted)),
          ),
      ]),
    );
  }
}

class _YearChart extends ConsumerWidget {
  const _YearChart({required this.all, required this.year});
  final List<AccountHistory> all;
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final totals = [
      for (var m = 1; m <= 12; m++)
        LocalDate(year, m, 1).isAfter(today)
            ? MonthTotal(month: LocalDate(year, m, 1), total: null, change: 0, recorded: 0, carried: 0, newAccounts: 0, countedAccounts: 0)
            : monthTotal(all, LocalDate(year, m, 1), today),
    ];
    return Container(
      padding: const EdgeInsets.all(Space.l),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Month-end totals · $year', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: Space.m),
        MonthBars(
          data: totalsToBars(totals, today),
          accent: financeAccent(context),
          labelColor: c.inkMuted,
          height: 160,
          semanticLabel: '${totalsChartLabel(context, totals, scope: 'in $year')} Switch to the table for every value.',
        ),
      ]),
    );
  }
}
