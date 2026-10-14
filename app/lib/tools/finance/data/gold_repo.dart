import 'package:drift/drift.dart';

import '../../../core/data/database.dart';
import '../../../core/data/deletions_repo.dart';
import '../../../core/data/watch.dart';
import '../../../core/domain/dates.dart';
import '../../../core/domain/ids.dart';
import '../domain/gold.dart';

const String goldItemEntity = 'gold_item';
const String karatPriceEntity = 'karat_price';

/// Gold items and the full price history, loaded together.
class GoldData {
  GoldData(this.items, this.priceRows);

  final List<GoldItemRow> items;

  /// Every saved price, newest date first.
  final List<KaratPriceRow> priceRows;

  late final Map<int, KaratPrice> prices = currentPrices([for (final r in priceRows) toPrice(r)]);
  late final List<GoldPiece> pieces = [for (final i in items) toPiece(i)];
  late final GoldTotals totals = goldTotals(pieces, prices);
  late final List<GoldItemRow> held = [for (final i in items) if (i.status == 'held') i];
  late final List<GoldItemRow> disposed = [for (final i in items) if (i.status == 'disposed') i];

  static KaratPrice toPrice(KaratPriceRow r) => KaratPrice(r.karat, r.pricePerGram, LocalDate.parseIso(r.date).valueOrNull!);
  static GoldPiece toPiece(GoldItemRow i) =>
      GoldPiece(id: i.id, name: i.name, weightMg: i.weightMg, karat: i.karat, cost: i.cost, held: i.status == 'held');

  /// Value of one held item, or null when its karat has no price.
  int? valueOf(GoldItemRow i) {
    final p = prices[i.karat];
    return p == null ? null : itemValue(i.weightMg, p.pricePerGram);
  }
}

/// The fields of a gold item form.
class GoldItemInput {
  const GoldItemInput({
    required this.name,
    required this.weightMg,
    required this.karat,
    this.vendor,
    required this.purchaseDate,
    required this.cost,
    this.disposedDate,
    this.remarks,
  });

  final String name;
  final int weightMg;
  final int karat;
  final String? vendor;
  final LocalDate purchaseDate;
  final int cost;

  /// Set when the item is disposed (status `disposed`).
  final LocalDate? disposedDate;
  final String? remarks;
}

/// The only code that reads and writes gold tables (F3-01 §1).
class GoldRepo {
  GoldRepo(this._db, this._deletions);

  final AppDatabase _db;
  final DeletionsRepo _deletions;

  static int _now() => DateTime.now().toUtc().millisecondsSinceEpoch;

  Future<GoldData> load() async => GoldData(
        await _db.select(_db.goldItems).get(),
        await (_db.select(_db.karatPrices)..orderBy([(p) => OrderingTerm.desc(p.date), (p) => OrderingTerm.desc(p.karat)])).get(),
      );

  Stream<GoldData> watch() =>
      watchTables(_db, [_db.goldItems, _db.karatPrices], load);

  Future<String> addItem(GoldItemInput f) async {
    final id = newId();
    final now = _now();
    await _db.into(_db.goldItems).insert(GoldItemsCompanion.insert(
          id: id,
          name: f.name,
          weightMg: f.weightMg,
          karat: f.karat,
          vendor: Value(f.vendor),
          purchaseDate: f.purchaseDate.toIso(),
          cost: f.cost,
          status: Value(f.disposedDate == null ? 'held' : 'disposed'),
          disposedDate: Value(f.disposedDate?.toIso()),
          remarks: Value(f.remarks),
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  /// Saves the form. `updated_at` moves only when a field really changes.
  Future<void> editItem(String id, GoldItemInput f) async {
    final cur = await (_db.select(_db.goldItems)..where((x) => x.id.equals(id))).getSingle();
    final status = f.disposedDate == null ? 'held' : 'disposed';
    if (cur.name == f.name &&
        cur.weightMg == f.weightMg &&
        cur.karat == f.karat &&
        cur.vendor == f.vendor &&
        cur.purchaseDate == f.purchaseDate.toIso() &&
        cur.cost == f.cost &&
        cur.status == status &&
        cur.disposedDate == f.disposedDate?.toIso() &&
        cur.remarks == f.remarks) {
      return;
    }
    await (_db.update(_db.goldItems)..where((x) => x.id.equals(id))).write(GoldItemsCompanion(
      name: Value(f.name),
      weightMg: Value(f.weightMg),
      karat: Value(f.karat),
      vendor: Value(f.vendor),
      purchaseDate: Value(f.purchaseDate.toIso()),
      cost: Value(f.cost),
      status: Value(status),
      disposedDate: Value(f.disposedDate?.toIso()),
      remarks: Value(f.remarks),
      updatedAt: Value(_now()),
    ));
  }

  /// Removes an item now; [restoreItem] is Undo; [recordItemDeleted] writes the tombstone after.
  Future<GoldItemRow> deleteItem(String id) async {
    final row = await (_db.select(_db.goldItems)..where((x) => x.id.equals(id))).getSingle();
    await (_db.delete(_db.goldItems)..where((x) => x.id.equals(id))).go();
    return row;
  }

  Future<void> restoreItem(GoldItemRow row) => _db.into(_db.goldItems).insertOnConflictUpdate(row);
  Future<void> recordItemDeleted(String id) => _deletions.record(goldItemEntity, id);

  /// Saves prices for one date in one transaction. One price per karat per
  /// date: saving twice on a day replaces it (F1-01).
  Future<void> savePrices(LocalDate date, Map<int, int> pricePerGram) => _db.transaction(() async {
        final now = _now();
        for (final e in pricePerGram.entries) {
          final existing = await (_db.select(_db.karatPrices)
                ..where((p) => p.karat.equals(e.key) & p.date.equals(date.toIso())))
              .getSingleOrNull();
          if (existing == null) {
            await _db.into(_db.karatPrices).insert(KaratPricesCompanion.insert(
                  id: newId(),
                  karat: e.key,
                  pricePerGram: e.value,
                  date: date.toIso(),
                  createdAt: now,
                  updatedAt: now,
                ));
          } else if (existing.pricePerGram != e.value) {
            await (_db.update(_db.karatPrices)..where((p) => p.id.equals(existing.id)))
                .write(KaratPricesCompanion(pricePerGram: Value(e.value), updatedAt: Value(now)));
          }
        }
      });

  Future<KaratPriceRow> deletePrice(String id) async {
    final row = await (_db.select(_db.karatPrices)..where((p) => p.id.equals(id))).getSingle();
    await (_db.delete(_db.karatPrices)..where((p) => p.id.equals(id))).go();
    return row;
  }

  Future<void> restorePrice(KaratPriceRow row) => _db.into(_db.karatPrices).insertOnConflictUpdate(row);
  Future<void> recordPriceDeleted(String id) => _deletions.record(karatPriceEntity, id);
}
