import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/today.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/components/states.dart';
import '../../../core/ui/charts/month_bars.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/savings_history.dart';
import '../state/savings_providers.dart';
import 'account_sheet.dart';
import 'savings_parts.dart';

/// Savings tab (W1 · Savings): total card with the 12-month chart, then
/// open accounts sorted by balance (decision M2-4), and the Add account button.
class SavingsOverview extends ConsumerWidget {
  const SavingsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(savingsDataProvider);
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);

    return Stack(
      children: [
        AsyncBody(
          value: data,
          what: 'Savings',
          onRetry: () => ref.invalidate(savingsDataProvider),
          builder: (d) {
            final open = [...d.open]..sort((a, b) => (b.latest?.balance ?? 0).compareTo(a.latest?.balance ?? 0));
            if (open.isEmpty) return _Empty(hasArchived: d.archived.isNotEmpty);
            final month = monthTotal(d.histories, today, today);
            final months = lastTwelveMonths(d.histories, today);
            return ListView(
              padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, 104),
              children: [
                _TotalCard(month: month, months: months),
                const SizedBox(height: Space.l),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                  child: Row(children: [
                    Expanded(child: Semantics(header: true, child: Text('Accounts', style: text.titleMedium!.copyWith(fontSize: 15, fontWeight: FontWeight.w800)))),
                    Text('Sorted by balance', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                  ]),
                ),
                const SizedBox(height: Space.s),
                for (final a in open) ...[
                  _AccountRow(history: a, platform: d.account(a.id)?.platform),
                  const SizedBox(height: Space.s),
                ],
              ],
            );
          },
        ),
        Positioned(
          right: Space.screen,
          bottom: Space.screen,
          child: FinanceAddButton(label: 'Add account', onPressed: () => showAccountSheet(context)),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.month, required this.months});
  final MonthTotal month;
  final List<MonthTotal> months;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final accent = financeAccent(context);
    final prev = month.month.addMonths(-1);
    return Consumer(builder: (context, ref, _) {
      final now = ref.watch(todayProvider);
      return Container(
        padding: const EdgeInsets.fromLTRB(18, Space.l, 18, Space.l),
        decoration: BoxDecoration(color: financeTile(context), borderRadius: BorderRadius.circular(Radii.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('Total savings', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800))),
              Text('As of ${now.formatLong()}', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
            ]),
            const SizedBox(height: Space.s),
            Semantics(
              label: moneySpoken(context, month.total ?? 0), // the heading above already says "Total savings"
              excludeSemantics: true,
              child: Text(money(context, month.total ?? 0), semanticsLabel: spokenAmounts(money(context, month.total ?? 0)), style: text.displaySmall!.copyWith(fontSize: 32, letterSpacing: -0.6)),
            ),
            const SizedBox(height: Space.s),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (month.countedAccounts > 0) ChangePill(amount: month.change, suffix: ' vs ${prev.monthShort}'),
                Text(accountsLine(month), style: text.bodyMedium!.copyWith(color: c.inkMuted)),
              ],
            ),
            if (month.newAccountsNote != null) ...[
              const SizedBox(height: Space.xs),
              Text(month.newAccountsNote!, style: text.labelSmall!.copyWith(color: c.inkMuted)),
            ],
            const SizedBox(height: Space.m),
            MonthBars(
              data: totalsToBars(months, now),
              accent: accent,
              labelColor: c.inkMuted,
              semanticLabel: totalsChartLabel(context, months),
            ),
            const SizedBox(height: Space.s),
            Row(children: [
              Expanded(
                child: _PillButton(
                  label: 'Update balances',
                  bg: accent,
                  fg: c.onAccent,
                  onTap: () => context.push('/finance/savings/update'),
                ),
              ),
              const SizedBox(width: Space.s),
              _PillButton(label: 'History', bg: c.surface, fg: c.ink, onTap: () => context.push('/finance/savings/history')),
            ]),
          ],
        ),
      );
    });
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.bg, required this.fg, required this.onTap});
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: bg,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            alignment: Alignment.center,
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w800, color: fg)),
          ),
        ),
      );
}

class _AccountRow extends ConsumerWidget {
  const _AccountRow({required this.history, this.platform});
  final AccountHistory history;
  final String? platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final mb = monthBalance(history, today, today);
    final last = history.latest!;
    final carried = mb.status == MonthStatus.carried;
    final date = last.date.format(today);
    final sub = [?platform, date].join(' · ');
    return Semantics(
      button: true,
      label: '${history.name}, ${moneySpoken(context, last.balance)}, ${carried ? 'carried from $date' : 'updated $date'}',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/finance/savings/accounts/${history.id}'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                AccountTile(history.name),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(history.name, style: text.bodyLarge!.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    if (carried) DashedPill('Carried · $date') else Text(sub, style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                  ]),
                ),
                const SizedBox(width: Space.s),
                Text(money(context, last.balance), semanticsLabel: spokenAmounts(money(context, last.balance)), style: text.bodyLarge!.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasArchived});
  final bool hasArchived;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Space.screen),
      children: [
        Container(
          padding: const EdgeInsets.all(Space.xl),
          decoration: BoxDecoration(color: financeTile(context), borderRadius: BorderRadius.circular(Radii.card)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('No savings accounts yet', style: text.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: Space.xs),
            Text('Add an account with its current balance. Update the balances once a month to see your savings grow.',
                style: text.bodyLarge!.copyWith(color: c.inkMuted)),
          ]),
        ),
        if (hasArchived)
          Padding(
            padding: const EdgeInsets.only(top: Space.m),
            child: TextButton(
              onPressed: () => context.push('/finance/savings/archived'),
              child: Text('See archived accounts', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800, color: c.ink)),
            ),
          ),
      ],
    );
  }
}
