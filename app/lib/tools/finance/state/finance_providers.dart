import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../data/expenses_repo.dart';
import '../data/gold_repo.dart';
import '../data/lists_repo.dart';
import '../domain/gold.dart';

// Gold, Expenses and Lists state. Savings has its own file (savings_providers.dart).

final goldRepoProvider = Provider<GoldRepo>((ref) => GoldRepo(ref.watch(databaseProvider), ref.watch(deletionsRepoProvider)));
final expensesRepoProvider =
    Provider<ExpensesRepo>((ref) => ExpensesRepo(ref.watch(databaseProvider), ref.watch(deletionsRepoProvider)));
final listsRepoProvider = Provider<ListsRepo>((ref) => ListsRepo(ref.watch(databaseProvider), ref.watch(settingsRepoProvider)));

final goldDataProvider = StreamProvider<GoldData>((ref) => ref.watch(goldRepoProvider).watch());
final expensesDataProvider = StreamProvider<ExpensesData>((ref) => ref.watch(expensesRepoProvider).watch());

final goldStaleDaysProvider = StreamProvider<int>((ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.goldStaleDays));

/// "Gold prices are 41 days old", "No price for 21K" for Needs attention.
final goldAttentionProvider = Provider<List<String>>((ref) {
  final d = ref.watch(goldDataProvider).value;
  if (d == null) return const [];
  return goldAttention(d.pieces, d.prices, ref.watch(todayProvider), staleDays: ref.watch(goldStaleDaysProvider).value ?? 30);
});
