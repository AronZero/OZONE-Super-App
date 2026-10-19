import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/tools/recipe/data/scan_pages.dart';
import 'package:ozone/tools/recipe/domain/scan_parser.dart';

import '../../helpers/harness.dart';
import 'recipe_flow_test.dart' show tapVisible;
import 'scan_parser_test.dart' show pages;

/// A 1×1 PNG, so Image.file has something real to show.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

class _FakeReader implements PageReader {
  _FakeReader(this.pages);
  final List<ScanPage> pages;
  int reads = 0;
  bool closed = false;

  @override
  Future<ScanPage> read(String path, Size size) async => pages[reads++];

  @override
  Future<void> close() async => closed = true;
}

const _adobo = '''
# Chicken Adobo
Serves 4
Ingredients
1 kg chicken thighs
1/2 cup vlnegar
8 cloves garlic
Method
1. Marinate the chicken for 30 minutes.
2. Simmer until tender.
p. 112
''';

void main() {
  late Directory tmp;
  late _FakeReader reader;
  final picked = <String>[];

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('ozone_scan');
    picked.clear();
  });
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  List<Object> overrides(String fixture) {
    reader = _FakeReader(pages(fixture));
    return [
      pagePickerProvider.overrideWithValue((source) async {
        final f = File('${tmp.path}/picked_${picked.length}.png')..writeAsBytesSync(_png);
        picked.add(f.path);
        return f.path;
      }),
      pictureSizeProvider.overrideWithValue((path) async => const Size(1000, 1400)),
      pageStraightenerProvider.overrideWithValue((picture, corners, turns, out) async => const Size(1000, 2000)),
      pageReaderProvider.overrideWithValue(() => reader),
      scanCacheProvider.overrideWithValue(() async => Directory('${tmp.path}/scan')),
    ];
  }

  testWidgets('From a photo → read → check → form → save', (tester) async {
    final (db, _) = await pumpApp(tester, initialLocation: '/recipe', overrides: overrides(_adobo).cast());
    await tester.tap(find.byTooltip('Add recipe'));
    await settle(tester);
    expect(find.text('Type it in'), findsOneWidget);
    await tester.tap(find.text('From a photo'));
    await settle(tester);

    // Step 1: one page picked, corners and the privacy line shown.
    expect(find.text('Scan a page'), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Text is read on your phone. Nothing is uploaded.'), findsOneWidget);
    expect(find.bySemanticsLabel('Top left corner'), findsOneWidget);
    await tester.tap(find.byTooltip('Rotate'));
    await settle(tester);
    await tester.tap(find.text('Read text'));
    await settle(tester);

    // From a photo asks once whether the picture becomes the recipe's photo.
    expect(find.text('Use this picture as the recipe’s photo?'), findsOneWidget);
    await tester.tap(find.text('No'));
    await settle(tester);
    expect(reader.closed, isTrue);

    // Step 2: what was read.
    expect(find.text('Check what was read'), findsOneWidget);
    expect(find.text('1 page · 10 lines read'), findsOneWidget);
    expect(find.text('Servings: 4'), findsOneWidget);
    expect(find.text('Check: vlnegar?'), findsOneWidget);
    expect(find.text('1 line may be misread. It’s marked Check.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Marinate the chicken for 30 minutes.'), 200, scrollable: find.byType(Scrollable).first);
    await tester.scrollUntilVisible(find.text('1/2 cup vlnegar'), -200, scrollable: find.byType(Scrollable).first);

    // Fix the misread line by long-pressing it.
    await tester.longPress(find.text('1/2 cup vlnegar'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, '1/2 cup vlnegar'), '1/2 cup vinegar');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Check: vlnegar?'), findsNothing);

    // The move button opens a menu of the groups; the line moves only when one is picked.
    // ("Serves 4" and "p. 112" are Not used; p. 112 is the last line.)
    await tester.scrollUntilVisible(find.text('p. 112'), 200, scrollable: find.byType(Scrollable).first);
    await tapVisible(tester, find.byTooltip('Not used. Move to another group').last);
    expect(find.text('Ingredients'), findsOneWidget);
    await tester.tap(find.text('Notes'));
    await settle(tester);
    expect(find.text('Moved to Notes'), findsOneWidget);
    expect(find.byTooltip('Note. Move to another group'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Note. Move to another group'));
    await tester.tap(find.text('Not used').last);
    await settle(tester);
    expect(find.byTooltip('Not used. Move to another group'), findsNWidgets(2));

    await tapVisible(tester, find.text('Continue to recipe'));
    expect(find.text('New recipe'), findsOneWidget);
    expect(find.text('Filled in from your scan. Give it a look.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Chicken Adobo'), findsOneWidget);
    await tapVisible(tester, find.text('Save recipe'));

    final r = await tester.runAsync(() => db.select(db.recipes).getSingle());
    expect((r!.title, r.servings, r.photoFile), ('Chicken Adobo', 4, null));
    final ings = await tester.runAsync(() => db.select(db.recipeIngredients).get());
    expect(ings!.map((i) => i.name), ['chicken thighs', 'vinegar', 'garlic']);
    final steps = await tester.runAsync(() => db.select(db.recipeSteps).get());
    expect(steps!.map((s) => s.body), ['Marinate the chicken for 30 minutes.', 'Simmer until tender.']);

    // The scan left no files behind.
    expect(Directory('${tmp.path}/scan').existsSync(), isFalse);
    expect(picked.where((p) => File(p).existsSync()), isEmpty);
    await closeApp(tester, db);
  });

  testWidgets('a page without text offers Retake', (tester) async {
    final (db, _) = await pumpApp(tester, initialLocation: '/recipe/scan', overrides: overrides('# x').cast());
    reader.pages[0] = const ScanPage(width: 1, height: 1, lines: []);
    await tester.tap(find.text('Read text'));
    await settle(tester);
    expect(find.text('No text found on this page'), findsOneWidget);
    expect(find.text('Retake page 1'), findsOneWidget);
    await closeApp(tester, db);
  });

  test('homography maps the corners onto the rectangle', () {
    const from = [Offset(10, 20), Offset(900, 5), Offset(950, 1300), Offset(30, 1250)];
    const to = [Offset.zero, Offset(800, 0), Offset(800, 1100), Offset(0, 1100)];
    final h = homography(from, to);
    for (var i = 0; i < 4; i++) {
      final (x, y) = (from[i].dx, from[i].dy);
      final w = h[6] * x + h[7] * y + h[8];
      expect((h[0] * x + h[1] * y + h[2]) / w, closeTo(to[i].dx, 1e-6));
      expect((h[3] * x + h[4] * y + h[5]) / w, closeTo(to[i].dy, 1e-6));
    }
    expect(unturn(const Offset(1, 0), 1), const Offset(0, 0));
    expect(unturn(const Offset(0, 1), 3), const Offset(0, 0));
  });
}
