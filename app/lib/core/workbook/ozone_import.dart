import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/database.dart';
import '../domain/dates.dart';
import '../domain/delta.dart';
import '../domain/ids.dart';
import '../domain/validation.dart';
import '../../tools/recipe/domain/amounts.dart';
import '../../tools/recipe/domain/ingredient_words.dart';
import '../../tools/recipe/domain/units.dart';
import '../data/photo_store.dart';
import 'cells.dart';
import 'ozone_export.dart';
import 'workbook.dart';

/// Import and restore (docs/spec/F1-03 §2–3): read and check the file, read the
/// rows with the app's own rules, match them to this phone's data, let the
/// person choose, then apply everything in one transaction. Nothing is deleted.

enum RowClass { newRow, same, changed, duplicate, error, deletedHere, otherVault }

/// One row of the file and what will happen to it.
class ImportRow {
  ImportRow({
    required this.sheet,
    required this.rowNo,
    required this.table,
    required this.entity,
    required this.label,
    this.fileId,
    this.fields = const {},
    this.created,
    this.updated,
    this.cls = RowClass.newRow,
    this.reason,
    this.tags = const [],
  });

  final String sheet;
  final int rowNo;
  final String table;
  final String entity;

  /// Name, title or item, for the review list.
  final String label;
  final String? fileId;

  /// DB column → value (String, int, bool or null), as they'd be written.
  Map<String, Object?> fields;
  final int? created;
  final int? updated;
  RowClass cls;
  String? reason;

  /// Notes only: tag names.
  List<String> tags;

  /// The phone's record this row matches (Same, Changed, duplicate).
  String? matchId;
  Map<String, Object?>? mine;
  List<String> mineTags = const [];
  int? mineUpdated;

  /// Will this row be written? Defaults follow F1-03 §2 (Changed: Keep mine).
  bool apply = false;

  /// Fields that differ (Changed): (label, yours, file's).
  List<(String, String, String)> diffs = const [];
}

/// Per-sheet counts for the preview table (W1 · Import preview).
class SheetCounts {
  int newRows = 0, changed = 0, same = 0, check = 0;
}

/// The file's vault, when it has one.
class FileVault {
  const FileVault(this.values);
  final Map<String, String> values;
}

class ImportPlan {
  ImportPlan({
    required this.fileName,
    required this.formatVersion,
    required this.sheetCount,
    required this.rows,
    required this.sheetErrors,
    this.fileVault,
    required this.importVault,
    this.filePhotos,
    this.photoDir,
    this.phonePhotos = const {},
  });
  final String fileName;
  final int formatVersion;
  final int sheetCount;
  final List<ImportRow> rows;

  /// Whole sheets that couldn't be read ("Expenses is missing the Amount column").
  final List<String> sheetErrors;
  final FileVault? fileVault;

  /// The phone has no vault and the file has one: it comes with the notes.
  final bool importVault;

  /// Photos in the backup .zip, unpacked in [photoDir]; null for a plain .xlsx (F4-01 §6).
  final Set<String>? filePhotos;
  final String? photoDir;

  /// Photo files already on the phone.
  final Set<String> phonePhotos;

  /// The preview line under Recipes: "Photos: 14 new · 2 same · 1 missing".
  ({int newPhotos, int same, int missing})? get photos {
    if (filePhotos == null) return null;
    var n = 0, s = 0;
    for (final r in rows.where((r) => r.table == 'recipes' && r.apply)) {
      final p = r.fields['photo_file'] as String?;
      if (p == null || !filePhotos!.contains(p)) continue;
      phonePhotos.contains(p) ? s++ : n++;
    }
    return (newPhotos: n, same: s, missing: rows.where((r) => r.entity == 'recipe_photo').length);
  }

  /// Photos to copy into the phone's store when the plan is applied.
  Set<String> get photosToCopy => {
        for (final r in rows.where((r) => r.table == 'recipes' && r.apply))
          if (r.fields['photo_file'] case final String p when (filePhotos?.contains(p) ?? false) && !phonePhotos.contains(p)) p,
      };

  /// The sheet order of the preview.
  static const sheets = ['Accounts', 'Balance updates', 'Gold items', 'Gold prices', 'Expenses', 'Books', 'Folders', 'Notes', 'Recipes', 'Kitchen', 'Settings'];

  Map<String, SheetCounts> get counts {
    final out = {for (final s in sheets) s: SheetCounts()};
    for (final r in rows) {
      final c = out[r.sheet]!;
      switch (r.cls) {
        case RowClass.newRow:
          c.newRows++;
        case RowClass.changed:
          c.changed++;
        case RowClass.same:
          c.same++;
        default:
          c.check++;
      }
    }
    return out;
  }

  /// Rows that will be written: the number on the "Import N rows" button.
  int get toWrite => rows.where((r) => r.apply).length;

  /// "Use file's" (or back to "Keep mine") for every Changed row of a sheet.
  void setSheetChoice(String sheet, {required bool useFile}) {
    for (final r in rows) {
      if (r.sheet == sheet && r.cls == RowClass.changed) r.apply = useFile;
    }
  }
}

/// Thrown when the whole file is refused; the message is shown as written.
class ImportRefused implements Exception {
  const ImportRefused(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Step 1–3: check the file, read the rows, match and classify.
Future<ImportPlan> planImport(
  AppDatabase db,
  Workbook book, {
  required String fileName,
  required LocalDate today,
  bool restore = false,
  Set<String>? filePhotos,
  String? photoDir,
  Set<String> phonePhotos = const {},
}) async {
  // ── 1 · Check the file ────────────────────────────────────────────────────
  final meta = <String, String>{};
  final metaSheet = book.sheet('_Meta');
  if (metaSheet != null) {
    for (final (_, r) in metaSheet.records()) {
      final k = text(r['key']);
      if (k != null) meta[k] = text(r['value']) ?? '';
    }
  }
  const shaped = ['Accounts', 'Balance updates', 'Gold items', 'Expenses', 'Books', 'Notes', 'Recipes'];
  if (metaSheet == null || meta['format'] != 'ozone-workbook') {
    if (!shaped.any((s) => book.sheet(s) != null)) {
      throw const ImportRefused('This isn’t an OZONE workbook. It has none of OZONE’s sheets (Accounts, Expenses, Books, Notes…).');
    }
  }
  final version = int.tryParse(meta['format_version'] ?? '1') ?? 1;
  if (version > Layout.formatVersion) throw const ImportRefused('This file is from a newer OZONE. Update the app to import it.');

  final rows = <ImportRow>[];
  final sheetErrors = <String>[];

  /// The sheet, or null (and a message) when a required column is missing.
  WbSheet? usable(String name, List<String> required) {
    final s = book.sheet(name);
    if (s == null) return null;
    for (final col in required) {
      if (s.column(col) == null) {
        sheetErrors.add('$name is missing the $col column, so that sheet was left out.');
        return null;
      }
    }
    return s;
  }

  ImportRow err(String sheet, int rowNo, String table, String entity, String label, String reason) =>
      ImportRow(sheet: sheet, rowNo: rowNo, table: table, entity: entity, label: label, cls: RowClass.error, reason: 'Row $rowNo: $reason');

  String? str(Map<String, Object?> r, String col, {int max = 80, String? what}) {
    final v = text(r[headerKey(col)]);
    if (v == null) return null;
    if (v.length > max) throw _RowError('${what ?? col} is longer than $max characters');
    return v;
  }

  T must<T>(Validation<T> v) => switch (v) { Ok(:final value) => value, Invalid(:final reason) => throw _RowError(reason) };

  int? stamp(Map<String, Object?> r, String col) => must(timestampCell(r[headerKey(col)], what: col));

  void read(String sheetName, String table, String entity, List<String> required, String Function(Map<String, Object?>) label,
      ImportRow Function(int rowNo, Map<String, Object?> r) parse) {
    final s = usable(sheetName, required);
    if (s == null) return;
    for (final (rowNo, r) in s.records()) {
      try {
        rows.add(parse(rowNo, r));
      } on _RowError catch (e) {
        rows.add(err(sheetName, rowNo, table, entity, label(r), e.message));
      }
    }
  }

  ImportRow row(String sheet, int rowNo, String table, String entity, String label, Map<String, Object?> r, Map<String, Object?> fields, {List<String> tags = const []}) =>
      ImportRow(
        sheet: sheet,
        rowNo: rowNo,
        table: table,
        entity: entity,
        label: label,
        fileId: text(r['id']),
        fields: fields,
        created: stamp(r, 'Created'),
        updated: stamp(r, 'Updated'),
        tags: tags,
      );

  String lbl(Map<String, Object?> r, String col) => text(r[headerKey(col)]) ?? '(no ${col.toLowerCase()})';

  // ── 2 · Read rows ─────────────────────────────────────────────────────────
  read('Accounts', 'savings_accounts', 'savings_account', ['Name'], (r) => lbl(r, 'Name'), (n, r) {
    final name = str(r, 'Name') ?? (throw _RowError('Name is empty'));
    return row('Accounts', n, 'savings_accounts', 'savings_account', name, r, {
      'name': name,
      'platform': str(r, 'Platform'),
      'type': str(r, 'Type'),
      'archived_at': must(optionalDateCell(r['archivedon'], what: 'Archived on', notAfter: today))?.toIso(),
      'remarks': str(r, 'Remarks', max: 1000),
    });
  });
  read('Balance updates', 'balance_updates', 'balance_update', ['Date', 'Balance'], (r) => lbl(r, 'Account †'), (n, r) {
    final acc = text(r['accountid']);
    final accName = text(r['account']);
    if (acc == null && accName == null) throw _RowError('Account not found');
    return row('Balance updates', n, 'balance_updates', 'balance_update', accName ?? 'Balance update', r, {
      'account_id': acc ?? '\u0000name:$accName', // resolved below
      'date': must(dateCell(r['date'], what: 'Date', notAfter: today)).toIso(),
      'balance': must(moneyCell(r['balance'], what: 'Balance', allowZero: true)),
      'is_unchanged': must(yesNoCell(r['unchanged'], what: 'Unchanged')),
      'remarks': str(r, 'Remarks', max: 1000),
    });
  });
  read('Gold items', 'gold_items', 'gold_item', ['Name', 'Grams', 'Karat', 'Purchase date', 'Cost'], (r) => lbl(r, 'Name'), (n, r) {
    final name = str(r, 'Name') ?? (throw _RowError('Name is empty'));
    final bought = must(dateCell(r['purchasedate'], what: 'Purchase date', notAfter: today));
    final status = isBlank(r['status']) ? 'held' : must(wordCell(r['status'], Layout.goldStatus, what: 'Status'));
    final disposed = must(optionalDateCell(r['disposedon'], what: 'Disposed on', notAfter: today));
    if (status == 'disposed' && disposed == null) throw _RowError('Disposed on is empty for a disposed item');
    if (disposed != null && disposed.isBefore(bought)) throw _RowError('Disposed on is before the purchase date');
    return row('Gold items', n, 'gold_items', 'gold_item', name, r, {
      'name': name,
      'weight_mg': must(gramsCell(r['grams'])),
      'karat': must(karatCell(r['karat'])),
      'vendor': str(r, 'Vendor'),
      'purchase_date': bought.toIso(),
      'cost': must(moneyCell(r['cost'], what: 'Cost')),
      'status': status,
      'disposed_date': status == 'disposed' ? disposed!.toIso() : null,
      'remarks': str(r, 'Remarks', max: 1000),
    });
  });
  read('Gold prices', 'karat_prices', 'karat_price', ['Karat', 'Price per gram', 'Date'], (r) => '${text(r['karat']) ?? '?'}K price', (n, r) {
    final k = must(karatCell(r['karat']));
    return row('Gold prices', n, 'karat_prices', 'karat_price', '${k}K price', r, {
      'karat': k,
      'price_per_gram': must(moneyCell(r['pricepergram'], what: 'Price per gram')),
      'date': must(dateCell(r['date'], what: 'Date', notAfter: today)).toIso(),
    });
  });
  read('Expenses', 'expenses', 'expense', ['Item', 'Vendor', 'Amount', 'Date'], (r) => lbl(r, 'Item'), (n, r) {
    final item = str(r, 'Item') ?? (throw _RowError('Item is empty'));
    return row('Expenses', n, 'expenses', 'expense', item, r, {
      'item': item,
      'vendor': str(r, 'Vendor') ?? (throw _RowError('Vendor is empty')),
      'amount': must(moneyCell(r['amount'], what: 'Amount')),
      'date': must(dateCell(r['date'], what: 'Date', notAfter: today)).toIso(),
      'is_refunded': must(yesNoCell(r['refunded'], what: 'Refunded')),
      'remarks': str(r, 'Remarks', max: 1000),
    });
  });
  read('Books', 'books', 'book', ['Title', 'Status', 'Acquisition'], (r) => lbl(r, 'Title'), (n, r) {
    final title = str(r, 'Title', max: 200) ?? (throw _RowError('Title is empty'));
    final acq = must(wordCell(r['acquisition'], Layout.acquisition, what: 'Acquisition'));
    final amount = isBlank(r['amount']) ? null : must(moneyCell(r['amount'], what: 'Amount'));
    if (acq == 'purchased' && amount == null) throw _RowError('Amount is empty for a purchased book');
    final size = isBlank(r['sizekb']) ? null : int.tryParse(text(r['sizekb'])!);
    if (!isBlank(r['sizekb']) && (size == null || size < 1)) throw _RowError('Size KB "${text(r['sizekb'])}" isn’t a whole number above 0');
    return row('Books', n, 'books', 'book', title, r, {
      'title': title,
      'author': str(r, 'Author', max: 200),
      'size_kb': size,
      'on_kindle': must(yesNoCell(r['onkindle'], what: 'On Kindle')),
      'status': must(wordCell(r['status'], Layout.bookStatus, what: 'Status')),
      'acquisition': acq,
      'acquired_date': must(optionalDateCell(r['acquiredon'], what: 'Acquired on', notAfter: today))?.toIso(),
      'amount': acq == 'purchased' ? amount : null,
      'rating_half': must(ratingCell(r['rating'])),
      'remarks': str(r, 'Remarks', max: 1000),
    });
  });
  read('Folders', 'folders', 'folder', ['Name'], (r) => lbl(r, 'Name'), (n, r) {
    final name = str(r, 'Name') ?? (throw _RowError('Name is empty'));
    final order = isBlank(r['order']) ? 0 : (r['order'] is num ? (r['order']! as num).toInt() : int.tryParse(text(r['order'])!) ?? 0);
    return ImportRow(sheet: 'Folders', rowNo: n, table: 'folders', entity: 'folder', label: name, fileId: text(r['id']), fields: {'name': name, 'sort_order': order});
  });

  // Notes: the readable sheet plus the content parts (F1-02 §4).
  final parts = <String, Map<int, String>>{};
  final contentSheet = book.sheet('Notes_Content');
  if (contentSheet != null) {
    for (final (_, r) in contentSheet.records()) {
      final id = text(r['noteid']);
      final p = r['part'] is num ? (r['part']! as num).toInt() : int.tryParse(text(r['part']) ?? '');
      if (id == null || p == null) continue;
      (parts[id] ??= {})[p] = r['content'] == null ? '' : r['content'].toString();
    }
  }
  read('Notes', 'notes', 'note', const [], (r) => lbl(r, 'Title'), (n, r) {
    final id = text(r['id']);
    final locked = must(yesNoCell(r['locked'], what: 'Locked'));
    final joined = id == null || parts[id] == null ? null : ([...parts[id]!.keys]..sort()).map((k) => parts[id]![k]).join();
    String? title, content, plain, cipher;
    if (locked) {
      if (joined == null || joined.isEmpty) throw _RowError('the locked note’s content is missing from Notes_Content');
      cipher = joined;
    } else {
      title = str(r, 'Title', max: 200, what: 'Title');
      final textCol = text(r['text']);
      if (joined != null) {
        List<Object?> ops;
        try {
          ops = jsonDecode(joined) as List<Object?>;
        } on Object {
          throw _RowError('the note’s content isn’t readable');
        }
        final clean = sanitizeDelta(ops);
        content = jsonEncode(clean);
        plain = plainTextFromDelta(clean); // Text † is only a helper (F1-02 §2)
      } else {
        // A note typed into the sheet by a person: its text becomes plain paragraphs.
        if (title == null && textCol == null) throw _RowError('the note has no title and no text');
        final clean = sanitizeDelta([{'insert': '${textCol ?? ''}\n'}]);
        content = jsonEncode(clean);
        plain = plainTextFromDelta(clean);
      }
    }
    final edited = stamp(r, 'Edited');
    return row('Notes', n, 'notes', 'note', locked ? 'Locked note' : (title ?? 'Untitled'), r, {
      'folder_id': text(r['folderid']),
      'title': title,
      'content': content,
      'plain_text': plain,
      'is_pinned': must(yesNoCell(r['pinned'], what: 'Pinned')),
      'is_locked': locked,
      'cipher': cipher,
      'edited_at': edited,
      'trashed_at': stamp(r, 'Trashed on'),
    }, tags: locked ? const [] : [for (final t in tagsCell(r['tags'])) t.toLowerCase()]);
  });
  // Recipes (F4-01 §4): ingredients and steps travel with their recipe as one
  // canonical payload, so a recipe is New, Same or Changed as a whole.
  String childKey(Map<String, Object?> r) => text(r['recipeid']) ?? '\u0000t:${text(r['recipe'])?.toLowerCase() ?? ''}';
  int position(Map<String, Object?> r) {
    final p = r['position'];
    final n = p is num ? p : num.tryParse(text(p) ?? '');
    if (n == null || n < 1 || n != n.roundToDouble()) throw _RowError('Position "${text(p) ?? ''}" isn’t a whole number from 1');
    return n.toInt();
  }

  int? qty(Object? v, String what) {
    if (isBlank(v)) return null;
    if (v is num) {
      if (v <= 0 || v * 1000 > Amount.max) throw _RowError('$what must be more than 0');
      return (v * 1000).round();
    }
    final p = readAmount(text(v)!);
    if (p == null || p.rest.isNotEmpty || p.unit != null || p.amount!.maxMilli != null) throw _RowError('$what "${text(v)}" isn’t a number');
    return p.amount!.milli;
  }

  final ingredientsOf = <String, List<(int, List<Object?>)>>{};
  final stepsOf = <String, List<(int, String)>>{};
  final childErrors = <String, String>{};
  void child(String sheet, List<String> required, void Function(Map<String, Object?> r) parse) {
    final s = usable(sheet, required);
    if (s == null) return;
    for (final (rowNo, r) in s.records()) {
      try {
        parse(r);
      } on _RowError catch (e) {
        childErrors.putIfAbsent(childKey(r), () => '$sheet row $rowNo: ${e.message}');
      }
    }
  }

  child('Recipe ingredients', ['Position', 'Name'], (r) {
    final name = str(r, 'Name', max: 200) ?? (throw _RowError('Name is empty'));
    final lo = qty(r['amount'], 'Amount');
    final hi = qty(r['amountmax'], 'Amount max');
    if (hi != null && (lo == null || hi <= lo)) throw _RowError('Amount max must be larger than Amount');
    final u = text(r['unit']);
    final unit = u == null ? null : (Units.of(u) ?? (throw _RowError('Unit "$u" isn’t one OZONE knows')));
    final key = (str(r, 'Key name') ?? keyNameFor(name)).toLowerCase();
    (ingredientsOf[childKey(r)] ??= []).add((position(r), [str(r, 'Section', max: 60), lo, hi, unit, name, key]));
  });
  child('Recipe steps', ['Position', 'Text'], (r) {
    final body = str(r, 'Text', max: 2000) ?? (throw _RowError('Text is empty'));
    (stepsOf[childKey(r)] ??= []).add((position(r), body));
  });

  read('Recipes', 'recipes', 'recipe', ['Title'], (r) => lbl(r, 'Title'), (n, r) {
    final title = str(r, 'Title', max: 200) ?? (throw _RowError('Title is empty'));
    final key = text(r['id']) ?? '\u0000t:${title.toLowerCase()}';
    if (childErrors[key] != null) throw _RowError(childErrors[key]!);
    final ings = [...?ingredientsOf[key]]..sort((a, b) => a.$1.compareTo(b.$1));
    if (ings.isEmpty) throw _RowError('the recipe has no rows in Recipe ingredients');
    if (ings.length > 100) throw _RowError('the recipe has more than 100 ingredients');
    final steps = [...?stepsOf[key]]..sort((a, b) => a.$1.compareTo(b.$1));
    if (steps.length > 60) throw _RowError('the recipe has more than 60 steps');
    int? whole(String col, int min, int max) {
      final v = r[headerKey(col)];
      if (isBlank(v)) return null;
      final x = v is num ? v : num.tryParse(text(v)!);
      if (x == null || x != x.roundToDouble() || x < min || x > max) throw _RowError('$col "${text(v)}" isn’t a whole number from $min to $max');
      return x.toInt();
    }

    final photo = text(r['photo']);
    return row('Recipes', n, 'recipes', 'recipe', title, r, {
      'title': title,
      'category': str(r, 'Category', max: 40),
      'servings': whole('Servings', 1, 100),
      'prep_min': whole('Prep min', 0, 6000),
      'cook_min': whole('Cook min', 0, 6000),
      'source': str(r, 'Source', max: 200),
      'notes': str(r, 'Notes', max: 2000),
      'is_favourite': must(yesNoCell(r['favourite'], what: 'Favourite')),
      'photo_file': photo != null && PhotoStore.namePattern.hasMatch(photo) ? photo : null,
      'children': recipeChildren([for (final i in ings) i.$2], [for (final s in steps) s.$2]),
    });
  });
  read('Kitchen', 'kitchen', 'kitchen', ['Key name'], (r) => lbl(r, 'Key name'), (n, r) {
    final key = (str(r, 'Key name') ?? (throw _RowError('Key name is empty'))).toLowerCase();
    return ImportRow(sheet: 'Kitchen', rowNo: n, table: 'kitchen', entity: 'kitchen', label: key, fileId: key);
  });
  read('Settings', 'settings', 'setting', ['Key', 'Value'], (r) => lbl(r, 'Key'), (n, r) {
    final key = text(r['key'])!;
    if (!Layout.settingKeys.containsKey(key)) throw _RowError('"$key" isn’t a setting OZONE keeps in workbooks');
    final value = r['value'] == null ? '' : r['value'].toString();
    try {
      jsonDecode(value);
    } on Object {
      throw _RowError('the value of $key isn’t readable');
    }
    return ImportRow(sheet: 'Settings', rowNo: n, table: 'settings', entity: 'setting', label: Layout.settingKeys[key]!, fileId: key, fields: {'value': value});
  });

  // The file's vault.
  FileVault? fileVault;
  final vs = book.sheet('Vault');
  if (vs != null) {
    final m = <String, String>{};
    for (final (_, r) in vs.records()) {
      final k = text(r['key']);
      if (k != null) m[k] = text(r['value']) ?? '';
    }
    if (m.containsKey('wrapped_key_password')) fileVault = FileVault(m);
  }

  // ── 3 · Match and classify ────────────────────────────────────────────────
  final phoneVault = await (db.select(db.vault)..where((v) => v.id.equals(1))).getSingleOrNull();
  final importVault = phoneVault == null && fileVault != null;
  final sameVault = phoneVault != null &&
      fileVault != null &&
      fileVault.values['salt'] == base64Encode(phoneVault.salt) &&
      fileVault.values['key_check'] == base64Encode(phoneVault.keyCheck);

  final deleted = {for (final d in await db.select(db.deletions).get()) '${d.entity}:${d.recordId}'};

  Future<Map<String, Map<String, Object?>>> load(String table, List<String> cols) async {
    final out = <String, Map<String, Object?>>{};
    final rs = await db.customSelect('SELECT id, updated_at, ${cols.join(', ')} FROM $table').get();
    for (final r in rs) {
      out[r.read<String>('id')] = {for (final c in ['updated_at', ...cols]) c: r.data[c]};
    }
    return out;
  }

  const boolCols = {'is_unchanged', 'is_refunded', 'on_kindle', 'is_pinned', 'is_locked', 'is_favourite'};
  Object? norm(String col, Object? v) => boolCols.contains(col) ? (v == true || v == 1) : v;

  final tagNames = {for (final t in await db.select(db.tags).get()) t.id: t.name};
  final noteTags = <String, List<String>>{};
  for (final l in await db.select(db.noteTags).get()) {
    (noteTags[l.noteId] ??= []).add(tagNames[l.tagId] ?? '');
  }

  // Accounts in the file by ID and name, for balance updates without an Account ID.
  final phoneAccounts = await load('savings_accounts', ['name']);
  final fileAccountIds = {for (final r in rows) if (r.table == 'savings_accounts' && r.fileId != null) r.fileId!};
  final accountByName = <String, List<String>>{};
  for (final MapEntry(key: id, value: a) in phoneAccounts.entries) {
    (accountByName[(a['name']! as String).toLowerCase()] ??= []).add(id);
  }
  for (final r in rows) {
    if (r.table == 'savings_accounts' && r.cls != RowClass.error && r.fileId != null && !phoneAccounts.containsKey(r.fileId)) {
      (accountByName[(r.fields['name']! as String).toLowerCase()] ??= []).add(r.fileId!);
    }
  }
  for (final r in rows.where((r) => r.table == 'balance_updates' && r.cls != RowClass.error)) {
    final a = r.fields['account_id']! as String;
    if (a.startsWith('\u0000name:')) {
      final hits = accountByName[a.substring(6).toLowerCase()] ?? const [];
      if (hits.length == 1) {
        r.fields['account_id'] = hits.single;
      } else {
        r
          ..cls = RowClass.error
          ..reason = 'Row ${r.rowNo}: Account not found';
      }
    } else if (!phoneAccounts.containsKey(a) && !fileAccountIds.contains(a)) {
      r
        ..cls = RowClass.error
        ..reason = 'Row ${r.rowNo}: Account not found';
    }
  }

  // Folders in the file that match a phone folder by name are the same folder.
  final phoneFolders = await load('folders', ['name', 'sort_order']);
  final folderIdMap = <String, String>{};

  const columns = {
    'savings_accounts': ['name', 'platform', 'type', 'archived_at', 'remarks'],
    'balance_updates': ['account_id', 'date', 'balance', 'is_unchanged', 'remarks'],
    'gold_items': ['name', 'weight_mg', 'karat', 'vendor', 'purchase_date', 'cost', 'status', 'disposed_date', 'remarks'],
    'karat_prices': ['karat', 'price_per_gram', 'date'],
    'expenses': ['item', 'vendor', 'amount', 'date', 'is_refunded', 'remarks'],
    'books': ['title', 'author', 'size_kb', 'on_kindle', 'status', 'acquisition', 'acquired_date', 'amount', 'rating_half', 'remarks'],
    'folders': ['name', 'sort_order'],
    'notes': ['folder_id', 'title', 'content', 'plain_text', 'is_pinned', 'is_locked', 'cipher', 'trashed_at'],
    'recipes': ['title', 'category', 'servings', 'prep_min', 'cook_min', 'source', 'notes', 'is_favourite', 'photo_file', 'children'],
  };

  // The phone's recipes with their children in the same canonical form.
  Future<Map<String, Map<String, Object?>>> loadRecipes() async {
    final out = await load('recipes', ['title', 'category', 'servings', 'prep_min', 'cook_min', 'source', 'notes', 'is_favourite', 'photo_file']);
    final ings = <String, List<List<Object?>>>{};
    for (final i in await (db.select(db.recipeIngredients)..orderBy([(x) => OrderingTerm.asc(x.position)])).get()) {
      (ings[i.recipeId] ??= []).add([i.section, i.amountMilli, i.amountMaxMilli, i.unit, i.name, i.keyName]);
    }
    final steps = <String, List<String>>{};
    for (final s in await (db.select(db.recipeSteps)..orderBy([(x) => OrderingTerm.asc(x.position)])).get()) {
      (steps[s.recipeId] ??= []).add(s.body);
    }
    for (final MapEntry(key: id, value: m) in out.entries) {
      m['children'] = recipeChildren(ings[id] ?? const [], steps[id] ?? const []);
    }
    return out;
  }

  final phoneRecipes = await loadRecipes();
  // Photos (F4-01 §6): a .xlsx carries none, so the phone's photo stays. In a
  // .zip, a photo that's missing or broken keeps the phone's photo and is listed.
  for (final r in [...rows.where((r) => r.table == 'recipes' && r.cls != RowClass.error)]) {
    final mine = r.fileId == null ? null : phoneRecipes[r.fileId]?['photo_file'] as String?;
    final p = r.fields['photo_file'] as String?;
    if (filePhotos == null) {
      r.fields['photo_file'] = mine;
    } else if (p != null && !filePhotos.contains(p)) {
      r.fields['photo_file'] = mine;
      rows.add(ImportRow(
        sheet: 'Recipes',
        rowNo: r.rowNo,
        table: 'recipe_photos',
        entity: 'recipe_photo',
        label: r.label,
        cls: RowClass.error,
        reason: 'Photo for ${r.label} is missing from the file',
      ));
    }
  }

  /// Natural keys (F1-03 §2). Unique keys (balance update, gold price, folder) mean the same record.
  String? naturalKey(String table, Map<String, Object?> f) => switch (table) {
        'expenses' => '${f['date']}|${f['amount']}|${(f['item'] as String).toLowerCase()}',
        'balance_updates' => '${f['account_id']}|${f['date']}',
        'karat_prices' => '${f['karat']}|${f['date']}',
        'books' => '${(f['title'] as String).toLowerCase()}|${(f['author'] as String?)?.toLowerCase() ?? ''}',
        'savings_accounts' => (f['name'] as String).toLowerCase(),
        'folders' => (f['name'] as String).toLowerCase(),
        'gold_items' => '${(f['name'] as String).toLowerCase()}|${f['purchase_date']}|${f['weight_mg']}',
        'recipes' => (f['title'] as String).toLowerCase(),
        _ => null,
      };
  const uniqueKey = {'balance_updates', 'karat_prices', 'folders'};

  String show(Object? v) => v == null ? '—' : (v is bool ? yesNo(v) : (v is String && v.length > 60 ? '${v.substring(0, 57)}…' : '$v'));
  String showChildren(Object? v) {
    final m = jsonDecode(v! as String) as Map<String, Object?>;
    final i = (m['i']! as List).length, s = (m['s']! as List).length;
    return '$i ${i == 1 ? 'ingredient' : 'ingredients'}, $s ${s == 1 ? 'step' : 'steps'}';
  }

  for (final MapEntry(key: table, value: cols) in columns.entries) {
    final phone = table == 'folders' ? phoneFolders : (table == 'recipes' ? phoneRecipes : await load(table, cols));
    final byKey = <String, String>{};
    for (final MapEntry(key: id, value: f) in phone.entries) {
      final k = naturalKey(table, f);
      if (k != null) byKey[k] = id;
    }
    for (final r in rows.where((r) => r.table == table && r.cls != RowClass.error)) {
      if (table == 'notes') {
        final fid = r.fields['folder_id'] as String?;
        if (fid != null) r.fields['folder_id'] = folderIdMap[fid] ?? fid;
      }
      final id = r.fileId;
      String? match;
      if (id != null && phone.containsKey(id)) {
        match = id;
      } else if (id != null && deleted.contains('${r.entity}:$id')) {
        r
          ..cls = RowClass.deletedHere
          ..reason = 'Deleted on this phone · skipped';
        continue;
      } else {
        final k = naturalKey(table, r.fields);
        final hit = k == null ? null : byKey[k];
        if (hit != null) {
          if (uniqueKey.contains(table)) {
            match = hit;
            if (table == 'folders' && id != null) folderIdMap[id] = hit;
          } else {
            r
              ..cls = RowClass.duplicate
              ..matchId = hit
              ..reason = 'Possible duplicate of a record on this phone · skipped';
            continue;
          }
        }
      }
      if (match == null) {
        r
          ..cls = RowClass.newRow
          ..apply = true;
        continue;
      }
      final mine = phone[match]!;
      r
        ..matchId = match
        ..mine = mine
        ..mineUpdated = mine['updated_at'] as int?
        ..mineTags = table == 'notes' ? ([...(noteTags[match] ?? const <String>[])]..sort()) : const [];
      final diffs = <(String, String, String)>[];
      for (final c in cols) {
        if (c == 'plain_text') continue; // follows content
        final a = norm(c, mine[c]), b = norm(c, r.fields[c]);
        if (a == b) continue;
        if (c == 'children') {
          final (x, y) = (showChildren(a), showChildren(b));
          diffs.add((_labels[c]!, x, x == y ? '$y (changed)' : y));
        } else {
          diffs.add((_labels[c] ?? c, show(a), show(b)));
        }
      }
      if (table == 'notes') {
        final ft = [...r.tags]..sort();
        if (ft.join(',') != r.mineTags.join(',')) diffs.add(('Tags', r.mineTags.join(', '), ft.join(', ')));
      }
      r
        ..diffs = diffs
        ..cls = diffs.isEmpty ? RowClass.same : RowClass.changed
        ..apply = false; // Keep mine (decision F1-4)
    }
  }

  // References that won't exist after the import: a note's folder becomes
  // Unfiled; a balance update without its account is an error (F1-03 §2).
  final foldersAfter = {...phoneFolders.keys, for (final r in rows) if (r.table == 'folders' && r.apply && r.matchId == null && r.fileId != null) r.fileId!};
  for (final r in rows.where((r) => r.table == 'notes' && r.cls != RowClass.error)) {
    final f = r.fields['folder_id'] as String?;
    if (f != null && !foldersAfter.contains(f)) r.fields['folder_id'] = null;
  }
  final accountsAfter = {...phoneAccounts.keys, for (final r in rows) if (r.table == 'savings_accounts' && r.apply && r.matchId == null && r.fileId != null) r.fileId!};
  for (final r in rows.where((r) => r.table == 'balance_updates' && r.apply && r.matchId == null)) {
    if (!accountsAfter.contains(r.fields['account_id'])) {
      r
        ..cls = RowClass.error
        ..apply = false
        ..reason = 'Row ${r.rowNo}: Account not found';
    }
  }

  // Locked notes and the vault (F1-03 §2).
  for (final r in rows.where((r) => r.table == 'notes' && r.fields['is_locked'] == true && r.cls != RowClass.error)) {
    if (fileVault == null) {
      r
        ..cls = RowClass.error
        ..apply = false
        ..reason = 'Row ${r.rowNo}: a locked note, but the file has no Vault sheet';
    } else if (!importVault && !sameVault && (r.cls == RowClass.newRow || r.cls == RowClass.changed)) {
      r
        ..cls = RowClass.otherVault
        ..apply = false
        ..reason = 'Locked with a different vault password';
    }
  }

  // Kitchen: a key the phone already has is Same; the rest are New (F4-01 §6).
  final phoneKitchen = {for (final k in await db.select(db.kitchen).get()) k.keyName};
  for (final r in rows.where((r) => r.table == 'kitchen' && r.cls != RowClass.error)) {
    final have = phoneKitchen.contains(r.fileId);
    r
      ..cls = have ? RowClass.same : RowClass.newRow
      ..apply = !have;
  }

  // Settings: one row per key; a difference is Changed (Keep mine), except on restore.
  final phoneSettings = {for (final s in await db.select(db.settings).get()) s.key: s.value};
  for (final r in rows.where((r) => r.table == 'settings' && r.cls != RowClass.error)) {
    final cur = phoneSettings[r.fileId];
    final file = r.fields['value']! as String;
    if (cur == file) {
      r.cls = RowClass.same;
    } else {
      r
        ..cls = RowClass.changed
        ..diffs = [(r.label, cur ?? 'default', file)];
    }
    r.apply = restore && r.cls == RowClass.changed;
  }
  if (restore) {
    for (final r in rows.where((r) => r.cls == RowClass.changed)) {
      r.apply = true;
    }
  }

  return ImportPlan(
    fileName: fileName,
    formatVersion: version,
    sheetCount: book.sheets.length,
    rows: rows,
    sheetErrors: sheetErrors,
    fileVault: fileVault,
    importVault: importVault,
    filePhotos: filePhotos,
    photoDir: photoDir,
    phonePhotos: phonePhotos,
  );
}

/// A recipe's ingredients ([section, amount, max, unit, name, key name] each)
/// and steps as one string, the same for the phone and the file.
String recipeChildren(List<List<Object?>> ingredients, List<String> steps) => jsonEncode({'i': ingredients, 's': steps});

const _labels = {
  'name': 'Name', 'platform': 'Platform', 'type': 'Type', 'archived_at': 'Archived on', 'remarks': 'Remarks', //
  'account_id': 'Account', 'date': 'Date', 'balance': 'Balance', 'is_unchanged': 'Unchanged',
  'weight_mg': 'Milligrams', 'karat': 'Karat', 'vendor': 'Vendor', 'purchase_date': 'Purchase date', 'cost': 'Cost (centavos)',
  'status': 'Status', 'disposed_date': 'Disposed on', 'price_per_gram': 'Price per gram (centavos)',
  'item': 'Item', 'amount': 'Amount (centavos)', 'is_refunded': 'Refunded',
  'title': 'Title', 'author': 'Author', 'size_kb': 'Size KB', 'on_kindle': 'On Kindle', 'acquisition': 'Acquisition',
  'acquired_date': 'Acquired on', 'rating_half': 'Rating (half stars)', 'sort_order': 'Order',
  'folder_id': 'Folder', 'content': 'Text', 'is_pinned': 'Pinned', 'is_locked': 'Locked', 'cipher': 'Locked content', 'trashed_at': 'Trashed',
  'category': 'Category', 'servings': 'Servings', 'prep_min': 'Prep min', 'cook_min': 'Cook min', 'source': 'Source', 'notes': 'Notes',
  'is_favourite': 'Favourite', 'photo_file': 'Photo', 'children': 'Ingredients and steps',
};

class _RowError implements Exception {
  _RowError(this.message);
  final String message;
}

/// Step 6: one transaction in dependency order (F1-03 §2). Any failure rolls
/// everything back. Returns rows written per sheet.
Future<Map<String, int>> applyImport(AppDatabase db, ImportPlan plan, {int Function()? clock}) async {
  final now = (clock ?? () => DateTime.now().toUtc().millisecondsSinceEpoch)();
  final written = <String, int>{};
  const order = ['folders', 'savings_accounts', 'balance_updates', 'karat_prices', 'gold_items', 'expenses', 'books', 'notes', 'recipes', 'kitchen', 'settings'];
  final tables = <String, TableInfo<Table, dynamic>>{
    'folders': db.folders, 'savings_accounts': db.savingsAccounts, 'balance_updates': db.balanceUpdates, 'karat_prices': db.karatPrices, //
    'gold_items': db.goldItems, 'expenses': db.expenses, 'books': db.books, 'notes': db.notes, 'recipes': db.recipes, 'kitchen': db.kitchen,
    'settings': db.settings,
  };
  Object? sql(Object? v) => v is bool ? (v ? 1 : 0) : v;

  await db.transaction(() async {
    if (plan.importVault) {
      final v = plan.fileVault!.values;
      int ts(String k) => DateTime.tryParse(v[k] ?? '')?.millisecondsSinceEpoch ?? now;
      await db.into(db.vault).insert(VaultCompanion.insert(
            id: const Value(1),
            kdfParams: v['kdf_params']!,
            salt: base64Decode(v['salt']!),
            saltRecovery: base64Decode(v['salt_recovery']!),
            wrappedKeyPassword: base64Decode(v['wrapped_key_password']!),
            wrappedKeyRecovery: base64Decode(v['wrapped_key_recovery']!),
            keyCheck: base64Decode(v['key_check']!),
            createdAt: ts('created_at'),
            updatedAt: now,
          ));
    }
    // File folder IDs that became new folders keep their IDs; notes already point at them.
    for (final table in order) {
      final info = tables[table]!;
      for (final r in plan.rows.where((r) => r.table == table && r.apply)) {
        if (table == 'settings') {
          await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: r.fileId!, value: r.fields['value']! as String, updatedAt: now));
          written[r.sheet] = (written[r.sheet] ?? 0) + 1;
          continue;
        }
        if (table == 'kitchen') {
          await db.into(db.kitchen).insert(KitchenCompanion.insert(keyName: r.fileId!, updatedAt: now), mode: InsertMode.insertOrIgnore);
          written[r.sheet] = (written[r.sheet] ?? 0) + 1;
          continue;
        }
        final f = Map<String, Object?>.of(r.fields);
        final children = f.remove('children') as String?;
        if (table == 'expenses') f['refunded_at'] = f['is_refunded'] == true ? now : null;
        if (table == 'notes') {
          if (f['is_pinned'] == true) f['pinned_at'] = r.updated ?? now;
          f['edited_at'] ??= r.updated ?? now;
          if (f['is_locked'] == true) {
            f
              ..['title'] = null
              ..['content'] = null
              ..['plain_text'] = null;
          }
        }
        String id;
        if (r.matchId != null && r.cls != RowClass.duplicate) {
          id = r.matchId!;
          final cols = f.keys.toList();
          await db.customUpdate(
            'UPDATE $table SET ${cols.map((c) => '$c = ?').join(', ')}, updated_at = ? WHERE id = ?',
            variables: [for (final c in cols) _v(sql(f[c])), Variable.withInt(now), Variable.withString(id)],
            updates: {info},
          );
        } else {
          id = r.fileId ?? newId();
          f['id'] = id;
          f['created_at'] = r.created ?? now;
          f['updated_at'] = now;
          final cols = f.keys.toList();
          await db.customInsert(
            'INSERT INTO $table (${cols.join(', ')}) VALUES (${List.filled(cols.length, '?').join(', ')})',
            variables: [for (final c in cols) _v(sql(f[c]))],
            updates: {info},
          );
        }
        if (table == 'recipes') await _writeRecipeChildren(db, id, children!);
        if (table == 'notes' && f['is_locked'] != true) {
          await db.customUpdate('DELETE FROM note_tags WHERE note_id = ?', variables: [Variable.withString(id)], updates: {db.noteTags});
          for (final name in r.tags) {
            final existing = await (db.select(db.tags)..where((t) => t.name.equals(name))).getSingleOrNull();
            final tagId = existing?.id ?? newId();
            if (existing == null) await db.into(db.tags).insert(TagsCompanion.insert(id: tagId, name: name, createdAt: now, updatedAt: now));
            await db.into(db.noteTags).insert(NoteTagsCompanion.insert(noteId: id, tagId: tagId), mode: InsertMode.insertOrIgnore);
          }
        }
        written[r.sheet] = (written[r.sheet] ?? 0) + 1;
      }
    }
  });
  return written;
}

/// Steps first, then ingredients, so the search triggers see the whole recipe (F4-01 §7).
Future<void> _writeRecipeChildren(AppDatabase db, String id, String children) async {
  final m = jsonDecode(children) as Map<String, Object?>;
  await db.customUpdate('DELETE FROM recipe_ingredients WHERE recipe_id = ?', variables: [Variable.withString(id)], updates: {db.recipeIngredients});
  await db.customUpdate('DELETE FROM recipe_steps WHERE recipe_id = ?', variables: [Variable.withString(id)], updates: {db.recipeSteps});
  final steps = (m['s']! as List).cast<String>();
  for (var p = 0; p < steps.length; p++) {
    await db.into(db.recipeSteps).insert(RecipeStepsCompanion.insert(recipeId: id, position: p, body: steps[p]));
  }
  final ings = (m['i']! as List).cast<List<Object?>>();
  for (var p = 0; p < ings.length; p++) {
    final i = ings[p];
    await db.into(db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
          recipeId: id,
          position: p,
          section: Value(i[0] as String?),
          amountMilli: Value(i[1] as int?),
          amountMaxMilli: Value(i[2] as int?),
          unit: Value(i[3] as String?),
          name: i[4]! as String,
          keyName: i[5]! as String,
        ));
  }
}

Variable<Object> _v(Object? v) => switch (v) {
      null => const Variable(null),
      final int i => Variable.withInt(i),
      final String s => Variable.withString(s),
      _ => Variable(v),
    };
