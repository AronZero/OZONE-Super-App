/// What can I cook? (F4-02 §5, R-7): pure matching over saved recipes.
library;

/// One saved recipe as the matcher sees it: its key names in recipe order.
class CookRecipe {
  const CookRecipe(this.id, this.title, this.keys);
  final String id;
  final String title;
  final List<String> keys;
}

enum CookGroup { ready, missing, more }

/// One recipe in a group: the key names it uses that are present (recipe
/// order) and the ones still missing.
class CookMatch {
  const CookMatch(this.id, this.title, this.uses, this.missing, this.tickedUsed);
  final String id;
  final String title;
  final List<String> uses;
  final List<String> missing;

  /// How many of the ticked key names it uses (sorts the group).
  final int tickedUsed;

  CookGroup get group => missing.isEmpty ? CookGroup.ready : (missing.length <= 2 ? CookGroup.missing : CookGroup.more);
}

class CookResult {
  const CookResult({required this.kitchen, required this.ready, required this.missing, required this.more});

  /// The ticked key names (the kitchen table).
  final Set<String> kitchen;
  final List<CookMatch> ready;
  final List<CookMatch> missing;
  final List<CookMatch> more;

  static const empty = CookResult(kitchen: {}, ready: [], missing: [], more: []);

  bool get kitchenEmpty => kitchen.isEmpty;
}

/// Groups recipes by how many key names are missing. Staples always count as
/// present. Only recipes using at least one ticked or staple key name take
/// part, and an empty kitchen gives no groups (owner, M13 Q2). Within a group:
/// more ticked key names used first, then title.
CookResult matchRecipes(List<CookRecipe> recipes, Set<String> kitchen, Set<String> staples) {
  if (kitchen.isEmpty) return CookResult.empty;
  final ready = <CookMatch>[], missing = <CookMatch>[], more = <CookMatch>[];
  for (final r in recipes) {
    final uses = <String>[], miss = <String>[];
    var ticked = 0;
    final seen = <String>{};
    for (final k in r.keys) {
      if (!seen.add(k)) continue;
      if (kitchen.contains(k)) {
        uses.add(k);
        ticked++;
      } else if (staples.contains(k)) {
        uses.add(k);
      } else {
        miss.add(k);
      }
    }
    if (uses.isEmpty) continue;
    final m = CookMatch(r.id, r.title, uses, miss, ticked);
    switch (m.group) {
      case CookGroup.ready:
        ready.add(m);
      case CookGroup.missing:
        missing.add(m);
      case CookGroup.more:
        more.add(m);
    }
  }
  int cmp(CookMatch a, CookMatch b) {
    final t = b.tickedUsed.compareTo(a.tickedUsed);
    return t != 0 ? t : a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  return CookResult(kitchen: kitchen, ready: ready..sort(cmp), missing: missing..sort(cmp), more: more..sort(cmp));
}

/// Every key name used in saved recipes, most used first then A–Z, staples
/// left out (the chips on What can I cook?).
List<String> kitchenChoices(List<CookRecipe> recipes, Set<String> staples) {
  final n = <String, int>{};
  for (final r in recipes) {
    for (final k in r.keys.toSet()) {
      if (!staples.contains(k)) n[k] = (n[k] ?? 0) + 1;
    }
  }
  return n.keys.toList()..sort((a, b) => n[b] != n[a] ? n[b]!.compareTo(n[a]!) : a.compareTo(b));
}

/// "a, b and c" for the staples line.
String andList(List<String> items) => switch (items.length) {
      0 => '',
      1 => items.first,
      _ => '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}',
    };
