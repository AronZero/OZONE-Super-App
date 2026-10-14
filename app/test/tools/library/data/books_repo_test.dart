import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/tools/library/data/books_repo.dart';
import 'package:ozone/tools/library/domain/library.dart';

import '../../../helpers/harness.dart';

void main() {
  late AppDatabase db;
  late BooksRepo repo;
  late DeletionsRepo deletions;

  setUp(() {
    db = memoryDb();
    deletions = DeletionsRepo(db);
    repo = BooksRepo(db, deletions);
  });
  tearDown(() => db.close());

  BookInput book({Acquisition a = Acquisition.purchased, int? amount = 59900, int? rating}) => BookInput(
        title: 'Project Hail Mary',
        author: 'Andy Weir',
        sizeKb: 4300,
        onKindle: true,
        status: BookStatus.reading,
        acquisition: a,
        acquired: LocalDate(2026, 9, 18),
        amount: amount,
        ratingHalf: rating,
      );

  test('the amount is dropped unless Purchased', () async {
    final id = await repo.add(book(a: Acquisition.free, amount: 59900));
    expect((await repo.load()).byId(id)!.amount, isNull);
    await repo.edit(id, book());
    expect((await repo.load()).byId(id)!.amount, 59900);
  });

  test('Not rated (null) stays distinct from 0 stars', () async {
    final id = await repo.add(book());
    expect((await repo.load()).byId(id)!.ratingHalf, isNull);
    await repo.setRating(id, 0);
    expect((await repo.load()).byId(id)!.ratingHalf, 0);
    await repo.setRating(id, null);
    expect((await repo.load()).byId(id)!.ratingHalf, isNull);
  });

  test('status changes; editing without changes keeps updated_at', () async {
    final id = await repo.add(book());
    await repo.setStatus(id, BookStatus.finished);
    final row = (await repo.load()).byId(id)!;
    expect(row.status, 'finished');
    await repo.edit(id, BookInput(
      title: row.title,
      author: row.author,
      sizeKb: row.sizeKb,
      onKindle: row.onKindle,
      status: BookStatus.finished,
      acquisition: Acquisition.purchased,
      acquired: LocalDate(2026, 9, 18),
      amount: row.amount,
    ));
    expect((await repo.load()).byId(id)!.updatedAt, row.updatedAt);
  });

  test('delete, Undo, then tombstone', () async {
    final id = await repo.add(book());
    final row = await repo.delete(id);
    await repo.restore(row);
    expect((await repo.load()).rows, hasLength(1));
    await repo.delete(id);
    await repo.recordDeleted(id);
    expect(await deletions.isDeleted(bookEntity, id), isTrue);
  });
}
