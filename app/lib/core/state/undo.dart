import 'dart:async';

import 'package:flutter/foundation.dart';

/// An action that can still be undone (docs/spec/F2-02 §6).
class PendingUndo {
  PendingUndo(this.message, this._commit, this._undo);

  final String message;
  final Future<void> Function() _commit;
  final VoidCallback _undo;
}

/// Shows "Expense deleted · Undo" for 5 s. The record is hidden at once; the
/// real delete (and tombstone) runs when the message closes, when another
/// action replaces it, or when the app goes to the background.
class UndoController extends ChangeNotifier {
  UndoController({this.duration = const Duration(seconds: 5)});

  final Duration duration;
  PendingUndo? _pending;
  Timer? _timer;

  PendingUndo? get pending => _pending;

  /// [hideNow] runs immediately (remove from the list); [commit] runs later
  /// unless the user taps Undo, in which case [restore] runs instead.
  Future<void> run({
    required String message,
    required VoidCallback hideNow,
    required Future<void> Function() commit,
    required VoidCallback restore,
  }) async {
    await flush();
    hideNow();
    _pending = PendingUndo(message, commit, restore);
    _timer = Timer(duration, () => unawaited(flush()));
    notifyListeners();
  }

  void undo() {
    final p = _pending;
    if (p == null) return;
    _timer?.cancel();
    _pending = null;
    p._undo();
    notifyListeners();
  }

  /// Commits the pending action now (timer end, a new action, app background).
  Future<void> flush() async {
    final p = _pending;
    if (p == null) return;
    _timer?.cancel();
    _pending = null;
    notifyListeners();
    await p._commit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
