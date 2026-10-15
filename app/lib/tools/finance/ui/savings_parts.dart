import 'package:flutter/material.dart';

import '../../../core/domain/dates.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/charts/month_bars.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/savings_history.dart';
import '../domain/savings_rules.dart';

/// Finance accent and tile for the current theme (docs/05 tool tints).
Color financeAccent(BuildContext context) => ToolTint.finance.accent(Theme.of(context).brightness);
Color financeTile(BuildContext context) => ToolTint.finance.tile(Theme.of(context).brightness);

/// The 40 dp initials tile in account rows. Archived accounts are neutral.
class AccountTile extends StatelessWidget {
  const AccountTile(this.name, {super.key, this.archived = false});
  final String name;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: archived ? c.surfaceSunken : financeTile(context),
          borderRadius: BorderRadius.circular(Radii.tile),
        ),
        child: Text(accountInitials(name),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: archived ? c.inkMuted : financeAccent(context),
                )),
      ),
    );
  }
}

/// White pill with a signed change: "▲ +₱18,420.00 vs Sep".
class ChangePill extends StatelessWidget {
  const ChangePill({super.key, required this.amount, this.suffix = ''});
  final int amount;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(999)),
      child: Text('${moneyChange(context, amount)}$suffix',
          style: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w800, color: changeColor(c, amount))),
    );
  }
}

/// Gains green, losses red, no change muted (docs/05; never colour alone: arrows too).
Color changeColor(OzoneColors c, int amount) => amount > 0 ? c.gain : (amount < 0 ? c.loss : c.inkMuted);

/// Chart bars for month totals: carried months dashed, no data as a stub.
List<BarDatum> totalsToBars(List<MonthTotal> months, LocalDate today) => [
      for (final m in months)
        BarDatum(m.month.monthShort, m.total, dashed: m.hasData && m.allCarried, highlight: m.month == monthOf(today)),
    ];

/// Spoken summary of a totals chart.
String totalsChartLabel(BuildContext context, List<MonthTotal> months, {String? scope}) {
  final withData = months.where((m) => m.hasData).toList();
  if (withData.isEmpty) return 'Month-end totals chart. No data yet.';
  final first = withData.first, last = withData.last;
  final gaps = months.length - withData.length;
  final carried = months.where((m) => m.hasData && m.allCarried).length;
  return 'Month-end totals ${scope ?? 'for the last ${months.length} months'}, from ${money(context, first.total!)} in '
      '${first.month.monthName} to ${money(context, last.total!)} in ${last.month.monthName}.'
      '${gaps > 0 ? ' $gaps ${gaps == 1 ? 'month has' : 'months have'} no data.' : ''}'
      '${carried > 0 ? ' $carried ${carried == 1 ? 'month is' : 'months are'} carried.' : ''}';
}

/// "4 accounts · 1 carried" under the total.
String accountsLine(MonthTotal t) {
  final n = t.accounts;
  final carried = t.carried == 0 ? '' : (t.allCarried ? ' · all carried' : ' · ${t.carried} carried');
  return '$n ${n == 1 ? 'account' : 'accounts'}$carried';
}

/// Rounded segmented tabs on a sunken track (W1 · Account detail, W3 · History).
class SegmentTabs extends StatelessWidget {
  const SegmentTabs({super.key, required this.labels, required this.selected, required this.onSelected});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Space.xs),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              selected: i == selected,
              button: true,
              label: labels[i],
              excludeSemantics: true,
              child: Material(
                color: i == selected ? c.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelected(i),
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium!.copyWith(
                            fontSize: 14,
                            fontWeight: i == selected ? FontWeight.w800 : FontWeight.w700,
                            color: i == selected ? c.ink : c.inkMuted,
                          )),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}


/// Up to 5 tappable suggestions that start with what's typed (F1-01 §3).
class SuggestionChips extends StatelessWidget {
  const SuggestionChips({super.key, required this.suggestions, required this.typed, required this.onPick, this.tinted = false});
  final List<String> suggestions;
  final String typed;
  final ValueChanged<String> onPick;

  /// Finance-tinted chips, as for recent vendors on W2 · Add expense.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final t = typed.trim().toLowerCase();
    final shown = [for (final s in suggestions) if (s.toLowerCase() != t && s.toLowerCase().startsWith(t)) s].take(5).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Space.s),
      child: Wrap(spacing: Space.s, runSpacing: Space.s, children: [
        for (final s in shown)
          ActionChip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            label: Text(s),
            tooltip: 'Use $s',
            backgroundColor: tinted ? financeTile(context) : c.surfaceSunken,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tinted ? financeAccent(context) : c.ink,
                ),
            onPressed: () => onPick(s),
          ),
      ]),
    );
  }
}

/// The add button of a Finance tab, in the Finance accent.
class FinanceAddButton extends StatelessWidget {
  const FinanceAddButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ToolAddButton(label: label, accent: financeAccent(context), onPressed: onPressed);
}
