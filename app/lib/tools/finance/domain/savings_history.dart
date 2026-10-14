import '../../../core/domain/dates.dart';

// Savings monthly history (docs/spec/F1-04 §2). Pure functions over the
// balance updates: nothing is stored, nothing is invented.

/// One dated balance update, as the history rules need it.
class BalancePoint {
  const BalancePoint(this.date, this.balance, {this.isUnchanged = false});
  final LocalDate date;
  final int balance;
  final bool isUnchanged;
}

/// One account with its updates, oldest first (one per date).
class AccountHistory {
  AccountHistory({required this.id, required this.name, this.archivedAt, required List<BalancePoint> updates})
      : updates = List<BalancePoint>.unmodifiable(<BalancePoint>[...updates]..sort((a, b) => a.date.compareTo(b.date)));

  final String id;
  final String name;
  final LocalDate? archivedAt;
  final List<BalancePoint> updates;

  bool get isArchived => archivedAt != null;
  BalancePoint? get latest => updates.isEmpty ? null : updates.last;
  BalancePoint? get first => updates.isEmpty ? null : updates.first;
}

enum MonthStatus { noData, recorded, carried }

/// A month is identified by its first day.
LocalDate monthOf(LocalDate d) => d.monthStart;

/// `end(M)`: the last day, or [today] for the current month (F1-04 §2).
LocalDate monthEndFor(LocalDate month, LocalDate today) {
  final end = month.monthEnd;
  return end.isAfter(today) ? today : end;
}

/// Where account A stands in month M.
class MonthBalance {
  const MonthBalance(this.status, this.update);
  const MonthBalance.noData() : status = MonthStatus.noData, update = null;

  final MonthStatus status;

  /// U(A, M): the latest update dated on or before end(M).
  final BalancePoint? update;

  int? get balance => update?.balance;
  bool get hasData => status != MonthStatus.noData;
}

/// U(A, M) and its status. Example: Payroll Savings last updated 30 Sep is
/// **Carried** in October with ₱312,400.00.
MonthBalance monthBalance(AccountHistory a, LocalDate month, LocalDate today) {
  final m = monthOf(month);
  final end = monthEndFor(m, today);
  BalancePoint? u;
  for (final p in a.updates) {
    if (p.date.isAfter(end)) break;
    u = p;
  }
  if (u == null) return const MonthBalance.noData();
  return MonthBalance(u.date.isBefore(m) ? MonthStatus.carried : MonthStatus.recorded, u);
}

/// Active in M: has an update by end(M), and isn't archived before M starts.
/// The archive month itself still counts.
bool isActiveIn(AccountHistory a, LocalDate month, LocalDate today) {
  final m = monthOf(month);
  final f = a.first;
  if (f == null || f.date.isAfter(monthEndFor(m, today))) return false;
  final arch = a.archivedAt;
  return arch == null || !arch.isBefore(m);
}

/// The change for one account between month M and base month B.
sealed class AccountChange {
  const AccountChange();
}

/// M has no data: nothing to show.
final class NoChangeData extends AccountChange {
  const NoChangeData();
}

/// M is Carried: never counted as a change.
final class NotCounted extends AccountChange {
  const NotCounted();
}

/// M has data but B has none (a new account): not counted.
final class StartChange extends AccountChange {
  const StartChange();
}

/// A counted change. [base] tells whether B was itself Carried (and from when).
final class CountedChange extends AccountChange {
  const CountedChange(this.amount, this.base);
  final int amount;
  final MonthBalance base;
}

/// Change for one account, M vs B (B = M−1 or M−12, or any earlier month).
/// Example: Emergency Fund ₱420,150.00 on 12 Oct vs ₱414,000.00 at September's
/// end → CountedChange(+615000).
AccountChange accountChange(AccountHistory a, LocalDate month, LocalDate base, LocalDate today) {
  final mb = monthBalance(a, month, today);
  switch (mb.status) {
    case MonthStatus.noData:
      return const NoChangeData();
    case MonthStatus.carried:
      return const NotCounted();
    case MonthStatus.recorded:
      final bb = monthBalance(a, base, today);
      if (!bb.hasData) return const StartChange();
      return CountedChange(mb.balance! - bb.balance!, bb);
  }
}

/// Totals for month M over all accounts (Savings card, History report, charts).
class MonthTotal {
  const MonthTotal({
    required this.month,
    required this.total,
    required this.change,
    required this.recorded,
    required this.carried,
    required this.newAccounts,
    required this.countedAccounts,
  });

  final LocalDate month;

  /// Null when no account has data: the month is **No data** (a gap in charts).
  final int? total;

  /// Sum of the counted account changes. Carried, Start and archived accounts add nothing.
  final int change;
  final int recorded;
  final int carried;

  /// Accounts whose first data is in M (Start): "Includes 1 new account, not counted".
  final int newAccounts;

  /// Accounts whose change was counted. 0 means there is no change to show.
  final int countedAccounts;

  bool get hasData => total != null;
  bool get allCarried => recorded == 0 && carried > 0;
  int get accounts => recorded + carried;

  /// "1 account carried", "2 accounts carried", "All carried", or null.
  String? get carriedLabel {
    if (carried == 0) return null;
    if (allCarried) return 'All carried';
    return '$carried ${carried == 1 ? 'account' : 'accounts'} carried';
  }

  /// "Includes 1 new account, not counted" (F1-04 decision 2), or null.
  String? get newAccountsNote => newAccounts == 0
      ? null
      : 'Includes $newAccounts new ${newAccounts == 1 ? 'account' : 'accounts'}, not counted';
}

/// Total(M) and Change(M) against [base] (default: the month before).
/// Example (W1): October total includes Payroll Savings' carried ₱312,400.00,
/// but its change is Not counted; Emergency Fund adds +₱6,150.00.
MonthTotal monthTotal(Iterable<AccountHistory> accounts, LocalDate month, LocalDate today, {LocalDate? base}) {
  final m = monthOf(month);
  final b = monthOf(base ?? m.addMonths(-1));
  var total = 0, change = 0, recorded = 0, carried = 0, fresh = 0, counted = 0;
  for (final a in accounts) {
    if (!isActiveIn(a, m, today)) continue;
    final mb = monthBalance(a, m, today);
    if (mb.status == MonthStatus.recorded) {
      recorded++;
    } else {
      carried++;
    }
    total += mb.balance!;
    switch (accountChange(a, m, b, today)) {
      case CountedChange(:final amount):
        change += amount;
        counted++;
      case StartChange():
        fresh++;
      case NotCounted() || NoChangeData():
        break;
    }
  }
  return MonthTotal(
    month: m,
    total: recorded + carried == 0 ? null : total,
    change: change,
    recorded: recorded,
    carried: carried,
    newAccounts: fresh,
    countedAccounts: counted,
  );
}

/// [count] months ending with [last], oldest first.
List<LocalDate> monthsEndingWith(LocalDate last, int count) =>
    [for (var i = count - 1; i >= 0; i--) monthOf(last).addMonths(-i)];

/// The 12-month chart (F1-04 §2 "Chart range"), oldest first.
List<MonthTotal> lastTwelveMonths(Iterable<AccountHistory> accounts, LocalDate today) =>
    [for (final m in monthsEndingWith(today, 12)) monthTotal(accounts, m, today)];

/// One "needs a balance" item for Needs attention (F1-04 §3, decision 1).
class BalanceDue {
  const BalanceDue(this.account, this.month);
  final AccountHistory account;
  final LocalDate month;

  /// "Payroll Savings needs an October balance".
  String get message {
    final name = month.monthName;
    final article = RegExp(r'^[AEIOU]').hasMatch(name) ? 'an' : 'a';
    return '${account.name} needs $article $name balance';
  }
}

/// Accounts due a balance, oldest month first:
/// - last month, for open accounts whose last month ended Carried (shown all
///   month, until a past-dated update fixes it);
/// - this month, from the 25th, for open accounts not yet Recorded.
/// Example: on 3 Nov, "Payroll Savings needs an October balance".
List<BalanceDue> balancesDue(Iterable<AccountHistory> accounts, LocalDate today) {
  final thisMonth = monthOf(today);
  final lastMonth = thisMonth.addMonths(-1);
  final open = [for (final a in accounts) if (!a.isArchived && a.updates.isNotEmpty) a];
  return [
    for (final a in open)
      if (monthBalance(a, lastMonth, today).status == MonthStatus.carried) BalanceDue(a, lastMonth),
    if (today.day >= 25)
      for (final a in open)
        if (monthBalance(a, thisMonth, today).status != MonthStatus.recorded) BalanceDue(a, thisMonth),
  ];
}
