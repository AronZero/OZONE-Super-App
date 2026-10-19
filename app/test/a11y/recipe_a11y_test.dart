import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/tools/recipe/data/recipes_repo.dart';
import 'package:ozone/tools/recipe/data/scan_pages.dart';
import 'package:ozone/tools/recipe/domain/scan_parser.dart';

import '../helpers/harness.dart';
import '../tools/recipe/recipes_repo_test.dart' show adobo;
import '../tools/recipe/scan_parser_test.dart' show pages;

/// Accessibility pass for the Recipe tool (M14, F4-03 §2), as a11y_test.dart does
/// for the rest: both themes, 100% and 200% text, the A03's screen; 48 dp touch
/// targets, labelled controls, no overflow, no raw ₱ for TalkBack.

final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

class _FakeReader implements PageReader {
  _FakeReader(this.pages);
  final List<ScanPage> pages;
  var _reads = 0;

  @override
  Future<ScanPage> read(String path, Size size) async => pages[_reads++ % pages.length];

  @override
  Future<void> close() async {}
}

const _page = '''
# Chicken Adobo With A Long Title That Wraps
Serves 4
Ingredients
1 kg chicken thighs
1/2 cup vlnegar
8 cloves garlic
Method
1. Marinate the chicken for 30 minutes, turning it now and then so every piece takes on the sauce.
2. Simmer until tender.
''';

Future<String> _seed(AppDatabase db, WidgetTester tester) async {
  late String id;
  await tester.runAsync(() async {
    final repo = RecipesRepo(db, DeletionsRepo(db), testPhotos());
    id = await repo.add(adobo(title: 'Chicken adobo with a long title that wraps'));
    await repo.add(adobo(title: 'Garlic fried rice'));
    await repo.setHave('chicken', true);
    await repo.setHave('soy sauce', true);
    final s = SettingsRepo(db);
    final d = await s.get(SettingKeys.dashboardWidgets);
    await s.set(SettingKeys.dashboardWidgets, [const WidgetSetting('recipe_cook', true), ...d.where((w) => w.id != 'recipe_cook')]);
  });
  return id;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader('Manrope')..addFont(rootBundle.load('assets/fonts/Manrope/Manrope-VariableFont_wght.ttf'))).load();
  });

  // Each screen: its route and, for the scan steps, the taps that reach it.
  final screens = <String, (String Function(String id), Future<void> Function(WidgetTester)?)>{
    'Home with What can I cook?': ((_) => '/home', null),
    'Recipes': ((_) => '/recipe', null),
    'Recipe': ((id) => '/recipe/$id', null),
    'Edit recipe': ((id) => '/recipe/$id/edit', null),
    'New recipe': ((_) => '/recipe/new', null),
    'What can I cook?': ((_) => '/recipe/cook', null),
    'Settings › Recipes': ((_) => '/settings/recipe', null),
    'Scan a page': ((_) => '/recipe/scan', null),
    'Check what was read': (
      (_) => '/recipe/scan?from=gallery',
      (tester) async {
        await tester.tap(find.text('Read text'));
        await settle(tester);
        await tester.tap(find.text('No'));
        await settle(tester);
        expect(find.text('Check what was read'), findsOneWidget);
      },
    ),
  };

  for (final MapEntry(key: name, value: (route, go)) in screens.entries) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$name · ${dark ? 'dark' : 'light'} · ${(scale * 100).round()}%', (tester) async {
          tester.view
            ..physicalSize = const Size(720, 1600)
            ..devicePixelRatio = 1.75;
          tester.platformDispatcher
            ..platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light
            ..textScaleFactorTestValue = scale;
          final tmp = Directory.systemTemp.createTempSync('ozone_a11y');
          addTearDown(() {
            tester.view.reset();
            tester.platformDispatcher.clearAllTestValues();
            if (tmp.existsSync()) tmp.deleteSync(recursive: true);
          });
          final semantics = tester.ensureSemantics();
          final db = memoryDb();
          final id = await _seed(db, tester);
          final reader = _FakeReader(pages(_page));
          await pumpApp(tester, db: db, initialLocation: route(id), overrides: [
            pagePickerProvider.overrideWithValue((source) async => (File('${tmp.path}/p.png')..writeAsBytesSync(_png)).path),
            pictureSizeProvider.overrideWithValue((path) async => const Size(1000, 1400)),
            pageStraightenerProvider.overrideWithValue((picture, corners, turns, out) async => const Size(1000, 2000)),
            pageReaderProvider.overrideWithValue(() => reader),
            scanCacheProvider.overrideWithValue(() async => Directory('${tmp.path}/scan')),
          ]);
          await go?.call(tester);

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          final raw = [for (final n in find.semantics.byPredicate((n) => n.label.contains('₱')).evaluate()) n.label];
          expect(raw, isEmpty, reason: 'amounts read with the peso sign');

          semantics.dispose();
          await closeApp(tester, db);
        });
      }
    }
  }
}
