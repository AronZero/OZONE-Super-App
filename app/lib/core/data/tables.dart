import 'package:drift/drift.dart';

// Every table from docs/spec/F1-01-data-model.md, schema version 1.
// Money: INTEGER centavos. Weight: INTEGER mg. Business dates: TEXT YYYY-MM-DD.
// Timestamps: INTEGER Unix ms (UTC). Booleans: INTEGER 0/1.

/// Columns every user record has.
mixin Record on Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── App ──────────────────────────────────────────────────────────────────

@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()(); // JSON
  IntColumn get updatedAt => integer()();
  @override
  Set<Column> get primaryKey => {key};
}

/// Tombstones: written when a record is permanently deleted, so an import
/// can't bring it back silently (F1-03).
@DataClassName('DeletionRow')
class Deletions extends Table {
  TextColumn get entity => text()();
  TextColumn get recordId => text()();
  IntColumn get deletedAt => integer()();
  @override
  Set<Column> get primaryKey => {entity, recordId};
}

@DataClassName('ExportLogRow')
class ExportsLog extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()(); // manual | safety
  TextColumn get fileName => text()();
  IntColumn get createdAt => integer()();
  TextColumn get rowCounts => text()(); // JSON
  @override
  Set<Column> get primaryKey => {id};
}

// ── Finance · Savings ────────────────────────────────────────────────────

@DataClassName('SavingsAccountRow')
class SavingsAccounts extends Table with Record {
  TextColumn get name => text()();
  TextColumn get platform => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get remarks => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get archivedAt => text().nullable()(); // business date
}

@DataClassName('BalanceUpdateRow')
@TableIndex(name: 'idx_balance_updates_account_date', columns: {#accountId, #date})
class BalanceUpdates extends Table with Record {
  TextColumn get accountId => text().references(SavingsAccounts, #id)();
  TextColumn get date => text()();
  IntColumn get balance => integer()(); // centavos, 0 allowed
  BoolColumn get isUnchanged => boolean().withDefault(const Constant(false))();
  TextColumn get remarks => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {accountId, date},
      ];
}

// ── Finance · Gold ───────────────────────────────────────────────────────

@DataClassName('GoldItemRow')
@TableIndex(name: 'idx_gold_items_status', columns: {#status})
class GoldItems extends Table with Record {
  TextColumn get name => text()();
  IntColumn get weightMg => integer()();
  IntColumn get karat => integer()();
  TextColumn get vendor => text().nullable()();
  TextColumn get purchaseDate => text()();
  IntColumn get cost => integer()();
  TextColumn get status => text().withDefault(const Constant('held'))(); // held | disposed
  TextColumn get disposedDate => text().nullable()();
  TextColumn get remarks => text().nullable()();
}

@DataClassName('KaratPriceRow')
@TableIndex(name: 'idx_karat_prices_karat_date', columns: {#karat, #date})
class KaratPrices extends Table with Record {
  IntColumn get karat => integer()();
  IntColumn get pricePerGram => integer()(); // centavos per gram
  TextColumn get date => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {karat, date},
      ];
}

// ── Finance · Expenses ───────────────────────────────────────────────────

@DataClassName('ExpenseRow')
@TableIndex(name: 'idx_expenses_date', columns: {#date})
@TableIndex(name: 'idx_expenses_vendor', columns: {#vendor})
class Expenses extends Table with Record {
  TextColumn get item => text()();
  TextColumn get vendor => text()();
  IntColumn get amount => integer()();
  TextColumn get date => text()();
  BoolColumn get isRefunded => boolean().withDefault(const Constant(false))();
  IntColumn get refundedAt => integer().nullable()();
  TextColumn get remarks => text().nullable()();
}

// ── Library ──────────────────────────────────────────────────────────────

@DataClassName('BookRow')
@TableIndex(name: 'idx_books_status', columns: {#status})
@TableIndex(name: 'idx_books_acquired_date', columns: {#acquiredDate})
class Books extends Table with Record {
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  IntColumn get sizeKb => integer().nullable()();
  BoolColumn get onKindle => boolean().withDefault(const Constant(false))();
  TextColumn get status => text()(); // not_started | reading | finished | abandoned
  TextColumn get acquisition => text()(); // purchased | free | other
  TextColumn get acquiredDate => text().nullable()();
  IntColumn get amount => integer().nullable()(); // required only when purchased
  IntColumn get ratingHalf => integer().nullable()(); // 0–10; null = Not rated
  TextColumn get remarks => text().nullable()();
}

// ── Notes ────────────────────────────────────────────────────────────────

@DataClassName('FolderRow')
class Folders extends Table with Record {
  TextColumn get name => text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('TagRow')
class Tags extends Table with Record {
  TextColumn get name => text().unique()(); // lower case, without '#'
}

@DataClassName('NoteRow')
@TableIndex(name: 'idx_notes_list', columns: {#trashedAt, #isPinned, #editedAt})
@TableIndex(name: 'idx_notes_folder', columns: {#folderId})
class Notes extends Table with Record {
  TextColumn get folderId => text().nullable().references(Folders, #id)(); // null = Unfiled
  TextColumn get title => text().nullable()(); // null when locked
  TextColumn get content => text().nullable()(); // Quill Delta JSON; null when locked
  TextColumn get plainText => text().nullable()(); // null when locked
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get pinnedAt => integer().nullable()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  TextColumn get cipher => text().nullable()(); // base64, F2-01 §3
  IntColumn get editedAt => integer()();
  IntColumn get trashedAt => integer().nullable()();
}

@DataClassName('NoteTagRow')
class NoteTags extends Table {
  TextColumn get noteId => text().references(Notes, #id)();
  TextColumn get tagId => text().references(Tags, #id)();
  @override
  Set<Column> get primaryKey => {noteId, tagId};
}

@DataClassName('NoteDraftRow')
class NoteDrafts extends Table {
  TextColumn get noteId => text()();
  TextColumn get content => text()();
  IntColumn get savedAt => integer()();
  @override
  Set<Column> get primaryKey => {noteId};
}

/// Single row (id = 1), created at vault setup. Meanings in F2-01 §2.
@DataClassName('VaultRow')
class Vault extends Table {
  IntColumn get id => integer()();
  TextColumn get kdfParams => text()(); // JSON
  BlobColumn get salt => blob()();
  BlobColumn get saltRecovery => blob()();
  BlobColumn get wrappedKeyPassword => blob()();
  BlobColumn get wrappedKeyRecovery => blob()();
  BlobColumn get keyCheck => blob()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  @override
  Set<Column> get primaryKey => {id};
}
