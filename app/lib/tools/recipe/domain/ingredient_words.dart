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

/// About 400 common ingredient words in English and Filipino (F4-02 §4 rule 9).
/// A scanned ingredient whose key name isn't made of these (or the synonyms
/// above, or a key name already on the phone) is flagged for a check.
const Set<String> ingredientWords = {
  // Meat, fish and eggs
  'chicken', 'pork', 'beef', 'lamb', 'mutton', 'goat', 'duck', 'turkey', 'veal', 'bacon', 'ham', 'sausage',
  'sausages', 'chorizo', 'longganisa', 'tocino', 'hotdog', 'hotdogs', 'liver', 'oxtail', 'tripe', 'tuwalya',
  'ribs', 'belly', 'shoulder', 'thigh', 'thighs', 'breast', 'breasts', 'wings', 'drumsticks', 'legs', 'mince',
  'meat', 'meatballs', 'corned', 'spam', 'luncheon', 'egg', 'yolk', 'yolks', 'whites', 'fish', 'tilapia',
  'bangus', 'milkfish', 'galunggong', 'tuna', 'salmon', 'cod', 'mackerel', 'sardines', 'sardinas', 'anchovies',
  'dilis', 'tuyo', 'daing', 'shrimp', 'crab', 'crabs', 'alimango', 'alimasag', 'squid', 'pusit', 'mussels',
  'tahong', 'clams', 'halaan', 'oysters', 'talaba', 'scallops', 'lobster', 'bagoong', 'alamang', 'tinapa',
  // Vegetables and herbs
  'onion', 'garlic', 'ginger', 'tomato', 'potato', 'carrot', 'cabbage', 'repolyo', 'pechay', 'bok', 'choy',
  'lettuce', 'spinach', 'kangkong', 'malunggay', 'moringa', 'ampalaya', 'bitter', 'gourd', 'okra', 'eggplant',
  'squash', 'kalabasa', 'pumpkin', 'sayote', 'chayote', 'upo', 'patola', 'radish', 'labanos', 'string',
  'beans', 'sitaw', 'baguio', 'green', 'peas', 'corn', 'mais', 'celery', 'leek', 'leeks', 'shallot', 'scallion',
  'bell', 'pepper', 'peppers', 'capsicum', 'chili', 'siling', 'labuyo', 'jalapeno', 'cucumber', 'pipino',
  'zucchini', 'broccoli', 'cauliflower', 'asparagus', 'mushroom', 'shiitake', 'button', 'sprouts', 'togue',
  'monggo', 'mung', 'gabi', 'taro', 'kamote', 'sweet', 'cassava', 'kamoteng', 'kahoy', 'ube', 'yam', 'jicama',
  'singkamas', 'banana', 'heart', 'puso', 'saging', 'langka', 'jackfruit', 'bamboo', 'shoots', 'labong',
  'lemongrass', 'tanglad', 'tamarind', 'kamias', 'bilimbi', 'calamansi', 'lemon', 'lime', 'dayap', 'avocado',
  'olives', 'beet', 'beets', 'kale', 'arugula', 'basil', 'parsley', 'cilantro', 'coriander', 'kinchay', 'dill',
  'mint', 'rosemary', 'thyme', 'oregano', 'sage', 'chives', 'bay', 'leaves', 'leaf', 'laurel', 'pandan',
  'tarragon', 'herbs',
  // Fruit
  'apple', 'orange', 'mango', 'mangga', 'pineapple', 'pinya', 'papaya', 'coconut', 'niyog', 'buko', 'grapes',
  'strawberries', 'strawberry', 'blueberries', 'raisins', 'pasas', 'dates', 'melon', 'watermelon', 'pear',
  'peach', 'peaches', 'cherries', 'kiwi', 'guava', 'bayabas', 'saba', 'plantain', 'fruit', 'cocktail', 'nata',
  'kaong', 'macapuno', 'zest', 'juice',
  // Grains, flour and noodles
  'rice', 'malagkit', 'glutinous', 'flour', 'cornstarch', 'starch', 'cornflour', 'bread', 'breadcrumbs',
  'panko', 'crumbs', 'oats', 'oatmeal', 'pasta', 'spaghetti', 'macaroni', 'noodles', 'bihon', 'canton',
  'sotanghon', 'misua', 'miki', 'vermicelli', 'udon', 'ramen', 'tortilla', 'tortillas', 'wrapper', 'wrappers',
  'lumpia', 'pandesal', 'buns', 'crackers', 'biscuits', 'graham', 'yeast', 'baking', 'powder', 'soda',
  'semolina', 'quinoa', 'barley', 'couscous', 'sago', 'tapioca', 'pearls', 'gulaman', 'gelatin', 'agar',
  // Dairy
  'milk', 'evaporated', 'condensed', 'cream', 'butter', 'margarine', 'cheese', 'cheddar', 'mozzarella',
  'parmesan', 'kesong', 'puti', 'quezo', 'yogurt', 'yoghurt', 'buttermilk', 'whipping', 'heavy', 'sour', 'ghee',
  // Pantry, sauces and seasoning
  'salt', 'sugar', 'brown', 'white', 'muscovado', 'honey', 'syrup', 'molasses', 'vinegar', 'soy', 'sauce',
  'patis', 'oyster', 'ketchup', 'catsup', 'mayonnaise', 'mustard', 'hoisin', 'sriracha', 'worcestershire',
  'liquid', 'seasoning', 'oil', 'olive', 'sesame', 'vegetable', 'canola', 'lard', 'shortening', 'stock',
  'broth', 'cube', 'cubes', 'bouillon', 'granules', 'paste', 'puree', 'atsuete', 'annatto', 'achuete',
  'paprika', 'cumin', 'turmeric', 'luyang', 'dilaw', 'cinnamon', 'nutmeg', 'cloves', 'star', 'anise',
  'cardamom', 'curry', 'flakes', 'cayenne', 'msg', 'vetsin', 'vanilla', 'extract', 'cocoa', 'chocolate',
  'chips', 'coffee', 'tea', 'peanut', 'peanuts', 'mani', 'cashew', 'cashews', 'almonds', 'walnuts', 'pecans',
  'nuts', 'seeds', 'linga', 'tofu', 'tokwa', 'miso', 'tausi', 'black', 'garbanzos', 'chickpeas', 'lentils',
  'kidney', 'red', 'mix', 'sinigang', 'gravy', 'water', 'ice', 'wine', 'rum', 'beer', 'cooking', 'spray',
  'food', 'coloring', 'colouring', 'sprinkles', 'jam', 'jelly', 'preserves', 'pickles', 'atchara', 'relish',
  'capers', 'gata', 'kakang', 'chicharon', 'chicharron', 'pinipig', 'halaya', 'leche', 'flan', 'dulce',
  // Describing words that stay in key names
  'smoked', 'salted', 'unsalted', 'spring', 'light', 'dark', 'roasted', 'toasted', 'instant', 'powdered',
  'canned', 'all-purpose', 'self-raising', 'self-rising', 'plain', 'native', 'young', 'mature',
};

/// Whether [key] is made only of words OZONE knows, or is a key name the
/// phone already uses ([known]).
bool isKnownKey(String key, {Set<String> known = const {}}) {
  if (key.isEmpty) return false;
  if (known.contains(key) || synonyms.containsKey(key) || synonyms.containsValue(key)) return true;
  return key
      .split(RegExp(r'[\s-]+'))
      .where((w) => w.isNotEmpty)
      .every((w) => ingredientWords.contains(w) || descriptorWords.contains(w));
}
