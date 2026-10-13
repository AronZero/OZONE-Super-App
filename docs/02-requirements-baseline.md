# Requirements baseline (v1)

Approved 13 Oct 2026. This file supersedes the earlier analysis boards on the design canvas.

## Platform and data

- Flutter, one codebase. Android is the primary test device, and iOS is supported.
- Offline and on-device only, with no backend. The user starts fresh (no migration of existing data).
- PHP only. Money is stored as whole centavos and shown as `₱1,234.56`.
- **The `.xlsx` workbook is the only import, export and backup format.** It covers every tool, notes, gold price history and settings.
- No encryption of the database or the backup file. **Locked notes stay encrypted inside the workbook.**
- Automatic Android and iCloud backup is **off** (local-only). A reminder appears when the last export is older than 30 days (adjustable).
- Import shows a preview first and never deletes or silently overwrites. A safety export is saved before every import.
- First run offers **Start fresh** or **Restore from a workbook**.

## Shell

- Bottom bar: **Home · up to 3 chosen tools · Tools**. Home and Tools are always present.
  The default is Home · Finance · Library · Notes · Tools. "Edit bar" picks and orders the 3.
- Finance has top tabs: Savings · Gold · Expenses.
- Search sits in the top bar of every main screen. Settings opens from Home.
- Dashboard: preset widgets with reorder, show/hide and reset only (no free-form layout and no sizes).
- Global search is grouped by tool and opens the exact record. **Locked notes are never indexed or searched.**
- Theme: System, Light or Dark. Optional app lock. A "Hide amounts" toggle (`₱ ••••`).

## Savings

- Account fields: name, platform, type, current balance and remarks. Accounts can be archived (history is kept).
- **Dated balance updates** (date, balance, remarks) are the source of truth. Past dates are allowed.
- Monthly history is worked out on demand: each month uses the latest update on or before month-end, and is labelled
  **Recorded**, **Carried** (an older value, shown dashed and never counted as a change) or **No data** (before tracking began).
  No background jobs and no invented values.
- **Net change only.** Changes are not split into interest, deposits, withdrawals or transfers.
- Month-on-month and year-on-year comparisons, up to 5 years.
- A month-end reminder notification (default 8 pm on the last day of the month, adjustable, can be turned off).
- "Update balances" updates all accounts on one screen. **"Unchanged"** confirms a month as Recorded.

## Gold

- Item fields: name, grams (no stones), karat, vendor, purchase date, cost and remarks. Status is **Held** or **Disposed** (disposed items are excluded from totals).
- A **manual price per gram for each karat**. Every save is kept with its date (price history).
- Value = grams × price for that karat. Totals: weight, cost, estimated value and gain, always shown with the price date.
- A price is flagged as stale after 30 days.

## Expenses

- Fields: item, vendor (with suggestions from past entries), amount, date and remarks. No category or platform field.
- **Refunded** tag: the expense is excluded from every total, as if deleted, but stays visible (struck through).
- Filter by year, month, vendor, amount and refunded. Sort by date or amount. Search.
- Yearly totals over 5 calendar years, with this year so far compared with the same period last year.
- Book purchases are **not** included (they belong to the Library).

## Library

- Fields: title, author (one text field), size in KB, on Kindle, status, acquisition, acquired date, amount, rating and remarks.
- Status: **Not started · Reading · Finished · Abandoned**. There is no finished date.
- Acquisition: **Purchased** (amount required) · **Free** · **Other**.
- Rating 0–5 in steps of 0.5, nullable ("Not rated" is not the same as 0).
- Reports: Kindle storage (MB/GB, 1 MB = 1,024 KB), total spent on books, books per year **by acquired date** with a status filter,
  counts per status, average rating, acquisition split.

## Notes

- Rich text: bold, italic, underline, headings, bulleted and numbered lists, checklists, highlight and text colour. Pinning.
- One level of **folders** (default "Unfiled") **and** multiple **tags** per note.
- **Notes vault:** one password, optional biometrics, a one-time recovery code. Titles are hidden too.
  The vault relocks when you leave the app, and screenshots are blocked while it's open.
  Without the password or recovery code, locked notes cannot be recovered. A vault reset deletes locked notes (type DELETE to confirm).
- Biometric unlock appears **only** if the phone has an enrolled sensor. Its label follows the platform.
- Autosave (about 1 s after typing stops, and when the app goes to the background), draft recovery after a crash, and a 30-day trash.
- In the workbook: a readable **Notes** sheet plus a **Notes_Content** sheet holding the formatted JSON, split into rows over 30,000 characters.

## Deletion rules

- Finance and book records: delete with an Undo message. Records with history suggest archiving first.
- Notes: move to the trash (30 days), or delete forever with a confirmation.
