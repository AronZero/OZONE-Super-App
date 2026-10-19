import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/painting.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/domain/ids.dart';

/// The large sample set for performance checks (F3-03 §1, F2-03 §8): 10,000
/// rows and 500 notes, in a realistic mix. Generated on the test phone only;
/// never shipped in the app.
///
/// 20 accounts × 36 months = 720 balance updates · 4 karats × 36 months = 144
/// gold prices · 136 gold items · 8,000 expenses · 1,000 books = 10,000 rows.
/// Plus 1,000 recipes (8 ingredients and 6 steps each, 300 with photos) and 14
/// ingredients in the kitchen (F4-03 §2). Returns the recipe photo file names,
/// for [writeSamplePhotos].
Future<List<String>> seedLargeSample(AppDatabase db) async {
  final photos = <String>[];
  final now = DateTime.utc(2026, 10, 1).millisecondsSinceEpoch;
  String iso(int y, int m, int d) => '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  // Month i (0–35) runs from Oct 2023 to Sep 2026 (nothing after "today" in the tests).
  (int, int) month(int i) => (2023 + (9 + i) ~/ 12, (9 + i) % 12 + 1);
  int lastDay(int y, int m) => DateTime.utc(y, m + 1, 0).day;

  const vendors = ['SM Supermarket', 'Puregold', 'Mercury Drug', 'Shopee', 'Lazada', 'Jollibee', 'Meralco', 'Globe', 'Shell', 'National Book Store'];
  const items = ['Groceries', 'Medicine', 'Phone load', 'Fuel', 'Lunch', 'Electric bill', 'Internet', 'School supplies', 'Household', 'Snacks'];
  const words = ['plan', 'trip', 'budget', 'recipe', 'meeting', 'ideas', 'list', 'journal', 'project', 'notes'];
  const dishes = ['Chicken adobo', 'Pork sinigang', 'Beef caldereta', 'Garlic fried rice', 'Tortang talong', 'Pancit canton', 'Banana bread', 'Lumpia', 'Kare-kare', 'Tinola'];
  const pantry = ['chicken', 'pork', 'beef', 'rice', 'garlic', 'onion', 'tomato', 'egg', 'eggplant', 'soy sauce', 'vinegar', 'bay leaves', 'sugar',
    'flour', 'butter', 'banana', 'potato', 'carrot', 'ginger', 'fish sauce', 'noodles', 'cabbage', 'peanut butter', 'tamarind', 'chili', 'milk',
    'coconut milk', 'calamansi', 'spinach', 'shrimp', 'salt', 'pepper', 'water', 'oil', 'cheese', 'bell pepper', 'green beans', 'squash', 'tofu', 'mushroom'];
  const units = ['cup', 'tbsp', 'tsp', 'g', 'kg', 'clove', null];

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
    for (var r = 0; r < 1000; r++) {
      final id = newId();
      final photo = r % 10 < 3 ? '${newId()}.jpg' : null;
      if (photo != null) photos.add(photo);
      b.insert(db.recipes, RecipesCompanion.insert(
        id: id, title: '${dishes[r % dishes.length]} ${r + 1}', category: Value(const ['Mains', 'Soups', 'Sides', 'Desserts', 'Snacks'][r % 5]),
        servings: Value(2 + r % 5), prepMin: Value(5 + r % 30), cookMin: Value(10 + r % 90), isFavourite: Value(r % 13 == 0), photoFile: Value(photo),
        createdAt: now + r, updatedAt: now + r,
      ));
      for (var i = 0; i < 8; i++) {
        final key = pantry[(r * 7 + i * 5) % pantry.length];
        b.insert(db.recipeIngredients, RecipeIngredientsCompanion.insert(
          recipeId: id, position: i, section: Value(i >= 6 && r % 4 == 0 ? 'For the sauce' : null), amountMilli: Value(units[(r + i) % units.length] == null ? null : 500 * (1 + (r + i) % 6)),
          unit: Value(units[(r + i) % units.length]), name: key, keyName: key,
        ));
      }
      for (var p = 0; p < 6; p++) {
        b.insert(db.recipeSteps, RecipeStepsCompanion.insert(recipeId: id, position: p, body: 'Step ${p + 1} for ${dishes[r % dishes.length]}: cook it gently, stir now and then, and taste before moving on.'));
      }
    }
    // Enough that every group of What can I cook? has recipes.
    for (final k in const ['chicken', 'onion', 'vinegar', 'banana', 'noodles', 'milk', 'bell pepper', 'rice', 'eggplant', 'flour', 'ginger', 'tamarind', 'garlic', 'egg']) {
      b.insert(db.kitchen, KitchenCompanion.insert(keyName: k, updatedAt: now));
    }
  });
  return photos;
}

/// Writes one 1,600 × 1,200 sample picture (photos are 1,600 px JPEGs, R-5) under
/// each of [names] in [dir]. PNG bytes: the decoder reads them whatever the name.
Future<void> writeSamplePhotos(Directory dir, List<String> names) async {
  final recorder = ui.PictureRecorder();
  const size = Size(1600, 1200);
  final canvas = Canvas(recorder)
    ..drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(colors: [Color(0xFF565F14), Color(0xFFECEEDC), Color(0xFFC0392B)]).createShader(Offset.zero & size));
  for (var i = 0; i < 60; i++) {
    canvas.drawCircle(Offset((i * 137) % 1600, (i * 89) % 1200), 20.0 + i % 70, Paint()..color = Color(0x40000000 + i * 0x030507));
  }
  final image = await recorder.endRecording().toImage(1600, 1200);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  image.dispose();
  dir.createSync(recursive: true);
  for (final n in names) {
    File('${dir.path}/$n').writeAsBytesSync(bytes);
  }
}
