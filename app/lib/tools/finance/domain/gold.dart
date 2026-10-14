import '../../../core/domain/dates.dart';
import '../../../core/domain/money.dart';

// Gold valuation (docs/spec/F1-04 §4). Pure functions; nothing is stored.

/// A gold item as the rules need it.
class GoldPiece {
  const GoldPiece({required this.id, required this.name, required this.weightMg, required this.karat, required this.cost, this.held = true});
  final String id;
  final String name;
  final int weightMg;
  final int karat;
  final int cost;
  final bool held;
}

/// The current price for one karat: the saved price with the latest date.
class KaratPrice {
  const KaratPrice(this.karat, this.pricePerGram, this.date);
  final int karat;
  final int pricePerGram;
  final LocalDate date;
}

/// Current prices from a price history (any order): latest date wins per karat.
Map<int, KaratPrice> currentPrices(Iterable<KaratPrice> history) {
  final out = <int, KaratPrice>{};
  for (final p in history) {
    final cur = out[p.karat];
    if (cur == null || p.date.isAfter(cur.date)) out[p.karat] = p;
  }
  return out;
}

/// Value(item) = weight_mg × price_per_gram ÷ 1000, rounded once per item.
/// Example: 25.000 g of 18K at ₱5,510.00/g → ₱137,750.00.
int itemValue(int weightMg, int pricePerGram) => mulDivRound(weightMg, pricePerGram, 1000);

/// Totals over held items (Gold card, Home widget).
class GoldTotals {
  const GoldTotals({
    required this.items,
    required this.weightMg,
    required this.cost,
    required this.value,
    required this.valuedCost,
    required this.unpriced,
    required this.pricesAsOf,
  });

  final int items;
  final int weightMg;
  final int cost;

  /// Estimated value of the items that have a price.
  final int value;

  /// Cost of the items that have a price: gain compares like with like.
  final int valuedCost;

  /// Held items whose karat has no price, by karat: left out of value and gain.
  final Map<int, int> unpriced;

  /// The **oldest** current-price date among karats in use, or null.
  final LocalDate? pricesAsOf;

  int get gain => value - valuedCost;
  int get unpricedCount => unpriced.values.fold(0, (a, b) => a + b);
  bool get hasValue => items > unpricedCount;

  /// "Value leaves out 1 item with no 21K price", or null.
  String? get unpricedNote {
    if (unpriced.isEmpty) return null;
    final n = unpricedCount;
    final ks = (unpriced.keys.toList()..sort((a, b) => b.compareTo(a))).map((k) => '${k}K').toList();
    final names = ks.length == 1 ? ks.first : '${ks.sublist(0, ks.length - 1).join(', ')} or ${ks.last}';
    return 'Value leaves out $n ${n == 1 ? 'item' : 'items'} with no $names price';
  }
}

/// Totals for held items. Disposed items count nowhere.
GoldTotals goldTotals(Iterable<GoldPiece> pieces, Map<int, KaratPrice> prices) {
  var items = 0, weight = 0, cost = 0, value = 0, valuedCost = 0;
  final unpriced = <int, int>{};
  LocalDate? asOf;
  for (final p in pieces) {
    if (!p.held) continue;
    items++;
    weight += p.weightMg;
    cost += p.cost;
    final price = prices[p.karat];
    if (price == null) {
      unpriced[p.karat] = (unpriced[p.karat] ?? 0) + 1;
      continue;
    }
    value += itemValue(p.weightMg, price.pricePerGram);
    valuedCost += p.cost;
    if (asOf == null || price.date.isBefore(asOf)) asOf = price.date;
  }
  return GoldTotals(
    items: items,
    weightMg: weight,
    cost: cost,
    value: value,
    valuedCost: valuedCost,
    unpriced: unpriced,
    pricesAsOf: asOf,
  );
}

/// Needs attention lines for gold (F1-04 §3): stale prices and missing prices.
/// Example: "Gold prices are 41 days old", "No price for 21K".
List<String> goldAttention(Iterable<GoldPiece> pieces, Map<int, KaratPrice> prices, LocalDate today, {int staleDays = 30}) {
  final karats = {for (final p in pieces) if (p.held) p.karat};
  final out = <String>[];
  var oldest = -1;
  for (final k in karats) {
    final price = prices[k];
    if (price == null) continue;
    final age = price.date.daysUntil(today);
    if (age > staleDays && age > oldest) oldest = age;
  }
  if (oldest >= 0) out.add('Gold prices are $oldest days old');
  for (final k in karats.toList()..sort((a, b) => b.compareTo(a))) {
    if (prices[k] == null) out.add('No price for ${k}K');
  }
  return out;
}

/// Karats offered as one-tap chips on the item sheet (decision M3-5).
const List<int> commonKarats = [24, 22, 21, 18, 14, 10];

/// The common karats plus every karat already used by an item or a saved
/// price, high to low. Example: an 8K item adds 8K after 10K.
List<int> karatChoices(Iterable<int> used) =>
    ({...commonKarats, ...used.where((k) => k >= 1 && k <= 24)}.toList()..sort((a, b) => b.compareTo(a)));
