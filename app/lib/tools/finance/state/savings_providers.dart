import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../data/savings_repo.dart';
import '../domain/savings_history.dart';

final savingsRepoProvider = Provider<SavingsRepo>((ref) => SavingsRepo(
      ref.watch(databaseProvider),
      ref.watch(deletionsRepoProvider),
    ));

/// All accounts and updates; screens rebuild whenever they change.
final savingsDataProvider = StreamProvider<SavingsData>((ref) => ref.watch(savingsRepoProvider).watch());

/// This month's total and change vs last month (Savings card, Total savings widget).
final savingsThisMonthProvider = Provider<AsyncValue<MonthTotal>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(savingsDataProvider).whenData((d) => monthTotal(d.histories, today, today));
});

/// The 12-month chart, oldest first.
final savingsTwelveMonthsProvider = Provider<AsyncValue<List<MonthTotal>>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(savingsDataProvider).whenData((d) => lastTwelveMonths(d.histories, today));
});

/// "Needs a balance" items for Needs attention.
final balancesDueProvider = Provider<List<BalanceDue>>((ref) {
  final today = ref.watch(todayProvider);
  final d = ref.watch(savingsDataProvider).value;
  return d == null ? const [] : balancesDue(d.histories, today);
});
