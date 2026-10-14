import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/ids.dart';
import 'tables.dart';

part 'database.g.dart';

/// The one OZONE database: `ozone.db` in app-private storage (F1-01).
/// Every schema change needs a new [schemaVersion], a migration step and a
/// migration test (F1-01 §6, F3-03).
@DriftDatabase(tables: [
  AppMeta,
  Settings,
  Deletions,
  ExportsLog,
  SavingsAccounts,
  BalanceUpdates,
  GoldItems,
  KaratPrices,
  Expenses,
  Books,
  Folders,
  Tags,
  Notes,
  NoteTags,
  NoteDrafts,
  Vault,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the on-phone database file.
  factory AppDatabase.open() => AppDatabase(
        driftDatabase(
          name: 'ozone',
          native: DriftNativeOptions(
            databasePath: () async => '${(await getApplicationSupportDirectory()).path}/ozone.db',
          ),
        ),
      );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Global search index (F2-02 §1). Filled from M7; locked and trashed notes are never added.
          await customStatement(
            'CREATE VIRTUAL TABLE search_index USING fts5('
            'tool, entity, record_id UNINDEXED, title, body, extra, label UNINDEXED, '
            'tokenize = "unicode61 remove_diacritics 2")',
          );
          final now = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
          await batch((b) => b.insertAll(appMeta, [
                AppMetaCompanion.insert(key: 'schema_version', value: '1'),
                AppMetaCompanion.insert(key: 'install_id', value: newId()),
                AppMetaCompanion.insert(key: 'first_run_at', value: now),
              ]));
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
