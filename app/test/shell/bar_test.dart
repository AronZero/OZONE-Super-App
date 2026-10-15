import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ozone/shell/ui/ozone_mark.dart';

import '../helpers/harness.dart';

Finder bar(String label) => find.byKey(ValueKey('bar-$label'));

/// The bar's slide (hidden while scrolling down).
Offset barOffset(WidgetTester tester) =>
    tester.widget<AnimatedSlide>(find.ancestor(of: bar('Home'), matching: find.byType(AnimatedSlide))).offset;

/// Home's add button distance from the bottom of the screen.
double addButtonBottom(WidgetTester tester) => tester.getBottomLeft(find.byTooltip('Quick add')).dy;

/// A short phone, so Home's dashboard scrolls.
void shortScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 560 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('only the active item shows its label; it is announced as selected', (tester) async {
    final (db, _) = await pumpApp(tester);
    double labelOpacity(String l) =>
        tester.widget<Opacity>(find.ancestor(of: find.descendant(of: bar(l), matching: find.text(l)), matching: find.byType(Opacity)).first).opacity;
    expect(labelOpacity('Home'), 1);
    expect(labelOpacity('Finance'), 0);
    expect(tester.getSemantics(find.descendant(of: bar('Home'), matching: find.byType(GestureDetector))),
        isSemantics(isSelected: true, label: 'Home', isButton: true));
    expect(tester.getSemantics(find.descendant(of: bar('Finance'), matching: find.byType(GestureDetector))),
        isSemantics(isSelected: false, label: 'Finance'));

    await tester.tap(bar('Finance'));
    await settle(tester);
    expect(labelOpacity('Finance'), 1);
    expect(labelOpacity('Home'), 0);
    expect(tester.getSize(bar('Finance')).width, greaterThan(tester.getSize(bar('Home')).width));
    await closeApp(tester, db);
  });

  testWidgets('changing tab gives a selection haptic; tapping the current tab does not', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final (db, _) = await pumpApp(tester);
    bool haptic(MethodCall c) => c.method == 'HapticFeedback.vibrate' && c.arguments == 'HapticFeedbackType.selectionClick';

    await tester.tap(bar('Home'));
    await settle(tester);
    expect(calls.where(haptic), isEmpty);
    await tester.tap(bar('Library'));
    await settle(tester);
    expect(calls.where(haptic), hasLength(1));
    await closeApp(tester, db);
  });

  testWidgets('scrolling down hides the bar and lowers the add button; scrolling up brings them back', (tester) async {
    shortScreen(tester);
    final (db, _) = await pumpApp(tester);
    final raised = addButtonBottom(tester);
    expect(barOffset(tester), Offset.zero);

    await tester.drag(find.text('Home').first, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(barOffset(tester).dy, greaterThan(0));
    expect(addButtonBottom(tester), greaterThan(raised));

    await tester.drag(find.byType(ListView).first, const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(barOffset(tester), Offset.zero);
    expect(addButtonBottom(tester), raised);
    await closeApp(tester, db);
  });

  testWidgets('with TalkBack on, the bar never hides', (tester) async {
    shortScreen(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final (db, _) = await pumpApp(tester);
    await tester.drag(find.text('Home').first, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(barOffset(tester), Offset.zero);
    await closeApp(tester, db);
  });

  testWidgets('Reduce motion: the bar changes in one frame', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final (db, _) = await pumpApp(tester);
    final activeWidth = tester.getSize(bar('Home')).width;
    await tester.tap(bar('Finance'));
    await tester.pump();
    await tester.pump();
    expect(tester.getSize(bar('Finance')).width, activeWidth);
    await settle(tester);
    await closeApp(tester, db);
  });

  testWidgets('Home shows the OZONE mark; the bar has no border and the add button no shadow', (tester) async {
    final (db, _) = await pumpApp(tester);
    expect(find.byType(OzoneMark), findsOneWidget);
    expect(tester.getSize(find.byType(OzoneMark)).width, greaterThanOrEqualTo(32));
    final barBox = tester.widget<Container>(find.ancestor(of: bar('Home'), matching: find.byType(Container)).first);
    expect((barBox.decoration! as BoxDecoration).border, isNull);
    final add = tester.widget<Material>(find.descendant(of: find.byTooltip('Quick add'), matching: find.byType(Material)).first);
    expect(add.elevation, 0);
    await closeApp(tester, db);
  });
}
