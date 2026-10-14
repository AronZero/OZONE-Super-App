import 'package:drift/drift.dart';

import 'database.dart';

/// Tombstones for permanently deleted records (F1-01, F1-03 "deleted here").
class DeletionsRepo {
  DeletionsRepo(this._db);

  final AppDatabase _db;

  /// Records a deletion. Call inside the same transaction as the delete.
  Future<void> record(String entity, String recordId) =>
      _db.into(_db.deletions).insertOnConflictUpdate(DeletionsCompanion.insert(
            entity: entity,
            recordId: recordId,
            deletedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
          ));

  Future<bool> isDeleted(String entity, String recordId) async =>
      await (_db.select(_db.deletions)
            ..where((d) => d.entity.equals(entity) & d.recordId.equals(recordId)))
          .getSingleOrNull() !=
      null;
}
