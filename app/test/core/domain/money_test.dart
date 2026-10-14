import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/domain/money.dart';
import 'package:ozone/core/domain/validation.dart';

void main() {
  group('format (docs/05 formats)', () {
    test('pesos and centavos with grouping', () {
      expect(Money.format(123456), '₱1,234.56');
      expect(Money.format(128435000), '₱1,284,350.00');
      expect(Money.format(5), '₱0.05');
      expect(Money.format(0), '₱0.00');
    });
    test('negative uses a true minus sign', () => expect(Money.format(-200000), '\u2212₱2,000.00'));
    test('compact for chart axes', () {
      expect(Money.compact(128000000), '₱1.28M');
      expect(Money.compact(6481250), '₱64.8k');
      expect(Money.compact(95000), '₱950');
    });
    test('changes carry sign and arrow', () {
      expect(Money.change(1842000), '▲ +₱18,420.00');
      expect(Money.change(-200000), '▼ \u2212₱2,000.00');
      expect(Money.change(0), 'No change');
    });
    test('percent: one decimal, dash when base is 0', () {
      expect(Money.percent(7051400, 40292000), '17.5%');
      expect(Money.percent(5, 0), '—');
    });
    test('spoken for screen readers', () {
      expect(Money.spoken(123456), '1,234 pesos and 56 centavos');
      expect(Money.spoken(100), '1 peso');
    });
  });

  group('parse (F1-04 §1)', () {
    int ok(String s, {bool zero = false}) => (Money.parse(s, allowZero: zero) as Ok<int>).value;
    String bad(String s) => (Money.parse(s) as Invalid<int>).reason;

    test('accepts commas, ₱ and up to 2 decimals', () {
      expect(ok('1,234.56'), 123456);
      expect(ok('₱1,299'), 129900);
      expect(ok('1299.5'), 129950);
      expect(ok(' 349.00 '), 34900);
    });
    test('rejects more than 2 decimals instead of rounding', () => expect(bad('1.234'), contains('2 decimals')));
    test('rejects letters', () => expect(bad('1,2OO'), contains('isn\u2019t an amount')));
    test('zero only where allowed', () {
      expect(bad('0'), contains('above ₱0.00'));
      expect(ok('0', zero: true), 0);
    });
    test('upper limit', () {
      expect(ok('999999999.99'), Money.max);
      expect(bad('1000000000'), contains('more than'));
    });
    test('empty', () => expect(bad('  '), 'Enter an amount'));
  });

  group('rounding', () {
    test('half away from zero', () {
      expect(roundHalfAwayFromZero(2.5), 3);
      expect(roundHalfAwayFromZero(-2.5), -3);
      expect(roundHalfAwayFromZero(2.4), 2);
    });
    test('mulDivRound is exact: gold value mg × price ÷ 1000', () {
      // 25.000 g of 18K at ₱5,510.00/g = ₱137,750.00 (W2 Gold board).
      expect(mulDivRound(25000, 551000, 1000), 13775000);
      // 0.001 g at ₱5,510.00/g = ₱5.51
      expect(mulDivRound(1, 551000, 1000), 551);
      // 1.5 centavos rounds to 2
      expect(mulDivRound(3, 1, 2), 2);
      expect(mulDivRound(-3, 1, 2), -2);
    });
  });
}
