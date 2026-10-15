import 'dart:async';

import 'package:flutter/foundation.dart';

/// Writes the editor's title and Delta ops somewhere (plain or sealed).
typedef NoteWrite = Future<void> Function(String title, List<Object?> ops);

/// Autosave and drafts for one open note (F2-02 §3):
/// - typing stops for 1 s → save, then "Saved";
/// - between saves, the typed state goes to `note_drafts` at most once a second;
/// - [saveNow] when the app goes to the background or the screen closes.
class NoteAutosave extends ChangeNotifier {
  NoteAutosave({
    required this.save,
    required this.draft,
    required this.read,
    this.idle = const Duration(seconds: 1),
    this.draftEvery = const Duration(seconds: 1),
  });

  final NoteWrite save;
  final NoteWrite draft;

  /// The editor's current title and Delta ops.
  final (String, List<Object?>) Function() read;
  final Duration idle;
  final Duration draftEvery;

  Timer? _idleTimer;
  Timer? _draftTimer;
  DateTime? _lastDraft;
  bool _dirty = false;
  Future<void> _chain = Future.value();

  /// True while there are changes not yet saved.
  bool get dirty => _dirty;

  /// Call on every change to the title or text.
  void changed() {
    final wasDirty = _dirty;
    _dirty = true;
    _idleTimer?.cancel();
    _idleTimer = Timer(idle, () => unawaited(saveNow()));
    _scheduleDraft();
    if (!wasDirty) notifyListeners();
  }

  void _scheduleDraft() {
    if (_draftTimer?.isActive ?? false) return;
    final since = _lastDraft == null ? draftEvery : DateTime.now().difference(_lastDraft!);
    final wait = since >= draftEvery ? Duration.zero : draftEvery - since;
    _draftTimer = Timer(wait, () {
      if (!_dirty) return;
      _lastDraft = DateTime.now();
      final (title, ops) = read();
      _run(() => draft(title, ops));
    });
  }

  /// Saves now if anything changed. Writes run one after another, so a draft
  /// never lands after the save that replaced it.
  Future<void> saveNow() {
    _idleTimer?.cancel();
    _draftTimer?.cancel();
    if (!_dirty) return _chain;
    _dirty = false;
    final (title, ops) = read();
    final done = _run(() => save(title, ops));
    notifyListeners();
    return done;
  }

  Future<void> _run(Future<void> Function() write) {
    _chain = _chain.then((_) => write()).then<void>((_) {}, onError: (Object e, StackTrace s) {
      // A failed write marks the note unsaved again, so the next change retries.
      _dirty = true;
      notifyListeners();
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s, library: 'notes autosave'));
    });
    return _chain;
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _draftTimer?.cancel();
    super.dispose();
  }
}
