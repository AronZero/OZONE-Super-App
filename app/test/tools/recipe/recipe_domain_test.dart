import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/domain/validation.dart';
import 'package:ozone/tools/recipe/domain/amounts.dart';
import 'package:ozone/tools/recipe/domain/ingredient_words.dart';
import 'package:ozone/tools/recipe/domain/recipe.dart';
import 'package:ozone/tools/recipe/domain/units.dart';

(Amount?, String?) ok(String s) => (parseAmountField(s) as Ok<(Amount?, String?)>).value;
String bad(String s) => (parseAmountField(s) as Invalid<(Amount?, String?)>).reason;

void main() {
  group('Amount field (F4-02 §2)', () {
    test('every accepted form', () {
      expect(ok(''), (null, null));
      expect(ok('2'), (const Amount(2000), null));
      expect(ok('1.5'), (const Amount(1500), null));
      expect(ok('1,5'), (const Amount(1500), null));
      expect(ok('½'), (const Amount(500), null));
      expect(ok('1/2'), (const Amount(500), null));
      expect(ok('1 1/2'), (const Amount(1500), null));
      expect(ok('1½'), (const Amount(1500), null));
      expect(ok('1 ½'), (const Amount(1500), null));
      expect(ok('⅓ cup'), (const Amount(333), 'cup'));
      expect(ok('2-3'), (const Amount(2000, 3000), null));
      expect(ok('2–3 cloves'), (const Amount(2000, 3000), 'clove'));
      expect(ok('2 to 3 tbsp'), (const Amount(2000, 3000), 'tbsp'));
      expect(ok('1kg'), (const Amount(1000), 'kg'));
      expect(ok('1,000 g'), (const Amount(1000000), 'g'));
    });

    test('units: aliases, Filipino words, T and t', () {
      expect(ok('2 Tablespoons.').$2, 'tbsp');
      expect(ok('1 T').$2, 'tbsp');
      expect(ok('1 t').$2, 'tsp');
      expect(ok('2 kutsara').$2, 'tbsp');
      expect(ok('1 tasa').$2, 'cup');
      expect(ok('3 butil').$2, 'clove');
      expect(Units.of('large'), isNull);
    });

    test('mistakes are explained in words', () {
      expect(bad('abc'), contains('isn’t a number'));
      expect(bad('0'), 'Amount must be more than 0');
      expect(bad('3-2'), contains('second number must be larger'));
      expect(bad('2 large'), '“large” isn’t a unit. Put it in the ingredient’s name.');
    });

    test('a saved amount reads back the same', () {
      for (final s in ['½ cup', '1 ½ cups', '2–3 cloves', '8 cloves', '1 kg', '3']) {
        final (a, u) = ok(s);
        expect(ok(amountFieldText(a, u)), (a, u), reason: s);
      }
    });
  });

  group('showing and scaling amounts (F4-02 §6)', () {
    test('fractions, decimals and whole numbers', () {
      expect(formatMilli(2000), '2');
      expect(formatMilli(500), '½');
      expect(formatMilli(1500), '1 ½');
      expect(formatMilli(333), '⅓');
      expect(formatMilli(1667), '1 ⅔');
      expect(formatMilli(750), '¾');
      expect(formatMilli(1200), '1.2');
      expect(formatMilli(12400), '12');
      expect(formatMilli(2990), '3');
      expect(formatMilli(1500, wholeOnly: true), '2');
    });

    test('scaling 4 → 6 servings: ½ cup becomes ¾ cup, ⅓ cup becomes ½ cup', () {
      expect(formatAmount(const Amount(500).scaled(6 / 4), 'cup'), '¾ cup');
      expect(formatAmount(const Amount(333).scaled(6 / 4), 'cup'), '½ cup');
      expect(formatAmount(const Amount(8000).scaled(6 / 4), 'clove'), '12 cloves');
      expect(formatAmount(const Amount(2000, 3000).scaled(2), 'clove'), '4–6 cloves');
      expect(formatAmount(const Amount(250000).scaled(1 / 3), 'g'), '83 g');
      expect(formatAmount(null, null), '');
    });

    test('plurals only for words', () {
      expect(formatAmount(const Amount(1000), 'cup'), '1 cup');
      expect(formatAmount(const Amount(2000), 'cup'), '2 cups');
      expect(formatAmount(const Amount(2000), 'tbsp'), '2 tbsp');
    });

    test('TalkBack reads fractions in words', () {
      expect(spokenAmount(const Amount(1500), 'cup'), '1 and a half cups');
      expect(spokenAmount(const Amount(500), 'cup'), 'a half cup');
      expect(spokenAmount(const Amount(2000, 3000), 'clove'), '2 to 3 cloves');
    });
  });

  group('key names (F4-02 §5)', () {
    test('descriptors, commas and synonyms', () {
      expect(keyNameFor('garlic, crushed'), 'garlic');
      expect(keyNameFor('Chicken thighs, cut into pieces'), 'chicken');
      expect(keyNameFor('large eggs'), 'egg');
      expect(keyNameFor('whole black peppercorns'), 'pepper');
      expect(keyNameFor('cane vinegar'), 'vinegar');
      expect(keyNameFor('brown sugar'), 'sugar');
      expect(keyNameFor('cooking oil'), 'oil');
      expect(keyNameFor('Talong'), 'eggplant');
      expect(keyNameFor('spring onions (green part)'), 'green onion');
      expect(keyNameFor('bay leaves'), 'bay leaves');
    });

    test('nothing left after the descriptors keeps the whole name', () {
      expect(keyNameFor('Fresh'), 'fresh');
    });
  });

  group('form rules', () {
    test('servings and minutes', () {
      expect(parseServings('').valueOrNull, isNull);
      expect(parseServings('4').valueOrNull, 4);
      expect(parseServings('0'), isA<Invalid<int?>>());
      expect(parseServings('101'), isA<Invalid<int?>>());
      expect(parseMinutes('6001'), isA<Invalid<int?>>());
      expect(parseMinutes('0').valueOrNull, 0);
    });

    test('durations', () {
      expect(durationText(15, 55), '1 h 10 min');
      expect(durationText(null, 45), '45 min');
      expect(durationText(120, null), '2 h');
      expect(durationText(null, null), isNull);
    });
  });
}
