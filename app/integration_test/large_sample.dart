import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/domain/ids.dart';

/// The large sample set for performance checks (F3-03 §1, F2-03 §8): 10,000
/// rows and 500 notes, in a realistic mix. Generated on the test phone only;
/// never shipped in the app.
///
/// 20 accounts × 36 months = 720 balance updates · 4 karats × 36 months = 144
/// gold prices · 136 gold items · 8,000 expenses · 1,000 books = 10,000 rows.
Future<void> seedLargeSample(AppDatabase db) async {
  final now = DateTime.utc(2026, 10, 1).millisecondsSinceEpoch;
  String iso(int y, int m, int d) => '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  // Month i (0–35) runs from Oct 2023 to Sep 2026 (nothing after "today" in the tests).
  (int, int) month(int i) => (2023 + (9 + i) ~/ 12, (9 + i) % 12 + 1);
  int lastDay(int y, int m) => DateTime.utc(y, m + 1, 0).day;

  const vendors = ['SM Supermarket', 'Puregold', 'Mercury Drug', 'Shopee', 'Lazada', 'Jollibee', 'Meralco', 'Globe', 'Shell', 'National Book Store'];
  const items = ['Groceries', 'Medicine', 'Phone load', 'Fuel', 'Lunch', 'Electric bill', 'Internet', 'School supplies', 'Household', 'Snacks'];
  const words = ['plan', 'trip', 'budget', 'recipe', 'meeting', 'ideas', 'list', 'journal', 'project', 'notes'];

  await db.batch((b) {
    final accounts = [for (var a = 0; a < 20; a++) newId()];
    for (var a = 0; a < 20; a++) {
      b.insert(db.savingsAccounts, SavingsAccountsCompanion.insert(
        id: accounts[a], name: 'Account ${a + 1}', platform: Value(['BPI', 'BDO', 'GCash', 'Maya', 'UnionBank'][a % 5]), createdAt: now, updatedAt: now,
      ));
      for (var i = 0; i < 36; i++) {
        final (y, m) = month(i);
        b.insert(db.balanceUpdates, BalanceUpdatesCompanion.insert(
          id: newId(), accountId: accounts[a], date: iso(y, m, lastDay(y, m) > 30 ? 30 : lastDay(y, m)),
          balance: 5000000 + a * 250000 + i * 12345, isUnchanged: Value(i % 7 == 3), createdAt: now, updatedAt: now,
        ));
      }
    }
    for (final k in const [14, 18, 21, 24]) {
      for (var i = 0; i < 36; i++) {
        final (y, m) = month(i);
        b.insert(db.karatPrices, KaratPricesCompanion.insert(
          id: newId(), karat: k, pricePerGram: 300000 + k * 12000 + i * 1500, date: iso(y, m, 1), createdAt: now, updatedAt: now,
        ));
      }
    }
    for (var g = 0; g < 136; g++) {
      final (y, m) = month(g % 36);
      final disposed = g % 17 == 0;
      b.insert(db.goldItems, GoldItemsCompanion.insert(
        id: newId(), name: '${const ['Ring', 'Necklace', 'Bracelet', 'Earrings', 'Pendant'][g % 5]} ${g + 1}', weightMg: 1500 + g * 37,
        karat: const [14, 18, 21, 24][g % 4], vendor: Value('Goldsmith ${g % 6}'), purchaseDate: iso(y, m, 10), cost: 800000 + g * 5000,
        status: Value(disposed ? 'disposed' : 'held'), disposedDate: Value(disposed ? '2026-09-15' : null), createdAt: now, updatedAt: now,
      ));
    }
    for (var e = 0; e < 8000; e++) {
      final (y, m) = month(e % 36);
      final refunded = e % 53 == 0;
      b.insert(db.expenses, ExpensesCompanion.insert(
        id: newId(), item: '${items[e % items.length]} ${e ~/ 100}', vendor: vendors[(e * 7) % vendors.length], amount: 4500 + (e * 997) % 500000,
        date: iso(y, m, 1 + e % 28), isRefunded: Value(refunded), refundedAt: Value(refunded ? now : null), createdAt: now, updatedAt: now,
      ));
    }
    for (var k = 0; k < 1000; k++) {
      final purchased = k % 3 == 0;
      b.insert(db.books, BooksCompanion.insert(
        id: newId(), title: 'Book title number ${k + 1}', author: Value('Author ${k % 120}'), sizeKb: Value(k % 4 == 0 ? 2048 + k : null),
        onKindle: Value(k % 4 == 0), status: ['not_started', 'reading', 'finished', 'abandoned'][k % 4], acquisition: purchased ? 'purchased' : (k % 3 == 1 ? 'free' : 'other'),
        acquiredDate: Value('2025-0${1 + k % 9}-1${k % 9}'), amount: Value(purchased ? 29900 + k * 10 : null), ratingHalf: Value(k % 11 == 0 ? null : k % 11),
        createdAt: now, updatedAt: now,
      ));
    }
    final folders = [for (var f = 0; f < 10; f++) newId()];
    for (var f = 0; f < 10; f++) {
      b.insert(db.folders, FoldersCompanion.insert(id: folders[f], name: 'Folder ${f + 1}', sortOrder: Value(f), createdAt: now, updatedAt: now));
    }
    for (var n = 0; n < 500; n++) {
      final body = List.generate(12, (p) => 'Paragraph ${p + 1} of note ${n + 1}: the ${words[(n + p) % words.length]} for this week, with a few details to read.').join('\n');
      b.insert(db.notes, NotesCompanion.insert(
        id: newId(), folderId: Value(n % 4 == 0 ? null : folders[n % 10]), title: Value('${words[n % words.length]} ${n + 1}'),
        content: Value(jsonEncode([{'insert': '$body\n'}])), plainText: Value(body), isPinned: Value(n < 3), pinnedAt: Value(n < 3 ? now : null),
        editedAt: now + n, createdAt: now, updatedAt: now + n,
      ));
    }
  });
}
