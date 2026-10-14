import 'dart:async';

import 'package:drift/drift.dart';

/// Emits [load] now and again after every write to [tables]. Repositories use
/// this for screens that show several related tables at once.
///
/// It listens to drift's table-update notifications directly, so a change is
/// never skipped as "the same result" (a stream query over `SELECT 1` can be).
/// Writes that arrive while a load runs are coalesced into one more load.
Stream<T> watchTables<T>(GeneratedDatabase db, Iterable<TableInfo<Table, dynamic>> tables, Future<T> Function() load) {
  late final StreamController<T> out;
  StreamSubscription<Set<TableUpdate>>? updates;
  var running = false, again = false, closed = false;

  Future<void> refresh() async {
    if (running) {
      again = true;
      return;
    }
    running = true;
    do {
      again = false;
      try {
        final v = await load();
        if (!closed) out.add(v);
      } on Object catch (e, s) {
        if (!closed) out.addError(e, s);
      }
    } while (again && !closed);
    running = false;
  }

  out = StreamController<T>(
    onListen: () {
      updates = db.tableUpdates(TableUpdateQuery.onAllTables(tables)).listen((_) => refresh());
      unawaited(refresh());
    },
    onCancel: () async {
      closed = true;
      await updates?.cancel();
    },
  );
  return out.stream;
}
