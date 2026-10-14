import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/ui/components/components.dart';

import '../helpers/harness.dart';

Finder bar(String label) => find.byKey(ValueKey('bar-$label'));

void main() {
  testWidgets('default bar: Home, Finance, Library, Notes, Tools; tabs switch', (tester) async {
    final (db, _) = await pumpApp(tester);
    for (final l in ['Home', 'Finance', 'Library', 'Notes', 'Tools']) {
      expect(bar(l), findsOneWidget, reason: l);
    }
    await tester.tap(bar('Library'));
    await settle(tester);
    expect(find.text('Your books arrive in milestone M4.'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('Edit bar: removing a tool updates the bar; the launcher still opens it', (tester) async {
    final (db, _) = await pumpApp(tester);
    await tester.tap(bar('Tools'));
    await settle(tester);
    await tester.tap(find.text('Edit bar'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Remove Library from the bar'));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);

    expect(bar('Library'), findsNothing);
    expect(await SettingsRepo(db).get(SettingKeys.barTools), ['finance', 'notes']);

    // Opening Library from the launcher keeps "Tools" as the active tab.
    final libraryTile = find.text('Library').last;
    await tester.ensureVisible(libraryTile);
    await tester.pumpAndSettle();
    await tester.tap(libraryTile);
    await settle(tester);
    expect(find.text('Your books arrive in milestone M4.'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('Appearance: choosing Dark switches the app to dark', (tester) async {
    final (db, _) = await pumpApp(tester);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    await tester.tap(find.text('Appearance'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Dark theme'));
    await settle(tester);
    expect(Theme.of(tester.element(find.text('Theme'))).brightness, Brightness.dark);
    expect(await SettingsRepo(db).get(SettingKeys.theme), ThemeChoice.dark);
    await closeApp(tester, db);
  });

  testWidgets('Dashboard arrange: hiding a widget removes it from Home', (tester) async {
    final (db, _) = await pumpApp(tester);
    expect(find.text('Total savings'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    await tester.tap(find.text('Home dashboard'));
    await settle(tester);
    await tester.tap(find.byWidgetPredicate((w) => w is OzoneSwitch && w.label == 'Show Total savings'));
    await settle(tester);
    await tester.tap(find.byTooltip('Back to Settings'));
    await settle(tester);
    await tester.tap(find.byTooltip('Back to Home'));
    await settle(tester);
    expect(find.text('Total savings'), findsNothing);
    await closeApp(tester, db);
  });

  testWidgets('App lock on: the gate covers the app until unlocked', (tester) async {
    final db = memoryDb();
    await tester.runAsync(() => SettingsRepo(db).set(SettingKeys.appLock, const AppLockSetting(on: true, relockAfterS: 60)));
    final (_, lock) = await pumpApp(tester, db: db);
    // The fake phone lock succeeds at once, so the auto prompt unlocks.
    await settle(tester);
    expect(lock.locked.value, isFalse);
    expect(find.text('OZONE is locked'), findsNothing);
    await closeApp(tester, db);
  });
}
