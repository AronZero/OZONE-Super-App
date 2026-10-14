import 'package:drift/drift.dart';

import '../../../core/data/database.dart';
import '../../../core/data/deletions_repo.dart';
import '../../../core/data/watch.dart';
import '../../../core/domain/dates.dart';
import '../../../core/domain/ids.dart';
import '../domain/expenses.dart';

const String expenseEntity = 'expense';

/// All expenses, newest first.
class ExpensesData {
  ExpensesData(this.rows);
  final List<ExpenseRow> rows;

  late final List<Spend> spends = [for (final r in rows) toSpend(r)];

  ExpenseRow? byId(String id) {
    for (final r in rows) {
      if (r.id == id) return r;
    }
    return null;
  }

  static Spend toSpend(ExpenseRow r) => Spend(
        id: r.id,
        item: r.item,
        vendor: r.vendor,
        amount: r.amount,
        date: LocalDate.parseIso(r.date).valueOrNull!,
        refunded: r.isRefunded,
      );
}

class ExpenseInput {
  const ExpenseInput({required this.item, required this.vendor, required this.amount, required this.date, this.remarks});
  final String item;
  final String vendor;
  final int amount;
  final LocalDate date;
  final String? remarks;
}

/// The only code that reads and writes expenses (F3-01 §1).
class ExpensesRepo {
  ExpensesRepo(this._db, this._deletions);

  final AppDatabase _db;
  final DeletionsRepo _deletions;

  static int _now() => DateTime.now().toUtc().millisecondsSinceEpoch;

  Future<ExpensesData> load() async => ExpensesData(await (_db.select(_db.expenses)
        ..orderBy([(e) => OrderingTerm.desc(e.date), (e) => OrderingTerm.desc(e.createdAt)]))
      .get());

  Stream<ExpensesData> watch() =>
      watchTables(_db, [_db.expenses], load);

  Future<String> add(ExpenseInput f) async {
    final id = newId();
    final now = _now();
    await _db.into(_db.expenses).insert(ExpensesCompanion.insert(
          id: id,
          item: f.item,
          vendor: f.vendor,
          amount: f.amount,
          date: f.date.toIso(),
          remarks: Value(f.remarks),
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  Future<void> edit(String id, ExpenseInput f) async {
    final cur = await (_db.select(_db.expenses)..where((e) => e.id.equals(id))).getSingle();
    if (cur.item == f.item && cur.vendor == f.vendor && cur.amount == f.amount && cur.date == f.date.toIso() && cur.remarks == f.remarks) {
      return;
    }
    await (_db.update(_db.expenses)..where((e) => e.id.equals(id))).write(ExpensesCompanion(
      item: Value(f.item),
      vendor: Value(f.vendor),
      amount: Value(f.amount),
      date: Value(f.date.toIso()),
      remarks: Value(f.remarks),
      updatedAt: Value(_now()),
    ));
  }

  /// Marks or unmarks Refunded. `refunded_at` records when.
  Future<void> setRefunded(String id, bool refunded) {
    final now = _now();
    return (_db.update(_db.expenses)..where((e) => e.id.equals(id))).write(ExpensesCompanion(
      isRefunded: Value(refunded),
      refundedAt: Value(refunded ? now : null),
      updatedAt: Value(now),
    ));
  }

  Future<ExpenseRow> delete(String id) async {
    final row = await (_db.select(_db.expenses)..where((e) => e.id.equals(id))).getSingle();
    await (_db.delete(_db.expenses)..where((e) => e.id.equals(id))).go();
    return row;
  }

  Future<void> restore(ExpenseRow row) => _db.into(_db.expenses).insertOnConflictUpdate(row);
  Future<void> recordDeleted(String id) => _deletions.record(expenseEntity, id);
}
