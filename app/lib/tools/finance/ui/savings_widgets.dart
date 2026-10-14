import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/money.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/charts/month_bars.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../state/savings_providers.dart';
import 'savings_parts.dart';

/// Home widget W2 · Total savings (W1 · Home). Opens Savings.
class TotalSavingsWidget extends ConsumerWidget {
  const TotalSavingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final t = ref.watch(savingsThisMonthProvider).value;
    final carried = t == null || t.carried == 0 ? '' : (t.allCarried ? ' · all carried' : ' · includes ${t.carried} carried');
    return FinanceWidgetTile(
      onTap: () => context.go('/finance?tab=savings'),
      semantics: t?.total == null ? 'Total savings, no accounts yet' : 'Total savings ${Money.spoken(t!.total!)}',
      children: [
        Row(children: [
          Expanded(child: Text('Total savings', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800))),
          if (t != null && t.countedAccounts > 0) ChangePill(amount: t.change, suffix: ' vs ${t.month.addMonths(-1).monthShort}'),
        ]),
        const SizedBox(height: 6),
        if (t?.total == null)
          Text('Add a savings account to see your total here.', style: text.bodyLarge!.copyWith(color: c.inkMuted))
        else ...[
          Text(Money.format(t!.total!), style: text.displaySmall!.copyWith(fontSize: 32, letterSpacing: -0.6)),
          const SizedBox(height: 6),
          Text('As of ${today.format(today)}$carried', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
        ],
      ],
    );
  }
}

/// Home widget W3 · Savings trend (12 months). Opens the History report.
class SavingsTrendWidget extends ConsumerWidget {
  const SavingsTrendWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final months = ref.watch(savingsTwelveMonthsProvider).value ?? const [];
    return FinanceWidgetTile(
      onTap: () {
        context.go('/finance?tab=savings');
        context.push('/finance/savings/history');
      },
      children: [
        Text('Savings trend · 12 months', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: Space.m),
        if (months.every((m) => !m.hasData))
          Text('No savings data yet.', style: text.bodyLarge!.copyWith(color: c.inkMuted))
        else
          MonthBars(
            data: totalsToBars(months, today),
            accent: financeAccent(context),
            labelColor: c.inkMuted,
            semanticLabel: totalsChartLabel(months),
          ),
      ],
    );
  }
}

/// A tinted, tappable Home widget card for Finance.
class FinanceWidgetTile extends StatelessWidget {
  const FinanceWidgetTile({super.key, required this.onTap, required this.children, this.semantics});
  final VoidCallback onTap;
  final List<Widget> children;
  final String? semantics;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semantics,
        child: Material(
          color: financeTile(context),
          borderRadius: BorderRadius.circular(Radii.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.card),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, Space.l, 18, Space.l),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
            ),
          ),
        ),
      );
}
