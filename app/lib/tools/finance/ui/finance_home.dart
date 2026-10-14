import 'package:flutter/material.dart';

import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import 'savings_overview.dart';
import 'savings_parts.dart';

/// Finance (W1 · Savings): top tabs Savings · Gold · Expenses (docs/02).
/// Gold and Expenses arrive in M3.
class FinanceHome extends StatefulWidget {
  const FinanceHome({super.key});

  @override
  State<FinanceHome> createState() => _FinanceHomeState();
}

class _FinanceHomeState extends State<FinanceHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MainTopBar(title: 'Finance', actions: [
            RoundIconButton(icon: Icons.search_rounded, label: 'Search (arrives in M7)', onPressed: null),
          ]),
          _FinanceTabs(selected: _tab, onSelected: (i) => setState(() => _tab = i)),
          Expanded(
            child: switch (_tab) {
              0 => const SavingsOverview(),
              1 => const _Later('Gold holdings, items and karat prices arrive in the next milestone.'),
              _ => const _Later('Expenses and spending by year arrive in the next milestone.'),
            },
          ),
        ],
      ),
    );
  }
}

class _FinanceTabs extends StatelessWidget {
  const _FinanceTabs({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(Space.screen, 2, Space.screen, Space.m),
      padding: const EdgeInsets.all(Space.xs),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          for (final (i, name) in const [(0, 'Savings'), (1, 'Gold'), (2, 'Expenses')])
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                label: '$name tab',
                excludeSemantics: true,
                child: Material(
                  color: i == selected ? financeTile(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onSelected(i),
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(name,
                            style: text.bodyMedium!.copyWith(
                              fontSize: 14,
                              fontWeight: i == selected ? FontWeight.w800 : FontWeight.w700,
                              color: i == selected ? financeAccent(context) : c.inkMuted,
                            )),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Later extends StatelessWidget {
  const _Later(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: Space.screen),
        children: [
          Container(
            padding: const EdgeInsets.all(Space.xl),
            decoration: BoxDecoration(color: financeTile(context), borderRadius: BorderRadius.circular(Radii.card)),
            child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      );
}
