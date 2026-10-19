import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/shell/ui/ozone_mark.dart';
import 'package:ozone/shell/ui/splash/splash_overlay.dart';

import '../helpers/harness.dart';

Finder _splash() => find.byType(SplashOverlay);
Finder _word() => find.descendant(of: _splash(), matching: find.text('OZONE'));

OzoneMarkPainter _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.descendant(of: _splash(), matching: find.byWidgetPredicate((w) => w is CustomPaint && w.painter is OzoneMarkPainter)))
    .painter! as OzoneMarkPainter;

void main() {
  testWidgets('The Bond plays over Home, then gets out of the way (UR4-1)', (tester) async {
    final (db, _) = await pumpApp(tester, splash: true);
    await tester.pump();
    expect(splashActive.value, isTrue);
    // Starts as Android's splash: the mark at rest, no name yet.
    expect(_painter(tester).spread, 0);
    expect(_word(), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    expect(_painter(tester).spread, greaterThan(0.8)); // atoms apart
    expect(_painter(tester).core, 0);

    await tester.pump(const Duration(milliseconds: 450)); // ~850 ms: core lit, name rising
    expect(_painter(tester).core, 1);
    expect(_word(), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(_word(), findsNothing);
    expect(splashActive.value, isFalse);
    await settle(tester);
    expect(find.text('Home'), findsWidgets);
    await closeApp(tester, db);
  });

  testWidgets('a tap skips to the fade', (tester) async {
    final (db, _) = await pumpApp(tester, splash: true);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(_splash());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 190));
    await tester.pump();
    expect(splashActive.value, isFalse);
    await settle(tester);
    await closeApp(tester, db);
  });

  testWidgets('Reduce motion: no movement, name at once, short fade', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final (db, _) = await pumpApp(tester, splash: true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_painter(tester).spread, 0);
    expect(_word(), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 420));
    await tester.pump();
    expect(splashActive.value, isFalse);
    await settle(tester);
    await closeApp(tester, db);
  });

  testWidgets('with app lock on, the phone is asked only after the splash', (tester) async {
    final db = memoryDb();
    await tester.runAsync(() => SettingsRepo(db).set(SettingKeys.appLock, const AppLockSetting(on: true, relockAfterS: 60)));
    final auth = FakeDeviceAuth();
    await pumpApp(tester, db: db, auth: auth, splash: true);
    await tester.pump(const Duration(milliseconds: 600));
    expect(auth.prompts, 0);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(auth.prompts, 1);
    await settle(tester);
    await closeApp(tester, db);
  });
}
