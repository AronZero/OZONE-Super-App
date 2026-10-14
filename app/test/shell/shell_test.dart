import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/app.dart';

void main() {
  testWidgets('bar shows Home, the 3 default tools and Tools; tabs switch', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OzoneApp()));
    await tester.pump();

    for (final label in ['Home', 'Finance', 'Library', 'Notes', 'Tools']) {
      expect(find.byKey(ValueKey('bar-$label')), findsOneWidget, reason: label);
    }

    await tester.tap(find.byKey(const ValueKey('bar-Library')));
    await tester.pumpAndSettle();
    expect(find.text('Your books arrive in milestone M4.'), findsOneWidget);
  });

  testWidgets('dark theme builds', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const ProviderScope(child: OzoneApp()));
    await tester.pump();
    expect(find.text('Home'), findsWidgets);
  });
}
