import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/dates.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/charts/month_bars.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/expenses.dart';
import '../state/finance_providers.dart';
import 'savings_parts.dart';

/// Spending by year (W2 · Spending by year): the current year and the 4
/// before it, as a chart or a table, then this year by month. Refunded
/// expenses aren't counted (F1-04 §5).
class SpendingYearScreen extends ConsumerStatefulWidget {
  const SpendingYearScreen({super.key});

  @override
  ConsumerState<SpendingYearScreen> createState() => _SpendingYearScreenState();
}

class _SpendingYearScreenState extends ConsumerState<SpendingYearScreen> {
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final spends = ref.watch(expensesDataProvider).value?.spends ?? const <Spend>[];
    final years = spendingByYear(spends, today);
    final ytd = yearToDate(spends, today.year, today);
    final months = monthlyTotals(spends, today.year, today);
    final head = text.labelSmall!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted);

    String vsPrior(int i) {
      if (i == 0) return '—';
      final cur = years[i], prev = years[i - 1];
      final base = cur.soFar ? ytd.lastYear : prev.total;
      final now = cur.soFar ? ytd.thisYear : cur.total;
      if (base == 0) return '—';
      final tenths = (((now - base) * 1000) / base).round();
      return '${tenths > 0 ? '▲ ' : tenths < 0 ? '▼ ' : ''}${percentTenths(tenths)}${cur.soFar ? ' YTD' : ''}';
    }

    final tenths = ytd.changeTenths;
    final summary = tenths == null
        ? '${today.year} so far is ${money(context, ytd.thisYear)}. Refunded items aren’t counted.'
        : '${today.year} so far is ${money(context, ytd.thisYear)}, ${percentTenths(tenths.abs()).replaceFirst('+', '')} '
            '${tenths < 0 ? 'less' : 'more'} than the same period of ${today.year - 1} (${money(context, ytd.lastYear)}). Refunded items aren’t counted.';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            const DetailTopBar(title: 'Spending by year', overline: 'Expenses'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SegmentTabs(labels: const ['Chart', 'Table'], selected: _table ? 1 : 0, onSelected: (i) => setState(() => _table = i == 1)),
                const SizedBox(height: Space.m),
                if (years.length == 1) ...[
                  Text('Comparisons start once you have two years of expenses. So far you have ${years.single.year} only.',
                      style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                  const SizedBox(height: Space.m),
                ],
                if (years.isEmpty)
                  Text('No expenses yet.', style: text.bodyLarge)
                else if (!_table)
                  Container(
                    padding: const EdgeInsets.all(Space.l),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      MonthBars(
                        data: [for (final y in years) BarDatum(y.soFar ? '${y.year}*' : '${y.year}', y.total, highlight: y.soFar)],
                        valueLabels: [for (final y in years) moneyCompact(context, y.total)],
                        labelEvery: 1,
                        height: 150,
                        accent: financeAccent(context),
                        labelColor: c.inkMuted,
                        semanticLabel: 'Yearly spending: ${years.map((y) => '${y.year}${y.soFar ? ' so far' : ''} ${money(context, y.total)}').join('; ')}.',
                      ),
                      const SizedBox(height: Space.s),
                      Text('* ${today.year} so far (to ${today.format(today)})', style: text.labelSmall!.copyWith(color: c.inkMuted)),
                    ]),
                  )
                else
                  Material(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(Radii.card),
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      _row(context, Text('Year', style: head), Text('Spent', style: head), Text('vs prior', style: head), header: true),
                      for (var i = years.length - 1; i >= 0; i--)
                        _row(
                          context,
                          Text(years[i].soFar ? '${years[i].year}*' : '${years[i].year}', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                          Text(money(context, years[i].total), semanticsLabel: spokenAmounts(money(context, years[i].total)), style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                          Text(vsPrior(i), style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted)),
                        ),
                    ]),
                  ),
                const SizedBox(height: Space.m),
                Text(summary, semanticsLabel: spokenAmounts(summary), style: text.bodyLarge!.copyWith(fontSize: 14, height: 1.5)),
                const SizedBox(height: Space.m),
                Container(
                  padding: const EdgeInsets.all(Space.l),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${today.year} by month', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: Space.m),
                    MonthBars(
                      data: [
                        for (var m = 0; m < 12; m++)
                          BarDatum(LocalDate(today.year, m + 1, 1).monthShort, months[m], highlight: m + 1 == today.month),
                      ],
                      height: 110,
                      accent: financeAccent(context),
                      labelColor: c.inkMuted,
                      semanticLabel: '${today.year} spending by month: '
                          '${[for (var m = 0; m < 12; m++) if (months[m] != null) '${LocalDate(today.year, m + 1, 1).monthName} ${money(context, months[m]!)}'].join('; ')}.',
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

  Widget _row(BuildContext context, Widget a, Widget b, Widget d, {bool header = false}) {
    final c = OzoneThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 12),
      decoration: BoxDecoration(
        color: header ? Color.alphaBlend(c.surfaceSunken.withValues(alpha: 0.35), c.surface) : null,
        border: header ? null : Border(top: BorderSide(color: c.surfaceSunken.withValues(alpha: 0.7))),
      ),
      child: Row(children: [
        SizedBox(width: 64, child: a),
        Expanded(child: b),
        SizedBox(width: 110, child: Align(alignment: Alignment.centerRight, child: d)),
      ]),
    );
  }
}
