import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/platform/error_log.dart';
import 'package:ozone/core/ui/components/states.dart';
import 'package:ozone/core/ui/theme/app_theme.dart';

/// W3 States: skeleton after 300 ms, load error with Try again, failed save kept.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(ProviderScope(
        child: MaterialApp(theme: buildOzoneTheme(Brightness.light), home: Scaffold(body: child)),
      ));

  testWidgets('the skeleton appears only after 300 ms', (tester) async {
    await pump(tester, AsyncBody<int>(value: const AsyncLoading(), what: 'Savings', onRetry: () {}, builder: (d) => Text('$d')));
    expect(find.bySemanticsLabel('Loading'), findsNothing);
    await tester.pump(const Duration(milliseconds: 299));
    expect(find.bySemanticsLabel('Loading'), findsNothing);
    await tester.pump(const Duration(milliseconds: 2));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('data shows at once', (tester) async {
    await pump(tester, AsyncBody<int>(value: const AsyncData(7), what: 'Savings', onRetry: () {}, builder: (d) => Text('$d')));
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('a load error says what failed and offers Try again', (tester) async {
    var retried = 0;
    await pump(
      tester,
      AsyncBody<int>(value: AsyncError(StateError('db'), StackTrace.empty), what: 'Gold', onRetry: () => retried++, builder: (d) => Text('$d')),
    );
    expect(find.text('Gold couldn’t be loaded'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('a failed save asks to try again and reports the outcome', (tester) async {
    late BuildContext ctx;
    await pump(tester, Builder(builder: (context) {
      ctx = context;
      return const SizedBox();
    }));
    var calls = 0;
    final result = guardSave(ctx, ErrorLog.disabled(), () async {
      calls++;
      if (calls == 1) throw const FileSystemExceptionStub();
    });
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t save'), findsOneWidget);
    expect(find.textContaining('What you typed is kept'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(calls, 2);
  });

  testWidgets('Not now leaves the form open (save returns false)', (tester) async {
    late BuildContext ctx;
    await pump(tester, Builder(builder: (context) {
      ctx = context;
      return const SizedBox();
    }));
    final result = guardSave(ctx, ErrorLog.disabled(), () async => throw const FileSystemExceptionStub());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });
}

class FileSystemExceptionStub implements Exception {
  const FileSystemExceptionStub();
}
