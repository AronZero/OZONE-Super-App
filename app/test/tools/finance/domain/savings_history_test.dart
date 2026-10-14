import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/domain/money.dart';
import 'package:ozone/tools/finance/domain/savings_history.dart';
import 'package:ozone/tools/finance/domain/savings_rules.dart';

LocalDate d(String iso) => LocalDate.parseIso(iso).valueOrNull!;
BalancePoint p(String iso, int pesos, {bool unchanged = false}) =>
    BalancePoint(d(iso), pesos * 100, isUnchanged: unchanged);

void main() {
  // The W1 worked example (F1-04 §2), today = 13 Oct 2026.
  final today = d('2026-10-13');
  final oct = d('2026-10-01'), sep = d('2026-09-01');
  final payroll = AccountHistory(id: 'ps', name: 'Payroll Savings', updates: [
    p('2026-08-31', 300000),
    p('2026-09-30', 312400),
  ]);
  final emergency = AccountHistory(id: 'ef', name: 'Emergency Fund', updates: [
    p('2026-09-28', 414000),
    p('2026-10-12', 420150),
  ]);

  group('F1-04 worked example', () {
    test('Payroll Savings is Carried in October and not counted', () {
      final mb = monthBalance(payroll, oct, today);
      expect(mb.status, MonthStatus.carried);
      expect(mb.balance, 31240000);
      expect(accountChange(payroll, oct, sep, today), isA<NotCounted>());
    });

    test('Emergency Fund adds +₱6,150.00', () {
      final c = accountChange(emergency, oct, sep, today) as CountedChange;
      expect(c.amount, 615000);
      expect(Money.change(c.amount), '▲ +₱6,150.00');
    });

    test('October total includes the carried balance; change counts only Recorded', () {
      final t = monthTotal([payroll, emergency], oct, today);
      expect(t.total, 31240000 + 42015000);
      expect(t.change, 615000);
      expect(t.recorded, 1);
      expect(t.carried, 1);
      expect(t.carriedLabel, '1 account carried');
      expect(t.newAccountsNote, isNull);
    });
  });

  group('monthly status', () {
    test('No data before the first update; Recorded within the month', () {
      expect(monthBalance(emergency, d('2026-08-01'), today).status, MonthStatus.noData);
      expect(monthBalance(emergency, sep, today).status, MonthStatus.recorded);
    });

    test('"Unchanged" updates make the month Recorded', () {
      final a = AccountHistory(id: 'a', name: 'A', updates: [p('2026-09-30', 100), p('2026-10-05', 100, unchanged: true)]);
      expect(monthBalance(a, oct, today).status, MonthStatus.recorded);
      expect((accountChange(a, oct, sep, today) as CountedChange).amount, 0);
    });

    test('the current month ends today: a later-dated update is not seen', () {
      final a = AccountHistory(id: 'a', name: 'A', updates: [p('2026-09-30', 100), p('2026-10-20', 200)]);
      expect(monthBalance(a, oct, today).status, MonthStatus.carried);
    });

    test('a carried base is a fair base', () {
      // Jul recorded, Aug carried, Sep recorded: Sep change is vs Jul's value.
      final a = AccountHistory(id: 'a', name: 'A', updates: [p('2026-07-02', 410000), p('2026-09-15', 414000)]);
      final c = accountChange(a, sep, d('2026-08-01'), today) as CountedChange;
      expect(c.amount, 400000);
      expect(c.base.status, MonthStatus.carried);
      expect(c.base.update!.date, d('2026-07-02'));
    });

    test('a new account is Start and noted, not counted', () {
      final fresh = AccountHistory(id: 'n', name: 'New', updates: [p('2026-10-02', 50000)]);
      expect(accountChange(fresh, oct, sep, today), isA<StartChange>());
      final t = monthTotal([emergency, fresh], oct, today);
      expect(t.total, 42015000 + 5000000);
      expect(t.change, 615000);
      expect(t.newAccountsNote, 'Includes 1 new account, not counted');
    });

    test('a month with no account data is No data', () {
      final t = monthTotal([emergency], d('2026-06-01'), today);
      expect(t.hasData, isFalse);
    });

    test('All carried label', () {
      final t = monthTotal([payroll], oct, today);
      expect(t.carriedLabel, 'All carried');
      expect(t.countedAccounts, 0);
    });

    test('year-on-year uses M−12 as the base', () {
      final a = AccountHistory(id: 'a', name: 'A', updates: [p('2025-10-10', 1000), p('2026-10-10', 1500)]);
      final t = monthTotal([a], oct, today, base: d('2025-10-01'));
      expect(t.change, 50000);
    });
  });

  group('archived accounts', () {
    final closed = AccountHistory(
      id: 'c',
      name: 'Closed',
      archivedAt: d('2026-09-15'),
      updates: [p('2026-08-10', 1000), p('2026-09-10', 0)],
    );

    test('the archive month still counts; later months do not', () {
      expect(isActiveIn(closed, sep, today), isTrue);
      expect(isActiveIn(closed, oct, today), isFalse);
      expect(monthTotal([closed], oct, today).hasData, isFalse);
      expect(monthTotal([closed], sep, today).change, -100000);
    });

    test('archiving is never shown as a loss in the following month', () {
      final t = monthTotal([closed, emergency], oct, today);
      expect(t.change, 615000);
    });
  });

  group('needs a balance (F1-04 decision 1)', () {
    test('before the 25th only last month\'s carried accounts are due', () {
      final due = balancesDue([payroll, emergency], today);
      expect(due, isEmpty); // both recorded in September
    });

    test('from the 25th, accounts not Recorded this month are due', () {
      final due = balancesDue([payroll, emergency], d('2026-10-25'));
      expect(due.map((x) => x.message), ['Payroll Savings needs an October balance']);
    });

    test('on 3 Nov, a month that ended Carried is still due', () {
      final due = balancesDue([payroll, emergency], d('2026-11-03'));
      expect(due.map((x) => x.message), ['Payroll Savings needs an October balance']);
    });

    test('a past-dated update fixes it; archived accounts are never due', () {
      final fixed = AccountHistory(id: 'ps', name: 'Payroll Savings', updates: [...payroll.updates, p('2026-10-31', 318950)]);
      expect(balancesDue([fixed], d('2026-11-03')), isEmpty);
      final arch = AccountHistory(id: 'x', name: 'X', archivedAt: d('2026-10-01'), updates: payroll.updates);
      expect(balancesDue([arch], d('2026-11-03')), isEmpty);
    });

    test('"a" vs "an" before the month name', () {
      expect(BalanceDue(payroll, d('2026-09-01')).message, 'Payroll Savings needs a September balance');
      expect(BalanceDue(payroll, d('2026-08-01')).message, 'Payroll Savings needs an August balance');
    });
  });

  test('12-month chart range ends with the current month', () {
    final months = lastTwelveMonths([emergency], today);
    expect(months.length, 12);
    expect(months.first.month, d('2025-11-01'));
    expect(months.last.month, oct);
  });

  group('rules', () {
    test('names', () {
      expect(validateAccountName('  ').isOk, isFalse);
      expect(validateAccountName(' Emergency Fund ').valueOrNull, 'Emergency Fund');
      expect(validateAccountName('x' * 81).isOk, isFalse);
      expect(nameTaken('emergency fund', ['Emergency Fund']), isTrue);
      expect(nameTaken('Payroll', ['Emergency Fund']), isFalse);
    });

    test('initials', () {
      expect(accountInitials('Emergency Fund'), 'EF');
      expect(accountInitials('MP2 Savings'), 'MP');
      expect(accountInitials('Payroll Savings'), 'PS');
      expect(accountInitials('gcash'), 'GC');
    });

    test('dates are never in the future', () {
      expect(validateNotFuture(d('2026-10-14'), today).isOk, isFalse);
      expect(validateNotFuture(d('2026-01-01'), today).isOk, isTrue);
    });
  });
}
