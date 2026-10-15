import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/theme/tokens.dart';
import '../../shell/tool_registry.dart';
import 'finance_search.dart';
import 'state/finance_providers.dart';
import 'state/savings_providers.dart';
import 'ui/account_detail_screen.dart';
import 'ui/archived_screen.dart';
import 'ui/disposed_screen.dart';
import 'ui/expense_detail_screen.dart';
import 'ui/finance_home.dart';
import 'ui/finance_widgets.dart';
import 'ui/history_screen.dart';
import 'ui/karat_prices_screen.dart';
import 'ui/lists_screen.dart';
import 'ui/savings_widgets.dart';
import 'ui/spending_year_screen.dart';
import 'ui/update_balances_screen.dart';

/// Finance tool definition: Savings (M2), Gold and Expenses (M3).
const ToolDefinition financeTool = ToolDefinition(
  id: 'finance',
  name: 'Finance',
  tint: ToolTint.finance,
  icon: Icons.account_balance_wallet_rounded,
  routeBase: '/finance',
  home: _home,
  routes: _routes,
  widgets: {
    'total_savings': _totalSavings,
    'savings_trend': _savingsTrend,
    'gold_holdings': _goldHoldings,
    'spending_this_year': _spendingThisYear,
    'recent_expenses': _recentExpenses,
  },
  attention: _attention,
  searchSources: financeSearch,
  quickAdd: financeQuickAdd,
);

Widget _home(BuildContext context) => const FinanceHome();
Widget _totalSavings(BuildContext context) => const TotalSavingsWidget();
Widget _savingsTrend(BuildContext context) => const SavingsTrendWidget();
Widget _goldHoldings(BuildContext context) => const GoldHoldingsWidget();
Widget _spendingThisYear(BuildContext context) => const SpendingThisYearWidget();
Widget _recentExpenses(BuildContext context) => const RecentExpensesWidget();

/// Finance screens below the tabs hide the bar (they open above it, as on the boards).
List<RouteBase> _routes(GlobalKey<NavigatorState> root) {
  GoRoute full(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, parentNavigatorKey: root, builder: (context, state) => build(state));
  return [
    full('savings/update', (_) => const UpdateBalancesScreen()),
    full('savings/history', (_) => const HistoryScreen()),
    full('savings/archived', (_) => const ArchivedScreen()),
    full('savings/accounts/:id', (s) => AccountDetailScreen(accountId: s.pathParameters['id']!)),
    full('gold/prices', (_) => const KaratPricesScreen()),
    full('gold/prices/history', (_) => const KaratHistoryScreen()),
    full('gold/disposed', (_) => const DisposedScreen()),
    full('expenses/years', (_) => const SpendingYearScreen()),
    full('expenses/:id', (s) => ExpenseDetailScreen(expenseId: s.pathParameters['id']!)),
    full('lists', (_) => const ListsScreen()),
  ];
}

/// Needs attention lines (F1-04 §3): due balances → Update balances;
/// stale or missing gold prices → Karat prices.
List<AttentionItem> _attention(WidgetRef ref) => [
      for (final d in ref.watch(balancesDueProvider)) AttentionItem(d.message, '/finance/savings/update'),
      for (final g in ref.watch(goldAttentionProvider)) AttentionItem(g, '/finance/gold/prices'),
    ];
