import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/tools/recipe/domain/amounts.dart';
import 'package:ozone/tools/recipe/domain/scan_parser.dart';

// Text fixtures for the scan parser (F4-03 §2). Each fixture line becomes a
// recognised line: `# ` = large print (a title), `~ ` = low confidence,
// `left || right` = two columns side by side, `---` = next page.
List<ScanPage> pages(String fixture) {
  final out = <ScanPage>[];
  for (final page in fixture.trim().split(RegExp(r'\n\s*---\s*\n'))) {
    final lines = <ScanLine>[];
    var top = 40.0;
    for (var raw in page.split('\n')) {
      raw = raw.trim();
      if (raw.isEmpty) continue;
      final cols = raw.split(' || ');
      for (var c = 0; c < cols.length; c++) {
        var t = cols[c].trim();
        if (t.isEmpty) continue;
        final big = t.startsWith('# '), low = t.startsWith('~ ');
        if (big || low) t = t.substring(2);
        lines.add(ScanLine(t, left: c == 0 ? 40 : 560, top: top, width: 400, height: big ? 32 : 18, confidence: low ? 0.4 : 0.95));
      }
      top += 28;
    }
    out.add(ScanPage(width: 1000, height: 2000, lines: lines));
  }
  return out;
}

ScanResult parse(String fixture) => parseScan(pages(fixture));
List<String> texts(ScanResult r, ScanLabel label) => [for (final l in r.lines.where((l) => l.label == label)) l.text];

void main() {
  test('1 · single column with headings', () {
    final r = parse('''
# Chicken Adobo
A family favourite.
Ingredients
1 kg chicken thighs
1/2 cup cane vinegar
1/3 cup soy sauce
8 cloves garlic, crushed
3 bay leaves
Method
1. Combine everything in a pot and marinate for 30 minutes.
2. Simmer, covered, until tender.
3. Serve with rice.
''');
    expect(r.title, 'Chicken Adobo');
    expect(texts(r, ScanLabel.ingredient), ['1 kg chicken thighs', '1/2 cup cane vinegar', '1/3 cup soy sauce', '8 cloves garlic, crushed', '3 bay leaves']);
    expect(texts(r, ScanLabel.step), ['Combine everything in a pot and marinate for 30 minutes.', 'Simmer, covered, until tender.', 'Serve with rice.']);
    expect(texts(r, ScanLabel.unused), ['A family favourite.']);
    expect(r.lineCount, 12);
  });

  test('2 · two columns: left column first, then right', () {
    final r = parse('''
# Sinigang na Baboy
Ingredients || Directions
1 kg pork ribs || 1. Boil the pork until tender.
2 tomatoes, quartered || 2. Add the tomatoes and onion.
1 onion, sliced || 3. Stir in the tamarind mix.
1 pack sinigang mix || 4. Add the vegetables and cook 5 minutes.
1 bunch kangkong || 5. Season with fish sauce.
''');
    expect(r.title, 'Sinigang na Baboy');
    expect(texts(r, ScanLabel.ingredient), ['1 kg pork ribs', '2 tomatoes, quartered', '1 onion, sliced', '1 pack sinigang mix', '1 bunch kangkong']);
    expect(texts(r, ScanLabel.step).first, 'Boil the pork until tender.');
    expect(texts(r, ScanLabel.step), hasLength(5));
  });

  test('3 · Filipino headings and units', () {
    final r = parse('''
# Ginisang Monggo
Mga Sangkap:
1 tasa monggo
5 butil bawang
1 sibuyas
2 kutsara patis
Paraan ng Pagluluto:
1. Pakuluan ang monggo hanggang lumambot.
2. Igisa ang bawang at sibuyas.
''');
    expect(texts(r, ScanLabel.ingredient), hasLength(4));
    final d = draftFromLines(title: r.title, lines: r.lines);
    expect(d.ingredients[0].unit, 'cup');
    expect(d.ingredients[1].unit, 'clove');
    expect(d.ingredients[1].keyName, 'garlic');
    expect(d.ingredients[3].unit, 'tbsp');
    expect(d.steps, ['Pakuluan ang monggo hanggang lumambot.', 'Igisa ang bawang at sibuyas.']);
  });

  test('4 · no headings: amounts are ingredients, numbers are steps', () {
    final r = parse('''
Pancakes
1 1/2 cups flour
1.5 cups milk
2 eggs
2 tbsp sugar
1) Whisk the dry ingredients.
2) Add the milk and eggs and whisk until smooth.
Fry in a buttered pan over medium heat until golden on both sides.
''');
    expect(r.title, 'Pancakes'); // no large print: the first line
    expect(texts(r, ScanLabel.ingredient), ['1 1/2 cups flour', '1.5 cups milk', '2 eggs', '2 tbsp sugar']);
    expect(texts(r, ScanLabel.step), ['Whisk the dry ingredients.', 'Add the milk and eggs and whisk until smooth.', 'Fry in a buttered pan over medium heat until golden on both sides.']);
  });

  test('5 · multi-page: pages are read in order', () {
    final r = parse('''
# Leche Flan
Ingredients
10 egg yolks
1 can condensed milk
1 can evaporated milk
---
Procedure
1. Caramelise the sugar in the llanera.
2. Mix the yolks and milks, strain, and pour in.
3. Steam for 40 minutes.
''');
    expect(texts(r, ScanLabel.ingredient), hasLength(3));
    expect(texts(r, ScanLabel.step), hasLength(3));
  });

  test('6 · sections inside ingredients', () {
    final r = parse('''
# Pork BBQ
Ingredients
2 lb pork shoulder
For the marinade:
1 cup soy sauce
1/2 cup banana ketchup
For the glaze:
1/4 cup brown sugar
''');
    final d = draftFromLines(title: r.title, lines: r.lines);
    expect(d.ingredients.map((i) => (i.section, i.name)), [
      (null, 'pork shoulder'),
      ('For the marinade', 'soy sauce'),
      ('For the marinade', 'banana ketchup'),
      ('For the glaze', 'brown sugar'),
    ]);
  });

  test('7 · ranges', () {
    final r = parse('''
# Garlic Rice
Ingredients
2-3 cloves garlic
2 to 3 tbsp oil
3–4 cups cooked rice
''');
    final d = draftFromLines(title: r.title, lines: r.lines);
    expect(d.ingredients.map((i) => (i.amount, i.unit)), [
      (const Amount(2000, 3000), 'clove'),
      (const Amount(2000, 3000), 'tbsp'),
      (const Amount(3000, 4000), 'cup'),
    ]);
  });

  test('8 · run-on steps and wrapped ingredients join', () {
    final r = parse('''
# Lumpia
Ingredients
1/2 kg ground pork
1 carrot, finely
chopped
2 tbsp soy sauce
Steps
1. Mix the pork, carrot and soy sauce
in a bowl until combined.
2. Roll in wrappers and fry
until golden.
''');
    expect(texts(r, ScanLabel.ingredient), ['1/2 kg ground pork', '1 carrot, finely chopped', '2 tbsp soy sauce']);
    expect(texts(r, ScanLabel.step), ['Mix the pork, carrot and soy sauce in a bowl until combined.', 'Roll in wrappers and fry until golden.']);
  });

  test('9 · page numbers and short scraps are Not used', () {
    final r = parse('''
# Turon
Ingredients
6 saba bananas
12 lumpia wrappers
112
---
p. 113
Method
1. Wrap each banana with sugar and fry.
Page 114
ab
''');
    expect(texts(r, ScanLabel.unused), ['112', 'p. 113', 'Page 114', 'ab']);
    expect(texts(r, ScanLabel.step), ['Wrap each banana with sugar and fry.']);
  });

  test('10 · servings', () {
    expect(parse('# Arroz Caldo\nServes 4\nIngredients\n1 cup rice').servings, 4);
    expect(parse('# Arroz Caldo\nMakes 6 servings\nIngredients\n1 cup rice').servings, 6);
    final r = parse('# Arroz Caldo\nYield: 8\nIngredients\n1 cup rice');
    expect(r.servings, 8);
    expect(texts(r, ScanLabel.unused), ['Yield: 8']);
  });

  test('11 · times', () {
    final r = parse('''
# Kare-Kare
Prep time: 20 mins · Cook time: 1 h 30 min
Ingredients
1 kg oxtail
''');
    expect((r.prepMin, r.cookMin), (20, 90));
    expect(parse('# Kare-Kare\nTotal: 1½ hours\nIngredients\n1 kg oxtail').cookMin, 90);
    expect(parse('# Kare-Kare\nPrep: 10 min\nTotal: 1 hr\nIngredients\n1 kg oxtail').cookMin, isNull);
    // Steps that mention minutes stay steps.
    expect(parse('# Kare-Kare\nAdd the beans and cook 5 minutes.').cookMin, isNull);
    final s = parse('# Kare-Kare\nMethod\nCook for 10 minutes.');
    expect(s.cookMin, isNull);
    expect(texts(s, ScanLabel.step), ['Cook for 10 minutes.']);
  });

  test('12 · OCR typos are flagged', () {
    final r = parse('''
# Adobo
Ingredients
1O cups water
2 tbsp vlnegar
~ 1 cup soy sauce
500g chicken
''');
    expect(r.lines.map(checkReason).toList(), ['Check: 1O?', 'Check: vlnegar?', 'Check: hard to read', null]);
    // A key name already on the phone isn't flagged.
    expect(checkReason(const ReadLine('2 pcs siling haba', ScanLabel.ingredient), knownKeys: {'siling haba'}), isNull);
    expect(checkReason(const ReadLine('2 pcs siling haba', ScanLabel.ingredient)), 'Check: siling haba?');
  });

  test('13 · notes and the draft', () {
    final r = parse('''
# Champorado
Ingredients
1 cup glutinous rice
Directions
1. Cook the rice in water until thick.
Tips
Use tablea for a richer taste.
''');
    final lines = [...r.lines, const ReadLine('Old scrap', ScanLabel.unused)];
    final d = draftFromLines(title: r.title, servings: 4, lines: lines);
    expect(d.title, 'Champorado');
    expect(d.servings, 4);
    expect(d.notes, 'Use tablea for a richer taste.');
    expect(d.steps, ['Cook the rice in water until thick.']);
    expect(d.ingredients.single.keyName, 'glutinous rice');
  });

  test('14 · empty scan', () {
    final r = parseScan([const ScanPage(width: 100, height: 100, lines: [])]);
    expect((r.title, r.lines.length, r.lineCount), ('', 0, 0));
  });

  test('15 · pieces of one printed line are joined (seen on the emulator)', () {
    ScanLine l(String t, double left, double top, double width) => ScanLine(t, left: left, top: top, width: width, height: 30);
    final r = parseScan([
      ScanPage(width: 1340, height: 1950, lines: [
        ScanLine('Pork Sinigang', left: 90, top: 90, width: 500, height: 64),
        l('Ingredients', 90, 300, 220),
        l('1 radish, sliced', 90, 541, 260),
        // Boxes as ML Kit gave them: a small '1' lower than the tall box beside it.
        ScanLine('1', left: 169, top: 615, width: 9, height: 19),
        ScanLine('pack sinigang mix', left: 190, top: 595, width: 268, height: 45),
        l('1 bunch kangkong', 90, 652, 300),
      ]),
    ]);
    expect(texts(r, ScanLabel.ingredient), ['1 radish, sliced', '1 pack sinigang mix', '1 bunch kangkong']);
    expect(r.lineCount, 5);
  });

  test('16 · times on a details line without separators', () {
    final r = parse('# Pork Sinigang\nServes 4 · Prep 15 min Cook 1 h\nIngredients\n1 kg pork ribs');
    expect((r.servings, r.prepMin, r.cookMin), (4, 15, 60));
  });

  test('ingredient lines', () {
    final i = ingredientFromLine('2 cups of rice');
    expect((i.amount, i.unit, i.name, i.keyName), (const Amount(2000), 'cup', 'rice', 'rice'));
    final j = ingredientFromLine('pinch salt');
    expect((j.amount, j.unit, j.name), (null, 'pinch', 'salt'));
    expect(ingredientFromLine('Salt to taste').name, 'Salt to taste');
  });
}
