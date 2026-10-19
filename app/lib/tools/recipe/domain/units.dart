/// Ingredient units (docs/spec/F4-02 §4). Stored in their short form;
/// everything else a person or a cookbook writes is read as one of these.
abstract final class Units {
  /// Short form → words that mean it (lower case; `t` and `T` are handled apart).
  static const Map<String, List<String>> _aliases = {
    'tsp': ['tsp', 'tsps', 'teaspoon', 'teaspoons', 'kutsarita'],
    'tbsp': ['tbsp', 'tbsps', 'tbs', 'tbl', 'tablespoon', 'tablespoons', 'kutsara'],
    'cup': ['cup', 'cups', 'c', 'tasa'],
    'g': ['g', 'gr', 'gram', 'grams'],
    'kg': ['kg', 'kgs', 'kilo', 'kilos', 'kilogram', 'kilograms'],
    'ml': ['ml', 'millilitre', 'millilitres', 'milliliter', 'milliliters'],
    'l': ['l', 'litre', 'litres', 'liter', 'liters'],
    'oz': ['oz', 'ounce', 'ounces'],
    'lb': ['lb', 'lbs', 'pound', 'pounds'],
    'clove': ['clove', 'cloves', 'butil'],
    'pc': ['pc', 'pcs', 'piece', 'pieces', 'piraso'],
    'head': ['head', 'heads', 'ulo'],
    'can': ['can', 'cans'],
    'pack': ['pack', 'packs'],
    'bunch': ['bunch', 'bunches'],
    'slice': ['slice', 'slices'],
    'stalk': ['stalk', 'stalks'],
    'pinch': ['pinch', 'pinches'],
    'thumb': ['thumb', 'thumbs'],
  };

  static final Map<String, String> _lookup = {
    for (final MapEntry(key: unit, value: words) in _aliases.entries)
      for (final w in words) w: unit,
  };

  /// Every short form, in a sensible order for a picker.
  static List<String> get all => _aliases.keys.toList();

  /// The short form for [word] (`Tablespoons.` → `tbsp`), or null if it isn't a unit.
  /// A lone `T` is a tablespoon and a lone `t` a teaspoon, as cookbooks write them.
  static String? of(String word) {
    var w = word.trim();
    if (w.endsWith('.')) w = w.substring(0, w.length - 1);
    if (w == 'T') return 'tbsp';
    if (w == 't') return 'tsp';
    return _lookup[w.toLowerCase()];
  }

  /// Units written as a word get a plural: 2 cups, 8 cloves. Abbreviations don't.
  static const _plural = {
    'cup': 'cups', 'clove': 'cloves', 'head': 'heads', 'can': 'cans', 'pack': 'packs', 'bunch': 'bunches', //
    'slice': 'slices', 'stalk': 'stalks', 'pinch': 'pinches', 'thumb': 'thumbs',
  };

  /// [unit] as shown after an amount of [milli] thousandths.
  static String label(String unit, {required int milli}) => milli > 1000 ? (_plural[unit] ?? unit) : unit;

  /// Units shown as whole numbers when scaled (F4-02 §6).
  static bool wholeOnly(String? unit) => unit == 'g' || unit == 'ml';
}
