import 'dart:io';

import 'package:flutter/foundation.dart';

/// A local, size-capped log of unexpected errors (docs/spec/F3-01 §5). It holds
/// the time, where it happened, the error's type and the code location only:
/// never the error message, which could quote what was typed. Nothing is sent
/// anywhere; the owner can share the file from Settings › About.
class ErrorLog {
  ErrorLog(Future<File> Function() file, {this.maxBytes = 64 * 1024, DateTime Function()? clock}) : _file = file, _clock = clock ?? DateTime.now;

  /// A log that keeps nothing (widget tests).
  ErrorLog.disabled() : _file = null, maxBytes = 0, _clock = DateTime.now;

  final Future<File> Function()? _file;
  final int maxBytes;
  final DateTime Function() _clock;

  /// Bumps when an entry is added or the log is cleared (About shows the count).
  final changes = ValueNotifier<int>(0);

  /// Appends one entry; when the file passes [maxBytes] the oldest half is dropped.
  Future<void> record(Object error, StackTrace? stack, {String where = 'app'}) async {
    final file = _file;
    if (file == null) return;
    try {
      final f = await file();
      final frames = (stack?.toString() ?? '').split('\n').where((l) => l.trim().isNotEmpty).take(8).map((l) => '    ${l.trim()}');
      final entry = '${_clock().toUtc().toIso8601String()} · $where · ${error.runtimeType}\n${frames.join('\n')}\n';
      var text = await f.exists() ? await f.readAsString() : '';
      text += entry;
      if (text.length > maxBytes) {
        final cut = text.indexOf('\n20', text.length - maxBytes ~/ 2);
        text = cut < 0 ? entry : text.substring(cut + 1);
      }
      await f.parent.create(recursive: true);
      await f.writeAsString(text, flush: true);
      changes.value++;
    } on Object {
      // The log must never cause a second error.
    }
  }

  /// Number of entries in the log.
  Future<int> count() async {
    final f = await file();
    if (f == null || !await f.exists()) return 0;
    return RegExp(r'^\d{4}-', multiLine: true).allMatches(await f.readAsString()).length;
  }

  Future<File?> file() async => _file == null ? null : _file();

  Future<void> clear() async {
    final f = await file();
    if (f != null && await f.exists()) await f.delete();
    changes.value++;
  }
}
