# F1-02 · Workbook format (`.xlsx`)

The workbook is OZONE's only import, export and backup format. It must open cleanly in Microsoft Excel, Google Sheets and
LibreOffice. It is readable by a person, and people may edit it and import it again.

## 1. File

- Name: `OZONE-YYYY-MM-DD.xlsx` (local date). If that name exists in the folder, add `-2`, `-3`, and so on.
- Safety exports: `OZONE-safety-YYYY-MM-DD-HHmm.xlsx`, kept in app-private storage, newest 3 only.
- Blank template: `OZONE-template.xlsx` has every sheet with headers and no rows.
- The file is **not encrypted**. Locked notes inside it **are** encrypted (F2).

## 2. Sheet order and contents

Row 1 of every data sheet is the header row (bold, frozen). Columns appear in the order below. **Headers are matched by
name, not position**, ignoring case and spaces. Columns marked † are helpers: they are written on export to make the file
readable, and ignored on import.

| # | Sheet | Columns |
|---|---|---|
| 1 | `Read me` | Plain sentences: what the file is, that it isn't encrypted, "don't change the ID columns", how to add rows (leave ID empty), date and amount formats. |
| 2 | `_Meta` | Two columns, `Key` and `Value`: `format` = `ozone-workbook`, `format_version` = `1`, `app_version`, `schema_version`, `exported_at` (ISO 8601 UTC), `install_id`, and one `rows.<Sheet>` count per data sheet. |
| 3 | `Accounts` | ID · Name · Platform · Type · Archived on · Remarks · Created · Updated |
| 4 | `Balance updates` | ID · Account ID · Account † · Date · Balance · Unchanged · Remarks · Created · Updated |
| 5 | `Gold items` | ID · Name · Grams · Karat · Vendor · Purchase date · Cost · Status · Disposed on · Remarks · Created · Updated |
| 6 | `Gold prices` | ID · Karat · Price per gram · Date · Created · Updated |
| 7 | `Expenses` | ID · Item · Vendor · Amount · Date · Refunded · Remarks · Created · Updated |
| 8 | `Books` | ID · Title · Author · Size KB · On Kindle · Status · Acquisition · Acquired on · Amount · Rating · Remarks · Created · Updated |
| 9 | `Folders` | ID · Name · Order |
| 10 | `Notes` | ID · Title · Folder ID · Folder † · Tags · Pinned · Locked · Text † · Edited · Trashed on · Created · Updated |
| 11 | `Notes_Content` | Note ID · Part · Parts · Content |
| 12 | `Vault` | Key · Value (only when a vault exists; see F2). The first row explains that it's useless without the password or recovery code. |
| 13 | `Settings` | Key · Value · About † (only the keys marked "In workbook" in F1-01 §4) |
| 14 | `Deleted` | Type · ID · Deleted on |

## 3. Cell formats

| Kind | Written as | Accepted on import |
|---|---|---|
| ID | Text | Text. Empty = new record. |
| Money | Number, 2 decimals, format `#,##0.00` | A number, or text such as `1,234.56` / `₱1,234.56`. More than 2 decimals → **Check** (never rounded silently). |
| Grams | Number, format `0.000` | A number with up to 3 decimals |
| Business date | Excel date cell, format `yyyy-mm-dd` | A date cell, or text `YYYY-MM-DD`. Any other text (for example `10/03/2026`, which is ambiguous) → **Check**. |
| Timestamps (Created, Updated, Edited, Trashed on) | Text, ISO 8601 UTC, for example `2026-10-14T09:41:00.000Z` | The same. Empty Updated on a changed row = "unknown" (see F1-03). |
| Yes/No | `Yes` / `No` | `Yes`/`No`/`TRUE`/`FALSE`/`1`/`0`, any case. Empty = No. |
| Status, acquisition | Words as shown in the app: `Held`/`Disposed`; `Not started`/`Reading`/`Finished`/`Abandoned`; `Purchased`/`Free`/`Other` | The same words, any case |
| Rating | Number 0–5 in steps of 0.5; empty = Not rated | The same |
| Karat | Whole number 1–24 | The same; `18K` text is accepted |
| Tags | `travel, 2026` (comma-separated, no `#`) | Commas or spaces; a leading `#` is removed |

Text cells are written as text so Excel doesn't change them (for example, IDs that look like numbers).
Formulas are never written. If a formula cell is imported, its cached value is used.

## 4. Notes in the workbook

- `Notes` shows each note as one row a person can read. For locked notes, Title and Text † say `Locked note` and Tags is empty.
- `Notes_Content` holds the rich-text JSON, which is the version actually imported. Content longer than **30,000 characters**
  is split into parts of at most 30,000 characters (Excel's cell limit is 32,767). It is never split inside a surrogate pair.
  Part numbers start at 1, and Parts is the total count.
- For a locked note, Content holds the `cipher` value (base64 text), split the same way.
- If a note has no rows in `Notes_Content` (for example, one a person added in Excel), its content is built from Text †
  as plain paragraphs.

## 5. Versions

- `format_version` starts at 1 and goes up only when a change would make an older app misread the file.
- Import accepts any `format_version` ≤ its own and upgrades older layouts in code. A newer version is refused with:
  "This file is from a newer OZONE. Update the app to import it."
- Extra unknown sheets or columns are ignored. A missing optional column uses its default. A missing required column
  rejects that sheet with a message naming the column (for example: "Expenses is missing the Amount column").
- A file without `_Meta` but with OZONE-shaped sheets (for example, a template a person filled in) is treated as version 1.

## 6. Required columns per sheet

ID columns are never required (empty = new). Required: Accounts › Name · Balance updates › Account ID, Date, Balance ·
Gold items › Name, Grams, Karat, Purchase date, Cost · Gold prices › Karat, Price per gram, Date · Expenses › Item, Vendor, Amount, Date ·
Books › Title, Status, Acquisition · Folders › Name · Notes › Title or Text (for unlocked) · Settings › Key, Value.

## Decisions (owner, 14 Oct 2026)

1. When **Account ID** is empty on a balance update, import matches the account by the **Account †** name, but only for an exact
   (case-insensitive) match to one account. Otherwise the row is **Check · error: "Account not found"**.
