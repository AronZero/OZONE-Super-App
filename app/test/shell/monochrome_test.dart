import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/ui/components/components.dart';
import 'package:ozone/core/ui/theme/app_theme.dart';
import 'package:ozone/core/ui/theme/tokens.dart';

import '../helpers/harness.dart';

Finder bar(String label) => find.byKey(ValueKey('bar-$label'));

OzoneColors colorsAt(WidgetTester tester, Finder f) => OzoneThemeColors.of(tester.element(f.first));

void main() {
  testWidgets('Appearance › Monochrome greys the active theme and is remembered', (tester) async {
    final (db, _) = await pumpApp(tester);
    expect(colorsAt(tester, find.text('Home')).mono, isFalse);

    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    await tester.tap(find.text('Appearance'));
    await settle(tester);
    final sw = find.byType(Switch).first;
    await tester.ensureVisible(sw);
    await tester.pumpAndSettle();
    // TalkBack reads the row alone, not the whole screen.
    final node = tester.getSemantics(sw);
    expect(node.label, contains('Monochrome'));
    expect(node.label, isNot(contains('Text size')));
    expect(node.label, isNot(contains('Theme')));
    await tester.tap(sw);
    await settle(tester);
    expect(await SettingsRepo(db).get(SettingKeys.monochrome), isTrue);
    expect(colorsAt(tester, find.text('Theme')), same(OzoneColors.monoLight));

    // Switching to Dark keeps Monochrome on: it recolours whichever theme is active.
    await tester.tap(find.bySemanticsLabel('Dark theme'));
    await settle(tester);
    expect(colorsAt(tester, find.text('Theme')), same(OzoneColors.monoDark));
    await closeApp(tester, db);
  });

  testWidgets('in Monochrome tool colours are ink and the selected Finance tab is solid ink', (tester) async {
    final db = memoryDb();
    await SettingsRepo(db).set(SettingKeys.monochrome, true);
    await pumpApp(tester, db: db);
    final c = colorsAt(tester, find.text('Home'));
    expect(ToolTint.finance.accentOf(tester.element(find.text('Home').first)), c.ink);
    expect(ToolTint.notes.cardOf(tester.element(find.text('Home').first)), c.surface);
    expect(ToolTint.library.tileOf(tester.element(find.text('Home').first)), c.surfaceSunken);

    await tester.tap(bar('Finance'));
    await settle(tester);
    final pill = tester.widget<DecoratedBox>(find.byKey(SegmentTabs.pillKey));
    expect((pill.decoration as BoxDecoration).color, c.ink);
    await closeApp(tester, db);
  });

  testWidgets('pill chips are never narrower than PillSize.minWidth ("All" stays a pill)', (tester) async {
    final (db, _) = await pumpApp(tester);
    await tester.tap(find.byTooltip('Search'));
    await settle(tester);
    expect(tester.getSize(find.ancestor(of: find.text('All'), matching: find.byType(Material)).first).width,
        greaterThanOrEqualTo(PillSize.minWidth));
    await closeApp(tester, db);
  });

  test('badges and buttons on a tool card stay visible: onCard differs from the card', () {
    for (final c in [OzoneColors.monoLight, OzoneColors.monoDark]) {
      expect(c.onCard, isNot(c.surface));
    }
    expect(OzoneColors.light.onCard, OzoneColors.light.surface);
  });
}
