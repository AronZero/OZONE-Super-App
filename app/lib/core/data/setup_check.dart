import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Result of the M0 setup check shown on Home.
class SetupCheckResult {
  const SetupCheckResult({required this.sqliteVersion, required this.fts5});

  final String sqliteVersion;
  final bool fts5;
}

/// Confirms the bundled SQLite opens on this phone and supports FTS5,
/// which global search depends on (docs/spec/F2-02 §1). Uses a throwaway
/// in-memory database, so nothing is written to the phone.
Future<SetupCheckResult> runSetupCheck() async {
  final db = _CheckDb();
  try {
    final version = await db.customSelect('SELECT sqlite_version() AS v').getSingle();
    var fts5 = true;
    try {
      await db.customStatement('CREATE VIRTUAL TABLE t USING fts5(body, tokenize = "unicode61 remove_diacritics 2")');
      await db.customStatement("INSERT INTO t(body) VALUES ('Café receipts')");
      final hit = await db.customSelect("SELECT count(*) AS n FROM t WHERE t MATCH 'cafe*'").getSingle();
      fts5 = hit.read<int>('n') == 1;
    } on Object {
      fts5 = false;
    }
    return SetupCheckResult(sqliteVersion: version.read<String>('v'), fts5: fts5);
  } finally {
    await db.close();
  }
}

class _CheckDb extends GeneratedDatabase {
  _CheckDb() : super(NativeDatabase.memory());

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}
