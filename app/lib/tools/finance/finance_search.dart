import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/dates.dart';
import '../../core/domain/weight.dart';
import '../../core/state/today.dart';
import '../../core/ui/amounts.dart';
import '../../shell/tool_registry.dart';
import 'state/finance_providers.dart';
import 'state/savings_providers.dart';
import 'ui/expense_sheet.dart';
import 'ui/gold_item_sheet.dart';

/// Finance records in global search (F2-02 §1): accounts, gold items, expenses.
const List<SearchSource> financeSearch = [
  SearchSource(entity: 'savings_account', group: 'Accounts', chip: 'Accounts', open: _openAccount, describe: _account),
  SearchSource(entity: 'gold_item', group: 'Gold items', chip: 'Gold', open: _openGold, describe: _gold),
  SearchSource(entity: 'expense', group: 'Expenses', chip: 'Expenses', open: _openExpense, describe: _expense),
];

void _openAccount(BuildContext context, WidgetRef ref, String id) => context.push('/finance/savings/accounts/$id');
void _openExpense(BuildContext context, WidgetRef ref, String id) => context.push('/finance/expenses/$id');

/// Gold items have no screen of their own (decision M3-1): the item sheet opens above search.
void _openGold(BuildContext context, WidgetRef ref, String id) {
  final item = ref.read(goldDataProvider).value?.items.where((i) => i.id == id).firstOrNull;
  if (item != null) showGoldItemSheet(context, existing: item);
}

SearchRowInfo? _account(BuildContext context, WidgetRef ref, String id) {
  final d = ref.watch(savingsDataProvider).value;
  final a = d?.account(id);
  if (d == null || a == null) return null;
  final ups = d.updatesOf(id);
  final words = [?a.platform, ?a.type, if (a.archivedAt != null) 'Archived'];
  return SearchRowInfo(words.isEmpty ? 'Savings account' : words.join(' · '), trailing: ups.isEmpty ? null : money(context, ups.last.balance));
}

SearchRowInfo? _gold(BuildContext context, WidgetRef ref, String id) {
  final d = ref.watch(goldDataProvider).value;
  final i = d?.items.where((x) => x.id == id).firstOrNull;
  if (d == null || i == null) return null;
  final v = d.valueOf(i);
  return SearchRowInfo(
    '${i.karat}K · ${Weight.format(i.weightMg)}${i.status == 'disposed' ? ' · Disposed' : ''}',
    trailing: i.status == 'disposed' || v == null ? null : money(context, v),
  );
}

SearchRowInfo? _expense(BuildContext context, WidgetRef ref, String id) {
  final e = ref.watch(expensesDataProvider).value?.byId(id);
  if (e == null) return null;
  final date = LocalDate.parseIso(e.date).valueOrNull;
  final today = ref.watch(todayProvider);
  return SearchRowInfo(
    '${e.vendor}${date == null ? '' : ' · ${date.format(today)}'}${e.isRefunded ? ' · Refunded' : ''}',
    trailing: money(context, e.amount),
    struck: e.isRefunded,
  );
}

/// Finance entries of Home's quick-add menu (Components board order).
const List<QuickAddAction> financeQuickAdd = [
  QuickAddAction(label: 'Update balances', icon: Icons.account_balance_wallet_outlined, run: _updateBalances),
  QuickAddAction(label: 'Add expense', icon: Icons.receipt_long_outlined, run: _addExpense),
  QuickAddAction(label: 'Add gold item', icon: Icons.diamond_outlined, run: _addGold),
];

void _updateBalances(BuildContext context) => context.push('/finance/savings/update');
void _addExpense(BuildContext context) => showExpenseSheet(context);
void _addGold(BuildContext context) => showGoldItemSheet(context);
