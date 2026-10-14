import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/domain/money.dart';
import 'package:ozone/core/domain/weight.dart';
import 'package:ozone/tools/finance/domain/expenses.dart';
import 'package:ozone/tools/finance/domain/gold.dart';

LocalDate d(String iso) => LocalDate.parseIso(iso).valueOrNull!;

void main() {
  group('weight', () {
    test('format and parse', () {
      expect(Weight.format(82400), '82.400 g');
      expect(Weight.format(1234567), '1,234.567 g');
      expect(Weight.parse('20.3').valueOrNull, 20300);
      expect(Weight.parse('25 g').valueOrNull, 25000);
      expect(Weight.parse('1.2345').isOk, isFalse);
      expect(Weight.parse('0').isOk, isFalse);
      expect(Weight.parse('abc').isOk, isFalse);
      expect(Weight.plain(20300), '20.300');
    });
  });

  group('gold (F1-04 §4, W2 · Gold board)', () {
    final prices = currentPrices([
      KaratPrice(24, 735000, d('2026-10-02')),
      KaratPrice(21, 643000, d('2026-10-02')),
      KaratPrice(18, 551000, d('2026-10-02')),
      KaratPrice(14, 430000, d('2026-10-02')),
      KaratPrice(18, 500000, d('2026-09-01')), // older: not current
    ]);
    const pieces = [
      GoldPiece(id: '1', name: 'Gold bangle', weightMg: 25000, karat: 18, cost: 11822000),
      GoldPiece(id: '2', name: 'Gold chain', weightMg: 20300, karat: 21, cost: 11250000),
      GoldPiece(id: '3', name: 'Gold bar', weightMg: 10000, karat: 24, cost: 6420000),
      GoldPiece(id: '4', name: 'Gold wedding bands', weightMg: 12500, karat: 18, cost: 5800000),
      GoldPiece(id: '5', name: 'Ring', weightMg: 14600, karat: 14, cost: 5000000),
      GoldPiece(id: '6', name: 'Sold earrings', weightMg: 5000, karat: 18, cost: 2000000, held: false),
    ];

    test('value = grams × price, rounded once per item', () {
      expect(itemValue(25000, 551000), 13775000);
      expect(itemValue(20300, 643000), 13052900);
      expect(itemValue(1, 1), 0); // 0.001 centavo rounds to 0
      expect(itemValue(1, 500), 1); // 0.5 centavo rounds away from zero
    });

    test('board totals: ₱473,434.00, gain ▲ +₱70,514.00 · 17.5%', () {
      final t = goldTotals(pieces, prices);
      expect(t.items, 5);
      expect(Weight.format(t.weightMg), '82.400 g');
      expect(t.value, 47343400);
      expect(t.cost, 40292000);
      expect(t.gain, 7051400);
      expect(Money.percent(t.gain, t.valuedCost), '17.5%');
      expect(t.pricesAsOf, d('2026-10-02'));
    });

    test('items with no price stay in weight and cost but not value or gain', () {
      final t = goldTotals(pieces, {...prices}..remove(21));
      expect(t.weightMg, 82400);
      expect(t.cost, 40292000);
      expect(t.value, 47343400 - 13052900);
      expect(t.gain, (47343400 - 13052900) - (40292000 - 11250000));
      expect(t.unpricedNote, 'Value leaves out 1 item with no 21K price');
    });

    test('"Prices as of" is the oldest current price in use', () {
      final p = {...prices, 14: KaratPrice(14, 430000, d('2026-08-01'))};
      expect(goldTotals(pieces, p).pricesAsOf, d('2026-08-01'));
    });

    test('karat chips: common ones plus karats in use, high to low (M3-5)', () {
      expect(karatChoices(const []), [24, 22, 21, 18, 14, 10]);
      expect(karatChoices(const [8, 18, 8, 0, 30]), [24, 22, 21, 18, 14, 10, 8]);
    });

    test('Needs attention: stale after 30 days, and missing prices', () {
      expect(goldAttention(pieces, prices, d('2026-11-01')), isEmpty); // 30 days old
      expect(goldAttention(pieces, prices, d('2026-11-12')), ['Gold prices are 41 days old']);
      expect(goldAttention(pieces, {...prices}..remove(21), d('2026-10-13')), ['No price for 21K']);
    });
  });

  group('expenses (F1-04 §5)', () {
    final xs = [
      Spend(id: 'a', item: 'Air fryer', vendor: 'Shopee', amount: 349900, date: d('2026-10-03')),
      Spend(id: 'b', item: 'Earbuds', vendor: 'Shopee', amount: 129900, date: d('2026-10-12'), refunded: true),
      Spend(id: 'c', item: 'Shoes', vendor: 'Lazada', amount: 425000, date: d('2026-02-28')),
      Spend(id: 'd', item: 'Bag', vendor: 'Lazada', amount: 100000, date: d('2025-03-01')),
      Spend(id: 'e', item: 'Lamp', vendor: 'Lazada', amount: 50000, date: d('2025-10-14')),
      Spend(id: 'f', item: 'Old', vendor: 'Mall', amount: 10000, date: d('2023-05-05')),
    ];

    test('refunded expenses are left out of totals', () {
      final y = yearToDate(xs, 2026, d('2026-10-13'));
      expect(y.thisYear, 349900 + 425000);
      expect(y.lastYear, 100000); // 14 Oct 2025 is after the same day last year
      expect(y.lastYearEnd, d('2025-10-13'));
    });

    test('29 Feb compares with 28 Feb last year', () {
      expect(sameDayLastYear(d('2028-02-29')), d('2027-02-28'));
      final leap = [Spend(id: 'x', item: 'x', vendor: 'v', amount: 100, date: d('2027-02-28'))];
      expect(yearToDate(leap, 2028, d('2028-02-29')).lastYear, 100);
    });

    test('change % with no base is null', () {
      expect(yearToDate(const [], 2026, d('2026-10-13')).changeTenths, isNull);
      expect(percentTenths(-91), '−9.1%');
      expect(percentTenths(178), '+17.8%');
    });

    test('Spending by year: ₱0.00 years after the first expense, none before', () {
      final years = spendingByYear(xs, d('2026-10-13'));
      expect(years.map((y) => y.year), [2023, 2024, 2025, 2026]);
      expect(years.firstWhere((y) => y.year == 2024).total, 0);
      expect(years.last.soFar, isTrue);
    });

    test('monthly bars leave future months empty', () {
      final m = monthlyTotals(xs, 2026, d('2026-10-13'));
      expect(m[9], 349900);
      expect(m[1], 425000);
      expect(m[10], isNull);
    });

    test('possible duplicates: same vendor and amount within 3 days', () {
      expect(possibleDuplicates(xs, vendor: 'shopee ', amount: 349900, date: d('2026-10-06')).map((e) => e.id), ['a']);
      expect(possibleDuplicates(xs, vendor: 'Shopee', amount: 349900, date: d('2026-10-07')), isEmpty);
      expect(possibleDuplicates(xs, vendor: 'Lazada', amount: 349900, date: d('2026-10-03')), isEmpty);
      expect(possibleDuplicates(xs, vendor: 'Shopee', amount: 349900, date: d('2026-10-03'), exceptId: 'a'), isEmpty);
    });
  });
}
