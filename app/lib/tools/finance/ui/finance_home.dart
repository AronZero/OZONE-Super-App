import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import 'expenses_overview.dart';
import 'gold_overview.dart';
import 'savings_overview.dart';
import '../../../core/ui/theme/oz_icons.dart';

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
              icon: OzIcons.search,
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
    final (pill, pillText) = ToolTint.finance.selectedOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.screen, 2, Space.screen, Space.m),
      child: SegmentTabs(
        labels: const ['Savings', 'Gold', 'Expenses'],
        selected: selected,
        onSelected: onSelected,
        pill: pill,
        pillText: pillText,
        spokenSuffix: ' tab',
      ),
    );
  }
}
