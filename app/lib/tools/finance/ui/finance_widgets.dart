import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/money.dart';
import '../../../core/domain/weight.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/rolling_amount.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/expenses.dart';
import '../state/finance_providers.dart';
import 'expenses_overview.dart';
import 'savings_parts.dart';
import 'savings_widgets.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/motion.dart';

/// Home widget W4 · Gold holdings (W1 · Home). Opens Gold.
class GoldHoldingsWidget extends ConsumerWidget {
  const GoldHoldingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final t = ref.watch(goldDataProvider).value?.totals;
    final has = t != null && t.items > 0;
    return FinanceWidgetTile(
      onTap: () => context.go('/finance?tab=gold'),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Gold holdings · est.', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: Space.xs),
              if (!has)
                Text('Add your gold items to see an estimate here.', style: text.bodyLarge!.copyWith(color: c.inkMuted))
              else ...[
                t.hasValue ? RollingAmount(t.value, rollOnOpen: true, style: text.headlineSmall!) : Text('No prices yet', style: text.headlineSmall),
                const SizedBox(height: Space.xs),
                Text(
                  '${Weight.format(t.weightMg)}${t.pricesAsOf == null ? '' : ' · prices ${t.pricesAsOf!.format(today)}'}',
                  style: text.bodyMedium!.copyWith(color: c.inkMuted),
                ),
              ],
            ]),
          ),
          if (has && t.hasValue && t.valuedCost > 0)
            Text('${t.gain >= 0 ? '▲' : '▼'} ${Money.percent(t.gain.abs(), t.valuedCost)}',
                semanticsLabel: '${t.gain >= 0 ? 'up' : 'down'} ${Money.percent(t.gain.abs(), t.valuedCost)}',
                style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: changeColor(c, t.gain))),
        ]),
      ],
    );
  }
}

/// Home widget W5 · Spending this year. Opens Spending by year.
class SpendingThisYearWidget extends ConsumerWidget {
  const SpendingThisYearWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final spends = ref.watch(expensesDataProvider).value?.spends ?? const <Spend>[];
    final y = yearToDate(spends, today.year, today);
    final tenths = y.changeTenths;
    return FinanceWidgetTile(
      onTap: () {
        context.go('/finance?tab=expenses');
        if (spends.isNotEmpty) context.push('/finance/expenses/years');
      },
      children: [
        Text('Spending this year', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: Space.xs),
        RollingAmount(y.thisYear, rollOnOpen: true, style: text.headlineSmall!),
        const SizedBox(height: Space.xs),
        Text(
          tenths == null ? 'Nothing to compare with last year yet' : '${percentTenths(tenths)} vs the same period in ${today.year - 1}',
          style: text.bodyMedium!.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}

/// Home widget W6 · Recent expenses (off by default): the latest 3.
class RecentExpensesWidget extends ConsumerWidget {
  const RecentExpensesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final rows = ref.watch(expensesDataProvider).value?.rows ?? const [];
    return Container(
      decoration: BoxDecoration(color: financeCard(context), borderRadius: BorderRadius.circular(Radii.card)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PressScale(scale: PressScale.card, child: InkWell(
          onTap: () => context.go('/finance?tab=expenses'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, Space.l, 18, Space.s),
            child: Row(children: [
              Expanded(child: Text('Recent expenses', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800))),
              Icon(OzIcons.chevronRight, color: c.inkMuted),
            ]),
          ),
        )),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, Space.l),
            child: Text('No expenses yet.', style: text.bodyLarge!.copyWith(color: c.inkMuted)),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s, 0, Space.s, Space.s),
            child: Material(
              color: c.onCard,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [for (final r in rows.take(3)) ExpenseRowTile(row: r, today: today)]),
            ),
          ),
      ]),
    );
  }
}
