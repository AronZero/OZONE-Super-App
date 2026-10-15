import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/ids.dart';
import '../search/search_index.dart';
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

  /// v1: every F1-01 table. v2 (M7): search keys and the triggers that keep the
  /// search index in step; the index is rebuilt for existing data.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Global search index and its triggers (F2-02 §1).
          await SearchIndex.install(this);
          final now = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
          await batch((b) => b.insertAll(appMeta, [
                AppMetaCompanion.insert(key: 'schema_version', value: '$schemaVersion'),
                AppMetaCompanion.insert(key: 'install_id', value: newId()),
                AppMetaCompanion.insert(key: 'first_run_at', value: now),
              ]));
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await SearchIndex.install(this);
            await SearchIndex.rebuild(this);
          }
          await into(appMeta).insertOnConflictUpdate(AppMetaCompanion.insert(key: 'schema_version', value: '$to'));
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
