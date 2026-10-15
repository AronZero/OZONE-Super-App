# F1-01 · Data model

All data lives in one SQLite database in the app's private storage, `ozone.db`. Nothing is sent off the phone.
Android and iOS automatic backup is turned off for this file (see F2).

## 1. Value rules (apply to every table)

| Kind | Stored as | Rules |
|---|---|---|
| ID | `TEXT`, random UUID v4, lower case | Created on the phone, never reused, never changed. It is the link between the database and the workbook. Generate with `Random.secure()`, so no package is needed. |
| Money | `INTEGER` centavos | `₱1,234.56` = `123456`. Never floating point. Range 1 to 99,999,999,999 (₱999,999,999.99) unless a field says 0 is allowed. |
| Weight | `INTEGER` milligrams | `82.400 g` = `82400`. Must be greater than 0. |
| Gold price | `INTEGER` centavos per gram | |
| Business date | `TEXT` `YYYY-MM-DD` | The phone's local calendar date, with no time zone. No future dates (checked against today's local date). |
| Timestamp | `INTEGER` Unix milliseconds, UTC | `created_at`, `updated_at`, and the `*_at` columns that record when something happened. |
| Boolean | `INTEGER` 0 or 1 | |
| Short text | `TEXT`, trimmed | Names and titles: 1–80 characters (book and note titles: 1–200). Empty after trimming = missing. |
| Remarks | `TEXT`, nullable | Up to 1,000 characters. Empty is stored as `NULL`. |
| Rating | `INTEGER` half-stars 0–10, nullable | `NULL` = "Not rated", which is different from `0` (0 stars). `7` = ★ 3.5. |

Every user record has `created_at` and `updated_at`. `updated_at` changes only when a user-visible field changes;
import conflict rules depend on this.

## 2. Tables

### App

| Table | Columns | Notes |
|---|---|---|
| `app_meta` | `key TEXT PK`, `value TEXT` | `schema_version`, `install_id` (UUID), `first_run_at`. |
| `settings` | `key TEXT PK`, `value TEXT` (JSON), `updated_at` | The full key list is in §4. |
| `deletions` | `entity TEXT`, `record_id TEXT`, `deleted_at`; PK (`entity`, `record_id`) | Tombstones. Written when a record is permanently deleted (after its Undo expires). Import uses them so deleted records don't come back silently. Kept forever (small). |
| `exports_log` | `id`, `kind` (`manual` \| `safety`), `file_name`, `created_at`, `row_counts` (JSON) | Drives "Last export" and keeps the 3 newest safety exports. |

### Finance · Savings

| Table | Columns | Notes |
|---|---|---|
| `savings_accounts` | `id`, `name`, `platform`, `type`, `remarks`, `sort_order INTEGER`, `archived_at` (business date, nullable), `created_at`, `updated_at` | `name` is unique among accounts that aren't archived (case-insensitive). `platform` and `type` are free text with suggestions (§3). The "current balance" is never stored; it is the latest balance update. |
| `balance_updates` | `id`, `account_id` → `savings_accounts.id`, `date`, `balance` (centavos, **0 allowed**), `is_unchanged`, `remarks`, `created_at`, `updated_at` | **One per account per date:** UNIQUE(`account_id`, `date`). Saving again on the same date replaces it. `is_unchanged` = 1 when saved with "Balance is unchanged". Past dates allowed, future dates not. |

Adding an account with a starting balance creates the account plus its first balance update in one transaction.
Deleting an account with updates is allowed only after a confirmation that suggests archiving instead. It deletes its updates too.

### Finance · Gold

| Table | Columns | Notes |
|---|---|---|
| `gold_items` | `id`, `name`, `weight_mg`, `karat INTEGER`, `vendor`, `purchase_date`, `cost` (centavos), `status` (`held` \| `disposed`), `disposed_date` (nullable), `remarks`, `created_at`, `updated_at` | `karat` 1–24. `disposed_date` is required when status is `disposed`, and must not be before `purchase_date`. |
| `karat_prices` | `id`, `karat`, `price_per_gram` (centavos), `date`, `created_at`, `updated_at` | Price history. UNIQUE(`karat`, `date`): saving twice on one day replaces it. The current price for a karat = the row with the latest `date`. |

### Finance · Expenses

| Table | Columns | Notes |
|---|---|---|
| `expenses` | `id`, `item`, `vendor`, `amount` (centavos), `date`, `is_refunded`, `refunded_at` (timestamp, nullable), `remarks`, `created_at`, `updated_at` | `vendor` is required. Refunded expenses stay in the table and are left out of every total. |

### Library

| Table | Columns | Notes |
|---|---|---|
| `books` | `id`, `title`, `author` (nullable), `size_kb INTEGER` (nullable, ≥ 1), `on_kindle`, `status` (`not_started` \| `reading` \| `finished` \| `abandoned`), `acquisition` (`purchased` \| `free` \| `other`), `acquired_date` (nullable), `amount` (centavos, nullable), `rating_half` (nullable 0–10), `remarks`, `created_at`, `updated_at` | `amount` is **required when `acquisition = purchased`** and must be `NULL` otherwise. The form fills `acquired_date` with today; it is nullable only so imported books with no date aren't rejected (reports show them as "No date"). |

### Notes

| Table | Columns | Notes |
|---|---|---|
| `folders` | `id`, `name` (unique, case-insensitive), `sort_order`, `created_at`, `updated_at` | One level only. **Unfiled is not a row**; it means `folder_id IS NULL`. |
| `tags` | `id`, `name` (unique, stored lower case without `#`), `created_at`, `updated_at` | Shown as `#name`. Allowed characters: letters, digits, `-`, `_`; 1–40 characters. |
| `notes` | `id`, `folder_id` (nullable), `title`, `content` (rich-text JSON), `plain_text`, `is_pinned`, `pinned_at`, `is_locked`, `cipher` (nullable), `edited_at`, `trashed_at` (nullable), `created_at`, `updated_at` | See "Locked notes" below. `plain_text` is the content without formatting, kept in step with `content`. It feeds search and the workbook's readable Notes sheet. |
| `note_tags` | `note_id`, `tag_id`; PK both | Unlocked notes only. |
| `note_drafts` | `note_id PK`, `content`, `saved_at` | Crash recovery (rules in F2). |
| `vault` | single row: `id = 1`, `kdf_params` (JSON), `salt`, `salt_recovery`, `wrapped_key_password`, `wrapped_key_recovery`, `key_check`, `created_at`, `updated_at` | Exists only after the vault is set up. Field meanings and algorithms are in F2. |

**Locked notes.** When `is_locked = 1`, `title`, `content` and `plain_text` are `NULL`, and the note has no `note_tags` rows.
The title, content and tags are encrypted together into `cipher`. `folder_id`, `is_pinned`, dates and `trashed_at` stay
readable, because the list shows "Locked note · Personal · 9 Oct". Locked notes are never written to the search index.

**Trash.** Moving a note to the trash sets `trashed_at`. After 30 days it is deleted and a tombstone is written.
The check runs when the app starts and when it comes to the foreground.

The rich-text JSON format is set in F3, together with the editor package. The data model only needs it to be JSON text.

## 3. Suggestions and Lists

Vendor, savings platform and account type suggestions come from values already used (most used first, then most recent).
Settings › Lists can **rename** a value (updates every record using it, in one transaction) or **hide** it from suggestions.
Hidden values are stored in settings key `lists.hidden` (§4). No separate table is needed.

## 4. Settings keys

| Key | Default | In workbook |
|---|---|---|
| `theme` | `system` (`light`, `dark`) | Yes |
| `amounts.hide_on_open` | `false` | Yes |
| `dashboard.widgets` | ordered list of the 10 widgets with on/off, defaults as in docs/04 | Yes |
| `bar.tools` | `["finance","library","notes"]` (0–3 tool IDs, ordered) | Yes |
| `backup.reminder_days` | `30` (7, 14, 30, 60, 90) | Yes |
| `savings.month_end_reminder` | `{ "on": true, "time": "20:00" }`, on the last day of each month | Yes |
| `gold.stale_days` | `30` | Yes |
| `lists.hidden` | `{ "vendor": [], "platform": [], "type": [] }` | Yes |
| `notes.view` | `grid` (`list`), Notes home layout (decision M5-4) | Yes |
| `app_lock` | `{ "on": false, "relock_after_s": 60 }` (0, 60, 300) | **No** (belongs to this phone) |
| `vault.biometric` | `false` | **No** (belongs to this phone) |
| `search.recent` | up to 5 strings | **No** |
| `backup.last_export_at` | none | **No** (comes from `exports_log`) |

## 5. Indexes (minimum)

`balance_updates(account_id, date)`, `expenses(date)`, `expenses(vendor)`, `gold_items(status)`, `karat_prices(karat, date)`,
`books(status)`, `books(acquired_date)`, `notes(trashed_at, is_pinned, edited_at)`, `notes(folder_id)`.
The search index (FTS5) is defined in F2.

## 6. Schema versions

`app_meta.schema_version` starts at 1. Every change ships with a drift migration and a migration test that opens a database
saved by the previous version (F3). A migration never deletes user data. When a column is removed, its values move first.

## Decisions (owner, 14 Oct 2026)

1. A balance of **₱0.00 is allowed** (for example, an emptied account before it is archived).
2. Two **active** savings accounts **can't share a name** (case-insensitive). An archived account's name may be reused.
