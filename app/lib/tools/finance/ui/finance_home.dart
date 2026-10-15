import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import 'expenses_overview.dart';
import 'gold_overview.dart';
import 'savings_overview.dart';
import 'savings_parts.dart';
import '../../../core/ui/amounts.dart';

/// Finance (W1 · Savings): top tabs Savings · Gold · Expenses (docs/02).
/// The tab can be chosen by link: `/finance?tab=gold` (Home widgets use this).
class FinanceHome extends StatefulWidget {
  const FinanceHome({super.key});

  @override
  State<FinanceHome> createState() => _FinanceHomeState();
}

class _FinanceHomeState extends State<FinanceHome> {
  static const _tabs = ['savings', 'gold', 'expenses'];
  int _tab = 0;
  String? _linked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Follow a new ?tab= link; otherwise keep the tab the user picked.
    final t = GoRouterState.of(context).uri.queryParameters['tab'];
    if (t != _linked) {
      _linked = t;
      final i = _tabs.indexOf(t ?? '');
      if (i >= 0) _tab = i;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MainTopBar(title: 'Finance', actions: [
            // Search opens on the entity of the tab in view.
            RoundIconButton(
              icon: Icons.search_rounded,
              label: 'Search',
              onPressed: () => context.push('/search?scope=${const ['savings_account', 'gold_item', 'expense'][_tab]}'),
            ),
          ]),
          _FinanceTabs(selected: _tab, onSelected: (i) => context.go('/finance?tab=${_tabs[i]}')),
          Expanded(
            child: switch (_tab) {
              0 => const SavingsOverview(),
              1 => const GoldOverview(),
              _ => const ExpensesOverview(),
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
                label: spokenAmounts('$name tab'),
                excludeSemantics: true,
                child: Material(
                  color: i == selected ? financeTile(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onSelected(i),
                    child: SizedBox(
                      height: 48,
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
