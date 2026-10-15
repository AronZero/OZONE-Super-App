import 'dart:convert';

import '../data/database.dart';
import '../domain/dates.dart';
import 'cells.dart';
import 'workbook.dart';

/// The OZONE workbook layout (docs/spec/F1-02 §2): sheet names, columns and the
/// words used for statuses. Import (ozone_import.dart) reads the same layout.
abstract final class Layout {
  static const formatVersion = 1;

  static const accounts = ['ID', 'Name', 'Platform', 'Type', 'Archived on', 'Remarks', 'Created', 'Updated'];
  static const balanceUpdates = ['ID', 'Account ID', 'Account †', 'Date', 'Balance', 'Unchanged', 'Remarks', 'Created', 'Updated'];
  static const goldItems = ['ID', 'Name', 'Grams', 'Karat', 'Vendor', 'Purchase date', 'Cost', 'Status', 'Disposed on', 'Remarks', 'Created', 'Updated'];
  static const goldPrices = ['ID', 'Karat', 'Price per gram', 'Date', 'Created', 'Updated'];
  static const expenses = ['ID', 'Item', 'Vendor', 'Amount', 'Date', 'Refunded', 'Remarks', 'Created', 'Updated'];
  static const books = ['ID', 'Title', 'Author', 'Size KB', 'On Kindle', 'Status', 'Acquisition', 'Acquired on', 'Amount', 'Rating', 'Remarks', 'Created', 'Updated'];
  static const folders = ['ID', 'Name', 'Order'];
  static const notes = ['ID', 'Title', 'Folder ID', 'Folder †', 'Tags', 'Pinned', 'Locked', 'Text †', 'Edited', 'Trashed on', 'Created', 'Updated'];
  static const notesContent = ['Note ID', 'Part', 'Parts', 'Content'];
  static const vault = ['Key', 'Value'];
  static const settings = ['Key', 'Value', 'About †'];
  static const deleted = ['Type', 'ID', 'Deleted on'];

  static const goldStatus = {'held': 'Held', 'disposed': 'Disposed'};
  static const bookStatus = {'not_started': 'Not started', 'reading': 'Reading', 'finished': 'Finished', 'abandoned': 'Abandoned'};
  static const acquisition = {'purchased': 'Purchased', 'free': 'Free', 'other': 'Other'};

  /// Settings that travel in the workbook (F1-01 §4 "In workbook"), with a line for people.
  static const settingKeys = {
    'theme': 'Light, dark or follow the phone',
    'theme.monochrome': 'Monochrome: greys only (true or false)',
    'amounts.hide_on_open': 'Hide amounts when OZONE opens',
    'dashboard.widgets': 'Home widgets, in order, shown or hidden',
    'bar.tools': 'Tools in the bottom bar',
    'backup.reminder_days': 'Remind me when the last export is older than this many days',
    'savings.month_end_reminder': 'Month-end balance reminder: on/off and time',
    'gold.stale_days': 'Flag gold prices older than this many days',
    'lists.hidden': 'Vendors, platforms and types hidden from suggestions',
    'notes.view': 'Notes home layout',
  };

  static const readMe = [
    'This is an OZONE workbook: a backup of everything in the OZONE app on one phone.',
    'This file is NOT encrypted. Anyone who opens it can read everything in it, except locked notes, which stay encrypted.',
    'Don’t change the ID columns. OZONE uses them to match rows when you import this file again.',
    'To add a record, add a row and leave its ID empty.',
    'Dates are written as YYYY-MM-DD (for example 2026-10-13). Amounts are pesos with 2 decimals (1,234.56). Grams have up to 3 decimals.',
    'Yes/No columns accept Yes or No. Columns marked † are only there to help you read the file; OZONE ignores them on import.',
    'Importing never deletes anything in OZONE. You see a preview first, and a safety copy is saved before anything changes.',
  ];
}

/// The steps shown on W3 · Export (and their progress).
enum ExportStep { savings, gold, expenses, library, notes, settings }

/// Everything in the database as a workbook (F1-03 §1): one read transaction,
/// so the file is a consistent snapshot.
Future<Workbook> buildWorkbook(
  AppDatabase db, {
  required String appVersion,
  void Function(ExportStep step)? onStep,
  bool Function()? cancelled,
}) {
  return db.transaction(() async {
    void step(ExportStep s) {
      if (cancelled?.call() ?? false) throw const ExportCancelled();
      onStep?.call(s);
    }

    Object? date(String? iso) => iso == null ? null : (LocalDate.parseIso(iso).valueOrNull ?? iso);
    String ts(int ms) => timestampText(ms);

    step(ExportStep.savings);
    final accounts = await db.select(db.savingsAccounts).get();
    final names = {for (final a in accounts) a.id: a.name};
    final ups = await db.select(db.balanceUpdates).get();
    final accountsSheet = WbSheet('Accounts', Layout.accounts, [
      for (final a in accounts) [a.id, a.name, a.platform, a.type, date(a.archivedAt), a.remarks, ts(a.createdAt), ts(a.updatedAt)],
    ]);
    final updatesSheet = WbSheet('Balance updates', Layout.balanceUpdates, [
      for (final u in ups)
        [u.id, u.accountId, names[u.accountId], date(u.date), MoneyValue(u.balance), yesNo(u.isUnchanged), u.remarks, ts(u.createdAt), ts(u.updatedAt)],
    ]);

    step(ExportStep.gold);
    final items = await db.select(db.goldItems).get();
    final prices = await db.select(db.karatPrices).get();
    final goldSheet = WbSheet('Gold items', Layout.goldItems, [
      for (final g in items)
        [
          g.id, g.name, GramsValue(g.weightMg), NumberValue(g.karat), g.vendor, date(g.purchaseDate), MoneyValue(g.cost), //
          Layout.goldStatus[g.status] ?? g.status, date(g.disposedDate), g.remarks, ts(g.createdAt), ts(g.updatedAt),
        ],
    ]);
    final pricesSheet = WbSheet('Gold prices', Layout.goldPrices, [
      for (final p in prices) [p.id, NumberValue(p.karat), MoneyValue(p.pricePerGram), date(p.date), ts(p.createdAt), ts(p.updatedAt)],
    ]);

    step(ExportStep.expenses);
    final expenses = await db.select(db.expenses).get();
    final expensesSheet = WbSheet('Expenses', Layout.expenses, [
      for (final e in expenses)
        [e.id, e.item, e.vendor, MoneyValue(e.amount), date(e.date), yesNo(e.isRefunded), e.remarks, ts(e.createdAt), ts(e.updatedAt)],
    ]);

    step(ExportStep.library);
    final books = await db.select(db.books).get();
    final booksSheet = WbSheet('Books', Layout.books, [
      for (final b in books)
        [
          b.id, b.title, b.author, b.sizeKb == null ? null : NumberValue(b.sizeKb!), yesNo(b.onKindle), Layout.bookStatus[b.status] ?? b.status, //
          Layout.acquisition[b.acquisition] ?? b.acquisition, date(b.acquiredDate), b.amount == null ? null : MoneyValue(b.amount!),
          b.ratingHalf == null ? null : NumberValue(b.ratingHalf! / 2), b.remarks, ts(b.createdAt), ts(b.updatedAt),
        ],
    ]);

    step(ExportStep.notes);
    final folders = await (db.select(db.folders)).get();
    final folderNames = {for (final f in folders) f.id: f.name};
    final tags = {for (final t in await db.select(db.tags).get()) t.id: t.name};
    final links = await db.select(db.noteTags).get();
    final tagsOf = <String, List<String>>{};
    for (final l in links) {
      (tagsOf[l.noteId] ??= []).add(tags[l.tagId] ?? '');
    }
    final notes = await db.select(db.notes).get();
    final foldersSheet = WbSheet('Folders', Layout.folders, [for (final f in folders) [f.id, f.name, NumberValue(f.sortOrder)]]);
    final notesSheet = WbSheet('Notes', Layout.notes, [
      for (final n in notes)
        [
          n.id, n.isLocked ? 'Locked note' : (n.title ?? ''), n.folderId, folderNames[n.folderId], n.isLocked ? null : (tagsOf[n.id] ?? []).join(', '), //
          yesNo(n.isPinned), yesNo(n.isLocked), n.isLocked ? 'Locked note' : n.plainText, ts(n.editedAt),
          n.trashedAt == null ? null : ts(n.trashedAt!), ts(n.createdAt), ts(n.updatedAt),
        ],
    ]);
    final contentSheet = WbSheet('Notes_Content', Layout.notesContent);
    for (final n in notes) {
      final body = n.isLocked ? (n.cipher ?? '') : (n.content ?? '[{"insert":"\\n"}]');
      final parts = splitParts(body);
      for (var i = 0; i < parts.length; i++) {
        contentSheet.rows.add([n.id, NumberValue(i + 1), NumberValue(parts.length), parts[i]]);
      }
    }
    final v = await (db.select(db.vault)..where((x) => x.id.equals(1))).getSingleOrNull();
    final vaultSheet = v == null
        ? null
        : WbSheet('Vault', Layout.vault, [
            ['About', 'These values open nothing without the vault password or recovery code.'],
            ['kdf_params', v.kdfParams],
            ['salt', base64Encode(v.salt)],
            ['salt_recovery', base64Encode(v.saltRecovery)],
            ['wrapped_key_password', base64Encode(v.wrappedKeyPassword)],
            ['wrapped_key_recovery', base64Encode(v.wrappedKeyRecovery)],
            ['key_check', base64Encode(v.keyCheck)],
            ['created_at', ts(v.createdAt)],
            ['updated_at', ts(v.updatedAt)],
          ]);

    step(ExportStep.settings);
    final settings = await db.select(db.settings).get();
    final settingsSheet = WbSheet('Settings', Layout.settings, [
      for (final s in settings)
        if (Layout.settingKeys.containsKey(s.key)) [s.key, s.value, Layout.settingKeys[s.key]],
    ]);
    final deletedSheet = WbSheet('Deleted', Layout.deleted, [
      for (final x in await db.select(db.deletions).get()) [x.entity, x.recordId, ts(x.deletedAt)],
    ]);
    final meta = {for (final m in await db.select(db.appMeta).get()) m.key: m.value};

    final dataSheets = [
      accountsSheet, updatesSheet, goldSheet, pricesSheet, expensesSheet, booksSheet, foldersSheet, notesSheet, contentSheet, //
      ?vaultSheet, settingsSheet, deletedSheet,
    ];
    return Workbook([
      WbSheet('Read me', ['Read me'], [for (final l in Layout.readMe) [l]]),
      WbSheet('_Meta', ['Key', 'Value'], [
        ['format', 'ozone-workbook'],
        ['format_version', '${Layout.formatVersion}'],
        ['app_version', appVersion],
        ['schema_version', meta['schema_version'] ?? ''],
        ['exported_at', DateTime.now().toUtc().toIso8601String()],
        ['install_id', meta['install_id'] ?? ''],
        for (final s in dataSheets) ['rows.${s.name}', '${s.rows.length}'],
      ]),
      ...dataSheets,
    ]);
  });
}

class ExportCancelled implements Exception {
  const ExportCancelled();
}

/// Row counts of the user-facing sheets, for `exports_log.row_counts` and messages.
Map<String, int> rowCounts(Workbook book) => {
      for (final s in book.sheets)
        if (!const {'Read me', '_Meta', 'Notes_Content', 'Vault', 'Deleted'}.contains(s.name)) s.name: s.rows.length,
    };
