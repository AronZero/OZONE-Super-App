import 'package:drift/drift.dart';

import '../../../core/data/database.dart';
import '../../../core/data/deletions_repo.dart';
import '../../../core/data/settings_repo.dart';
import '../../../core/domain/dates.dart';
import '../../../core/domain/ids.dart';
import '../../../core/domain/validation.dart';
import '../domain/savings_history.dart';
import '../domain/savings_rules.dart';

/// Tombstone entity names (F1-03).
const String accountEntity = 'savings_account';
const String balanceUpdateEntity = 'balance_update';

/// Everything Savings screens show, loaded together so they stay consistent.
class SavingsData {
  SavingsData(this.accounts, this.updates);

  final List<SavingsAccountRow> accounts;

  /// Updates per account ID, oldest first.
  final Map<String, List<BalanceUpdateRow>> updates;

  late final List<AccountHistory> histories = [for (final a in accounts) toHistory(a)];
  late final List<AccountHistory> open = [for (final h in histories) if (!h.isArchived) h];
  late final List<SavingsAccountRow> archived = [for (final a in accounts) if (a.archivedAt != null) a];

  SavingsAccountRow? account(String id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  AccountHistory? history(String id) {
    for (final h in histories) {
      if (h.id == id) return h;
    }
    return null;
  }

  List<BalanceUpdateRow> updatesOf(String id) => updates[id] ?? const [];

  AccountHistory toHistory(SavingsAccountRow a) => AccountHistory(
        id: a.id,
        name: a.name,
        archivedAt: a.archivedAt == null ? null : LocalDate.parseIso(a.archivedAt!).valueOrNull,
        updates: [
          for (final u in updatesOf(a.id))
            BalancePoint(LocalDate.parseIso(u.date).valueOrNull!, u.balance, isUnchanged: u.isUnchanged),
        ],
      );
}

/// One row on the Update balances screen.
class UpdateEntry {
  const UpdateEntry(this.accountId, this.balance, {this.isUnchanged = false, this.remarks});
  final String accountId;
  final int balance;
  final bool isUnchanged;
  final String? remarks;
}

/// The only code that reads and writes savings tables (F3-01 §1).
class SavingsRepo {
  SavingsRepo(this._db, this._deletions, this._settings);

  final AppDatabase _db;
  final DeletionsRepo _deletions;
  final SettingsRepo _settings;

  static int _now() => DateTime.now().toUtc().millisecondsSinceEpoch;

  Future<SavingsData> load() async {
    final accounts = await _db.select(_db.savingsAccounts).get();
    final rows = await (_db.select(_db.balanceUpdates)..orderBy([(u) => OrderingTerm.asc(u.date)])).get();
    final byAccount = <String, List<BalanceUpdateRow>>{};
    for (final u in rows) {
      byAccount.putIfAbsent(u.accountId, () => []).add(u);
    }
    return SavingsData(accounts, byAccount);
  }

  /// Re-emits whenever an account or update changes.
  Stream<SavingsData> watch() => _db
      .customSelect('SELECT 1', readsFrom: {_db.savingsAccounts, _db.balanceUpdates})
      .watch()
      .asyncMap((_) => load());

  Future<List<String>> _openNames({String? except}) async {
    final q = _db.select(_db.savingsAccounts)..where((a) => a.archivedAt.isNull());
    return [for (final a in await q.get()) if (a.id != except) a.name];
  }

  static String _taken(String name) => 'You already have an account named “$name”. Use another name.';

  /// Adds an account with its starting balance in one transaction (F1-01).
  Future<Validation<String>> addAccount({
    required String name,
    String? platform,
    String? type,
    String? remarks,
    required int startBalance,
    required LocalDate asOf,
  }) async {
    if (nameTaken(name, await _openNames())) return Invalid(_taken(name));
    final id = newId();
    final now = _now();
    await _db.transaction(() async {
      await _db.into(_db.savingsAccounts).insert(SavingsAccountsCompanion.insert(
            id: id,
            name: name,
            platform: Value(platform),
            type: Value(type),
            remarks: Value(remarks),
            createdAt: now,
            updatedAt: now,
          ));
      await _db.into(_db.balanceUpdates).insert(BalanceUpdatesCompanion.insert(
            id: newId(),
            accountId: id,
            date: asOf.toIso(),
            balance: startBalance,
            createdAt: now,
            updatedAt: now,
          ));
    });
    return Ok(id);
  }

  /// Edits name, platform, type and remarks. `updated_at` moves only on a real change.
  Future<Validation<void>> editAccount(String id, {required String name, String? platform, String? type, String? remarks}) async {
    final a = await (_db.select(_db.savingsAccounts)..where((x) => x.id.equals(id))).getSingle();
    if (a.archivedAt == null && nameTaken(name, await _openNames(except: id))) return Invalid(_taken(name));
    if (a.name == name && a.platform == platform && a.type == type && a.remarks == remarks) return const Ok(null);
    await (_db.update(_db.savingsAccounts)..where((x) => x.id.equals(id))).write(SavingsAccountsCompanion(
      name: Value(name),
      platform: Value(platform),
      type: Value(type),
      remarks: Value(remarks),
      updatedAt: Value(_now()),
    ));
    return const Ok(null);
  }

  Future<void> archive(String id, LocalDate date) =>
      (_db.update(_db.savingsAccounts)..where((x) => x.id.equals(id)))
          .write(SavingsAccountsCompanion(archivedAt: Value(date.toIso()), updatedAt: Value(_now())));

  /// Brings an archived account back, unless an open account has its name.
  Future<Validation<void>> restore(String id) async {
    final a = await (_db.select(_db.savingsAccounts)..where((x) => x.id.equals(id))).getSingle();
    if (nameTaken(a.name, await _openNames(except: id))) {
      return Invalid('An open account is already named “${a.name}”. Rename one of them first.');
    }
    await (_db.update(_db.savingsAccounts)..where((x) => x.id.equals(id)))
        .write(SavingsAccountsCompanion(archivedAt: const Value(null), updatedAt: Value(_now())));
    return const Ok(null);
  }

  /// Deletes an account and its updates, with tombstones, in one transaction.
  Future<void> deleteAccount(String id) => _db.transaction(() async {
        final ups = await (_db.select(_db.balanceUpdates)..where((u) => u.accountId.equals(id))).get();
        for (final u in ups) {
          await _deletions.record(balanceUpdateEntity, u.id);
        }
        await (_db.delete(_db.balanceUpdates)..where((u) => u.accountId.equals(id))).go();
        await (_db.delete(_db.savingsAccounts)..where((a) => a.id.equals(id))).go();
        await _deletions.record(accountEntity, id);
      });

  /// Saves one update. One per account per date: saving again on a date replaces it (F1-01).
  Future<void> saveUpdate(String accountId, LocalDate date, int balance, {bool isUnchanged = false, String? remarks}) =>
      _db.transaction(() => _upsert(accountId, date, balance, isUnchanged, remarks, _now()));

  /// Saves every entry of the Update balances screen in one transaction.
  Future<void> saveUpdates(LocalDate date, List<UpdateEntry> entries) => _db.transaction(() async {
        final now = _now();
        for (final e in entries) {
          await _upsert(e.accountId, date, e.balance, e.isUnchanged, e.remarks, now);
        }
      });

  Future<void> _upsert(String accountId, LocalDate date, int balance, bool unchanged, String? remarks, int now) async {
    final existing = await (_db.select(_db.balanceUpdates)
          ..where((u) => u.accountId.equals(accountId) & u.date.equals(date.toIso())))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.balanceUpdates).insert(BalanceUpdatesCompanion.insert(
            id: newId(),
            accountId: accountId,
            date: date.toIso(),
            balance: balance,
            isUnchanged: Value(unchanged),
            remarks: Value(remarks),
            createdAt: now,
            updatedAt: now,
          ));
      return;
    }
    if (existing.balance == balance && existing.isUnchanged == unchanged && existing.remarks == remarks) return;
    await (_db.update(_db.balanceUpdates)..where((u) => u.id.equals(existing.id))).write(BalanceUpdatesCompanion(
      balance: Value(balance),
      isUnchanged: Value(unchanged),
      remarks: Value(remarks),
      updatedAt: Value(now),
    ));
  }

  /// Removes one update now; [restoreUpdate] puts it back (Undo), and
  /// [recordUpdateDeleted] writes the tombstone once Undo has expired.
  Future<BalanceUpdateRow> deleteUpdate(String id) async {
    final row = await (_db.select(_db.balanceUpdates)..where((u) => u.id.equals(id))).getSingle();
    await (_db.delete(_db.balanceUpdates)..where((u) => u.id.equals(id))).go();
    return row;
  }

  Future<void> restoreUpdate(BalanceUpdateRow row) => _db.into(_db.balanceUpdates).insertOnConflictUpdate(row);

  Future<void> recordUpdateDeleted(String id) => _deletions.record(balanceUpdateEntity, id);

  /// Platform or type suggestions: values already used, most used first, then
  /// most recent; minus those hidden in Settings › Lists (F1-01 §3).
  Future<List<String>> suggestions(SuggestionField field) async {
    final col = field == SuggestionField.platform ? 'platform' : 'type';
    final rows = await _db.customSelect(
      'SELECT $col AS v, COUNT(*) AS n, MAX(updated_at) AS t FROM savings_accounts '
      'WHERE $col IS NOT NULL AND $col <> \'\' GROUP BY $col ORDER BY n DESC, t DESC',
      readsFrom: {_db.savingsAccounts},
    ).get();
    final hidden = (await _settings.get(SettingKeys.listsHidden))[field.key] ?? const <String>[];
    final h = {for (final x in hidden) x.toLowerCase()};
    return [for (final r in rows) if (!h.contains(r.read<String>('v').toLowerCase())) r.read<String>('v')];
  }
}

enum SuggestionField {
  platform('platform'),
  type('type');

  const SuggestionField(this.key);

  /// Key inside the `lists.hidden` setting.
  final String key;
}
