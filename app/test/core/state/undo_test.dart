import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/state/undo.dart';

void main() {
  test('commits after 5 s unless undone', () async {
    final u = UndoController(duration: const Duration(milliseconds: 50));
    var hidden = false, committed = false, restored = false;
    await u.run(message: 'Expense deleted', hideNow: () => hidden = true, commit: () async => committed = true, restore: () => restored = true);
    expect((hidden, committed), (true, false));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect((committed, restored), (true, false));
    expect(u.pending, isNull);
  });

  test('Undo restores and never commits', () async {
    final u = UndoController(duration: const Duration(milliseconds: 50));
    var committed = false, restored = false;
    await u.run(message: 'x', hideNow: () {}, commit: () async => committed = true, restore: () => restored = true);
    u.undo();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect((committed, restored), (false, true));
  });

  test('a second action commits the first at once', () async {
    final u = UndoController();
    final log = <String>[];
    await u.run(message: 'a', hideNow: () {}, commit: () async => log.add('a'), restore: () {});
    await u.run(message: 'b', hideNow: () {}, commit: () async => log.add('b'), restore: () {});
    expect(log, ['a']);
    expect(u.pending!.message, 'b');
    unawaited(u.flush());
  });
}
