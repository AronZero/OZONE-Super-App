import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/theme/tokens.dart';
import '../../shell/tool_registry.dart';
import 'state/savings_providers.dart';
import 'ui/account_detail_screen.dart';
import 'ui/archived_screen.dart';
import 'ui/finance_home.dart';
import 'ui/history_screen.dart';
import 'ui/savings_widgets.dart';
import 'ui/update_balances_screen.dart';

/// Finance tool definition. Savings arrives in M2; Gold and Expenses in M3 (docs/spec/F3-04).
const ToolDefinition financeTool = ToolDefinition(
  id: 'finance',
  name: 'Finance',
  tint: ToolTint.finance,
  icon: Icons.account_balance_wallet_rounded,
  routeBase: '/finance',
  home: _home,
  routes: _routes,
  widgets: {'total_savings': _totalSavings, 'savings_trend': _savingsTrend},
  attention: _attention,
);

Widget _home(BuildContext context) => const FinanceHome();
Widget _totalSavings(BuildContext context) => const TotalSavingsWidget();
Widget _savingsTrend(BuildContext context) => const SavingsTrendWidget();

/// Savings screens hide the bar (they open above it, as on the W1/W3 boards).
List<RouteBase> _routes(GlobalKey<NavigatorState> root) => [
      GoRoute(path: 'savings/update', parentNavigatorKey: root, builder: (context, state) => const UpdateBalancesScreen()),
      GoRoute(path: 'savings/history', parentNavigatorKey: root, builder: (context, state) => const HistoryScreen()),
      GoRoute(path: 'savings/archived', parentNavigatorKey: root, builder: (context, state) => const ArchivedScreen()),
      GoRoute(
        path: 'savings/accounts/:id',
        parentNavigatorKey: root,
        builder: (context, state) => AccountDetailScreen(accountId: state.pathParameters['id']!),
      ),
    ];

/// "Payroll Savings needs an October balance" → Update balances (F1-04 §3).
List<AttentionItem> _attention(WidgetRef ref) => [
      for (final d in ref.watch(balancesDueProvider)) AttentionItem(d.message, '/finance/savings/update'),
    ];
