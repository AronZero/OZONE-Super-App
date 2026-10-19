// Key names for What can I cook? (docs/spec/F4-02 §5). Written by us, so
// there's no third-party word list to license.

/// Words that describe how an ingredient is cut or sold, not what it is.
const Set<String> descriptorWords = {
  'fresh', 'chopped', 'minced', 'crushed', 'sliced', 'diced', 'large', 'small', 'medium', 'whole', 'boneless', //
  'skinless', 'ground', 'dried', 'cooked', 'raw', 'peeled', 'finely', 'roughly', 'thinly', 'grated', 'shredded',
  'halved', 'quartered', 'cubed', 'beaten', 'melted', 'softened', 'frozen', 'thawed', 'ripe', 'big', 'pounded',
  'of', 'and', 'or', 'about', 'optional', 'to', 'taste', 'for', 'serving', 'garnish',
};

/// Same thing, different words: plurals, Filipino names and cuts → one key name.
const Map<String, String> synonyms = {
  // Plurals
  'eggs': 'egg', 'tomatoes': 'tomato', 'potatoes': 'potato', 'onions': 'onion', 'carrots': 'carrot',
  'bananas': 'banana', 'saba bananas': 'banana', 'apples': 'apple', 'lemons': 'lemon', 'limes': 'lime',
  'chilies': 'chili', 'chillies': 'chili', 'chilli': 'chili', 'shallots': 'shallot', 'mushrooms': 'mushroom',
  'bay leaf': 'bay leaves', 'bay leafs': 'bay leaves', 'scallions': 'green onion', 'green onions': 'green onion',
  'cloves garlic': 'garlic', 'garlic cloves': 'garlic', 'peas': 'green peas', 'beans': 'beans',
  'noodles': 'noodles', 'shrimps': 'shrimp', 'prawns': 'shrimp', 'prawn': 'shrimp',
  'eggplants': 'eggplant', 'calamansis': 'calamansi', 'spring roll wrappers': 'spring roll wrapper',
  'lumpia wrappers': 'spring roll wrapper', 'lumpia wrapper': 'spring roll wrapper',
  // Filipino names
  'itlog': 'egg', 'talong': 'eggplant', 'bawang': 'garlic', 'sibuyas': 'onion', 'kamatis': 'tomato',
  'luya': 'ginger', 'asin': 'salt', 'paminta': 'pepper', 'asukal': 'sugar', 'suka': 'vinegar', 'toyo': 'soy sauce',
  'patis': 'fish sauce', 'manok': 'chicken', 'baboy': 'pork', 'baka': 'beef', 'hipon': 'shrimp', 'isda': 'fish',
  'kanin': 'rice', 'bigas': 'rice', 'gata': 'coconut milk', 'mantika': 'oil', 'dahon ng laurel': 'bay leaves',
  'laurel': 'bay leaves', 'sitaw': 'string beans', 'kalabasa': 'squash', 'labanos': 'radish', 'saging': 'banana',
  'langka': 'jackfruit', 'harina': 'flour', 'gatas': 'milk', 'mantikilya': 'butter', 'sili': 'chili',
  'sampalok': 'tamarind', 'kangkong': 'kangkong', 'malunggay': 'malunggay',
  // Other words for the same thing
  'spring onion': 'green onion', 'scallion': 'green onion', 'spring onions': 'green onion',
  'peppercorns': 'pepper', 'peppercorn': 'pepper', 'black pepper': 'pepper', 'black peppercorns': 'pepper',
  'cooking oil': 'oil', 'vegetable oil': 'oil', 'canola oil': 'oil', 'olive oil': 'olive oil',
  'brown sugar': 'sugar', 'white sugar': 'sugar', 'granulated sugar': 'sugar', 'muscovado sugar': 'sugar',
  'cane vinegar': 'vinegar', 'white vinegar': 'vinegar', 'coconut vinegar': 'vinegar', 'sukang maasim': 'vinegar',
  'all-purpose flour': 'flour', 'all purpose flour': 'flour', 'plain flour': 'flour',
  'table salt': 'salt', 'sea salt': 'salt', 'rock salt': 'salt', 'iodized salt': 'salt',
  'cold water': 'water', 'warm water': 'water', 'hot water': 'water',
  'unsalted butter': 'butter', 'salted butter': 'butter',
  'fish sauce': 'fish sauce', 'light soy sauce': 'soy sauce', 'dark soy sauce': 'soy sauce',
  'cooked rice': 'rice', 'day-old rice': 'rice', 'leftover rice': 'rice', 'steamed rice': 'rice',
  'tamarind powder': 'tamarind mix', 'sinigang mix': 'tamarind mix', 'tamarind soup base': 'tamarind mix',
  // Cuts → the meat
  'chicken thigh': 'chicken', 'chicken thighs': 'chicken', 'chicken breast': 'chicken', 'chicken breasts': 'chicken',
  'chicken wings': 'chicken', 'chicken legs': 'chicken', 'chicken drumsticks': 'chicken', 'chicken leg quarters': 'chicken',
  'pork belly': 'pork', 'pork shoulder': 'pork', 'pork chops': 'pork', 'pork ribs': 'pork', 'pork liempo': 'pork',
  'liempo': 'pork', 'pork kasim': 'pork', 'beef brisket': 'beef', 'beef sirloin': 'beef', 'beef chuck': 'beef',
};

/// Key name for an ingredient's [name] (F4-02 §5): lower case, text after the
/// first `,` or `(` dropped, descriptor words dropped, then the synonym table.
/// "Garlic, crushed" → `garlic`; "8 large Eggs" isn't passed here (the amount
/// is already split off) but "large eggs" → `egg`.
String keyNameFor(String name) {
  var s = name.toLowerCase().trim();
  final cut = s.indexOf(RegExp('[,(]'));
  if (cut >= 0) s = s.substring(0, cut);
  final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && !descriptorWords.contains(w)).toList();
  var key = words.join(' ').trim();
  if (key.isEmpty) key = name.toLowerCase().trim();
  key = synonyms[key] ?? key;
  if (key.length > 80) key = key.substring(0, 80).trim();
  return key;
}
