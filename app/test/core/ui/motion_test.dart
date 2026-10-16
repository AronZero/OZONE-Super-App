import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/domain/money.dart';
import 'package:ozone/core/ui/amounts.dart';
import 'package:ozone/core/ui/components/components.dart';
import 'package:ozone/core/ui/components/states.dart';
import 'package:ozone/core/ui/motion.dart';
import 'package:ozone/core/ui/rolling_amount.dart';
import 'package:ozone/core/ui/theme/app_theme.dart';

/// UI refresh step 3 (canvas board "UI refresh · Step 3 · Motion").
void main() {
  Future<void> pump(WidgetTester tester, Widget child, {bool reduce = false}) => tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: buildOzoneTheme(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: Scaffold(body: child),
          ),
        ),
      ));

  double opacityOf(WidgetTester tester, String text) => tester
      .widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first)
      .opacity;

  test('staggered skips spacers and top bars and stops after six cards', () {
    final out = staggered([
      const MainTopBar(title: 'Home'),
      for (var i = 0; i < 8; i++) ...[Text('$i'), const SizedBox(height: 8)],
    ]);
    expect(out.first, isA<MainTopBar>());
    expect(out.whereType<EnterItem>().map((e) => e.index), [0, 1, 2, 3, 4, 5]);
    expect(out.whereType<SizedBox>(), hasLength(8));
    expect(out.whereType<Text>().map((t) => t.data), ['6', '7']);
  });

  testWidgets('cards rise in one after another, and again when the screen opens again', (tester) async {
    final opens = ValueNotifier(0);
    addTearDown(opens.dispose);
    await pump(tester, EntranceScope(opens: opens, child: ListView(children: staggered([const Text('a'), const Text('b')]))));
    expect(opacityOf(tester, 'a'), 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester, 'a'), greaterThan(opacityOf(tester, 'b')));
    await tester.pumpAndSettle();
    expect(opacityOf(tester, 'b'), 1);

    opens.value++;
    await tester.pump();
    expect(opacityOf(tester, 'a'), 0);
    await tester.pumpAndSettle();
    expect(opacityOf(tester, 'a'), 1);
  });

  testWidgets('with Reduce motion cards are there at once', (tester) async {
    await pump(tester, ListView(children: staggered([const Text('a')])), reduce: true);
    expect(opacityOf(tester, 'a'), 1);
  });

  testWidgets('a held card sinks to 97 % and lets go when the finger scrolls', (tester) async {
    await pump(tester, Center(child: PressScale(scale: PressScale.card, child: const ColoredBox(color: Colors.black, child: SizedBox(width: 100, height: 100)))));
    double scale() => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
    final g = await tester.startGesture(tester.getCenter(find.byType(PressScale)));
    await tester.pump();
    expect(scale(), PressScale.card);
    await g.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(scale(), 1);
    await g.up();
  });

  testWidgets('the skeleton breathes, and holds still with Reduce motion', (tester) async {
    for (final reduce in [false, true]) {
      await pump(tester, const DelayedSkeleton(), reduce: reduce);
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pump(const Duration(milliseconds: 600));
      final o = find.descendant(of: find.byType(DelayedSkeleton), matching: find.byType(Opacity));
      expect(o, reduce ? findsNothing : findsWidgets);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('a big amount rolls from the old figure to the new one; TalkBack hears the new one', (tester) async {
    Widget at(int v) => RollingAmount(v, style: const TextStyle(fontSize: 32));
    await pump(tester, at(100000));
    expect(find.text('₱1,000.00'), findsOneWidget);
    await pump(tester, at(200000));
    await tester.pump(const Duration(milliseconds: 150));
    final mid = tester.widget<Text>(find.byType(Text)).data!;
    expect(mid, isNot(anyOf('₱1,000.00', '₱2,000.00')));
    expect(find.bySemanticsLabel(Money.spoken(200000)), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('₱2,000.00'), findsOneWidget);
  });

  testWidgets('Home figures count up each time Home opens; Reduce motion shows them at once', (tester) async {
    final opens = ValueNotifier(0);
    addTearDown(opens.dispose);
    Widget home() => EntranceScope(opens: opens, child: RollingAmount(500000, rollOnOpen: true, style: const TextStyle()));
    await pump(tester, home());
    expect(find.text('₱0.00'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('₱5,000.00'), findsOneWidget);
    opens.value++;
    await tester.pump();
    expect(find.text('₱0.00'), findsOneWidget);
    await tester.pumpAndSettle();
    await pump(tester, home(), reduce: true);
    opens.value++;
    await tester.pump();
    expect(find.text('₱5,000.00'), findsOneWidget);
  });

  testWidgets('hidden amounts show the dots', (tester) async {
    final v = AmountsVisibility(hidden: true);
    addTearDown(v.dispose);
    await pump(tester, AmountsScope(visibility: v, child: RollingAmount(100000, style: const TextStyle())));
    expect(find.text(Money.hidden), findsOneWidget);
    expect(find.bySemanticsLabel('amount hidden'), findsOneWidget);
  });

  testWidgets('a badge pops when its value changes, not when it first shows', (tester) async {
    Widget at(int v) => PopOnChange(value: v, pop: Pop.badge, child: Text('$v'));
    double scale() => tester.widget<Transform>(find.ancestor(of: find.byType(Text), matching: find.byType(Transform)).first).transform.storage[0];
    await pump(tester, at(1));
    expect(scale(), 1);
    await pump(tester, at(2));
    await tester.pump(const Duration(milliseconds: 50));
    expect(scale(), lessThan(1));
    await tester.pumpAndSettle();
    expect(scale(), 1);
  });

  group('delete and Undo in lists', () {
    Widget list(List<String> ids, {Object? scope}) => AnimatedRows(
          scope: scope,
          children: [const Text('header'), for (final id in ids) Text(id, key: ValueKey(id))],
          builder: (rows) => ListView(children: rows),
        );

    testWidgets('a deleted row slides away and the gap closes; Undo brings it back', (tester) async {
      await pump(tester, list(['a', 'b', 'c']));
      await pump(tester, list(['a', 'c']));
      expect(find.text('b'), findsOneWidget, reason: 'still leaving');
      await tester.pumpAndSettle();
      expect(find.text('b'), findsNothing);

      await pump(tester, list(['a', 'b', 'c']));
      final arriving = tester.getSize(find.ancestor(of: find.text('b'), matching: find.byType(SizeTransition))).height;
      await tester.pumpAndSettle();
      expect(tester.getSize(find.ancestor(of: find.text('b'), matching: find.byType(SizeTransition))).height, greaterThan(arriving));
    });

    testWidgets('a new filter or a big change just swaps the rows', (tester) async {
      await pump(tester, list(['a', 'b', 'c'], scope: 'all'));
      await pump(tester, list(['a'], scope: 'reading'));
      expect(find.text('b'), findsNothing);
      await pump(tester, list(['a', 'b', 'c', 'd', 'e'], scope: 'reading'));
      await pump(tester, list(['a'], scope: 'reading'));
      expect(find.text('b'), findsNothing);
    });

    testWidgets('with Reduce motion rows go at once', (tester) async {
      await pump(tester, list(['a', 'b']), reduce: true);
      await pump(tester, list(['a']), reduce: true);
      expect(find.text('b'), findsNothing);
    });
  });

  testWidgets('the tab pill slides to the tapped tab', (tester) async {
    var selected = 0;
    await pump(tester, StatefulBuilder(
      builder: (context, setState) => SegmentTabs(labels: const ['Savings', 'Gold', 'Expenses'], selected: selected, onSelected: (i) => setState(() => selected = i)),
    ));
    double pillX() => tester.getCenter(find.byKey(SegmentTabs.pillKey)).dx;
    final start = pillX();
    await tester.tap(find.text('Expenses'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = pillX();
    await tester.pumpAndSettle();
    expect(mid, greaterThan(start));
    expect(pillX(), greaterThan(mid));
    expect(selected, 2);
  });

  testWidgets('Done: the circle pops in and the tick draws; still with Reduce motion', (tester) async {
    for (final reduce in [false, true]) {
      await pump(tester, const Center(child: DoneTick(background: Colors.black, foreground: Colors.white)), reduce: reduce);
      double scale() => tester.widget<Transform>(find.descendant(of: find.byType(DoneTick), matching: find.byType(Transform))).transform.storage[0];
      if (!reduce) {
        expect(scale(), lessThan(0.2));
        await tester.pumpAndSettle();
      }
      expect(scale(), 1);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
