import 'package:drift/drift.dart';

import '../../../core/data/database.dart';
import '../../../core/data/deletions_repo.dart';
import '../../../core/data/watch.dart';
import '../../../core/domain/dates.dart';
import '../../../core/domain/ids.dart';
import '../domain/library.dart';

const String bookEntity = 'book';

/// All books, loaded together.
class BooksData {
  BooksData(this.rows);
  final List<BookRow> rows;

  late final List<BookFacts> facts = [for (final r in rows) toFacts(r)];
  late final LibraryStats stats = libraryStats(facts);

  BookRow? byId(String id) {
    for (final r in rows) {
      if (r.id == id) return r;
    }
    return null;
  }

  static BookFacts toFacts(BookRow r) => BookFacts(
        status: BookStatus.of(r.status),
        acquisition: Acquisition.of(r.acquisition),
        onKindle: r.onKindle,
        sizeKb: r.sizeKb,
        acquired: r.acquiredDate == null ? null : LocalDate.parseIso(r.acquiredDate!).valueOrNull,
        amount: r.amount,
        ratingHalf: r.ratingHalf,
      );
}

/// The fields of the book form.
class BookInput {
  const BookInput({
    required this.title,
    this.author,
    this.sizeKb,
    this.onKindle = false,
    required this.status,
    required this.acquisition,
    this.acquired,
    this.amount,
    this.ratingHalf,
    this.remarks,
  });

  final String title;
  final String? author;
  final int? sizeKb;
  final bool onKindle;
  final BookStatus status;
  final Acquisition acquisition;
  final LocalDate? acquired;

  /// Required for Purchased, null otherwise (checked by [checkAmount]).
  final int? amount;
  final int? ratingHalf;
  final String? remarks;
}

/// The only code that reads and writes books (F3-01 §1).
class BooksRepo {
  BooksRepo(this._db, this._deletions);

  final AppDatabase _db;
  final DeletionsRepo _deletions;

  static int _now() => DateTime.now().toUtc().millisecondsSinceEpoch;

  Future<BooksData> load() async => BooksData(await _db.select(_db.books).get());

  Stream<BooksData> watch() => watchTables(_db, [_db.books], load);

  BooksCompanion _fields(BookInput f) => BooksCompanion(
        title: Value(f.title),
        author: Value(f.author),
        sizeKb: Value(f.sizeKb),
        onKindle: Value(f.onKindle),
        status: Value(f.status.key),
        acquisition: Value(f.acquisition.key),
        acquiredDate: Value(f.acquired?.toIso()),
        // The amount belongs to Purchased only (F1-01).
        amount: Value(f.acquisition == Acquisition.purchased ? f.amount : null),
        ratingHalf: Value(f.ratingHalf),
        remarks: Value(f.remarks),
      );

  Future<String> add(BookInput f) async {
    final id = newId();
    final now = _now();
    await _db.into(_db.books).insert(_fields(f).copyWith(id: Value(id), createdAt: Value(now), updatedAt: Value(now)));
    return id;
  }

  /// Saves the form; `updated_at` moves only on a real change.
  Future<void> edit(String id, BookInput f) async {
    final cur = await (_db.select(_db.books)..where((b) => b.id.equals(id))).getSingle();
    final next = _fields(f);
    final same = cur.title == next.title.value &&
        cur.author == next.author.value &&
        cur.sizeKb == next.sizeKb.value &&
        cur.onKindle == next.onKindle.value &&
        cur.status == next.status.value &&
        cur.acquisition == next.acquisition.value &&
        cur.acquiredDate == next.acquiredDate.value &&
        cur.amount == next.amount.value &&
        cur.ratingHalf == next.ratingHalf.value &&
        cur.remarks == next.remarks.value;
    if (same) return;
    await (_db.update(_db.books)..where((b) => b.id.equals(id))).write(next.copyWith(updatedAt: Value(_now())));
  }

  /// Quick changes from Book detail.
  Future<void> setStatus(String id, BookStatus s) => (_db.update(_db.books)..where((b) => b.id.equals(id)))
      .write(BooksCompanion(status: Value(s.key), updatedAt: Value(_now())));

  Future<void> setRating(String id, int? half) {
    assert(half == null || (half >= 0 && half <= 10));
    return (_db.update(_db.books)..where((b) => b.id.equals(id)))
        .write(BooksCompanion(ratingHalf: Value(half), updatedAt: Value(_now())));
  }

  Future<BookRow> delete(String id) async {
    final row = await (_db.select(_db.books)..where((b) => b.id.equals(id))).getSingle();
    await (_db.delete(_db.books)..where((b) => b.id.equals(id))).go();
    return row;
  }

  Future<void> restore(BookRow row) => _db.into(_db.books).insertOnConflictUpdate(row);
  Future<void> recordDeleted(String id) => _deletions.record(bookEntity, id);
}
