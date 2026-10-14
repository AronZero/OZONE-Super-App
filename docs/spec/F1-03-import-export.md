# F1-03 · Export, import and restore

Screens: W1 · Settings › Data & backup, W1 · Import preview, W3 · Export progress → done, W2 · Welcome (Restore).
Platform file handling (save dialog, Downloads, share sheet) is in F2.

## 1. Export

1. Read everything in **one read transaction**, so the file is a consistent snapshot even if a reminder or autosave runs.
2. Build the workbook in memory, sheet by sheet, and report progress per tool (Savings, Gold, Expenses, Library, Notes, Settings),
   as on the W3 Export board.
3. Write it to a temporary file, then move it into place, so a half-written file never appears under the final name.
4. On success, add an `exports_log` row (`manual`) and update "Last export". The backup reminder resets.
5. On failure, delete the temporary file, change nothing, and show "Couldn't save the export" with **Try again** (W3 States).
6. Cancel stops at the next sheet boundary and deletes the temporary file.

Budget: on the reference phone, 10,000 total rows plus 500 notes must export in **under 10 seconds**.

## 2. Import pipeline

```
Pick file → 1 Read and check the file → 2 Read rows → 3 Match and classify → 4 Preview (user choices)
         → 5 Safety export → 6 Apply in one transaction → 7 Summary
```

**1 · Check the file.** It must be a readable `.xlsx`. `_Meta.format` must be `ozone-workbook` (or the sheets must look like
OZONE's; see F1-02 §5) and the format version must be supported. Otherwise stop with one plain message and change nothing
(for example: "This isn't an OZONE workbook. It has no Savings sheet.").

**2 · Read rows.** Each row is converted with the rules in F1-02 §3 and checked with the same validation as the app's forms
(F1-01 §1). A row that fails is marked **Error** with its sheet, row number and reason, in words
(for example: "Row 57: amount ₱1,2OO isn't a number").

**3 · Match and classify.** Each valid row is matched to the phone's data **by ID**:

| Class | When | Default action |
|---|---|---|
| **New** | ID empty, or ID not on this phone and not in `deletions` | Add (an empty ID gets a new one) |
| **Same** | ID matches and every imported field is equal | Nothing |
| **Changed** | ID matches and at least one field differs | **Keep mine** (as approved on W1 · Import preview); can be switched to **Use file's** per row or per sheet |
| **Check · possible duplicate** | New row that matches an existing record's natural key (below) | **Skip**; can be switched to Add |
| **Check · error** | Failed step 2 | Not imported; listed with reasons |
| **Check · deleted here** | ID is in this phone's `deletions` | **Skip**; can be switched to Restore |

Natural keys for duplicates: expense = date + amount + item (case-insensitive) · balance update = account + date ·
gold price = karat + date · book = title + author · account = name · folder = name · gold item = name + purchase date + grams.
For balance updates and gold prices a key match is a **Changed** row, not a duplicate, because those keys are unique (F1-01).

The Changed view shows each differing field as "Yours" and "File", plus both Updated times. The newer one is labelled
"newer", but the default stays Keep mine.

**4 · Preview.** As on W1 · Import preview: one row per sheet with New / Changed / Same / Check counts; a review list for Check
and Changed rows; and a button showing how many rows will be written ("Import 62 rows"). Nothing is written before the user confirms.

**5 · Safety export.** A full export of the current data is written to app-private storage before anything changes
(`exports_log.kind = safety`; keep the newest 3). If it fails, stop the import.

**6 · Apply.** One write transaction, in dependency order: folders → tags → accounts → balance updates → karat prices → gold items
→ expenses → books → notes → settings. Any failure rolls everything back. The message says nothing was changed and the safety
export is kept.

**7 · Summary.** Counts written per sheet, and how to undo: "To go back, import the safety export from 14 Oct, 9:41 pm."

### Rules that always hold

- **Nothing is deleted by an import.** Records missing from the file are left alone.
- `created_at` comes from the file for New rows (or now if missing). `updated_at` is set to now for any row written.
- A row that refers to something missing (a balance update whose account isn't on the phone or in the file) is
  **Check · error**: "Account not found".
- Imported settings are a Changed row per key with default Keep mine, except on first-run restore (§3).
- Vendors, platforms and tags in imported rows join the suggestion lists automatically.

### Locked notes and the vault on import

- If the phone has **no vault** and the file has one, the file's `Vault` sheet is imported with the notes. The file's vault
  password then opens them.
- If both have a vault and they are **the same vault** (same salt and key check), locked notes import like any other note.
- If they are **different vaults**, those locked notes are listed as Check: "Locked with a different vault password". To
  import them, the user enters that file's vault password; the notes are decrypted in memory and re-encrypted with the phone's
  vault (F2). Otherwise they are skipped.

## 3. Restore on a new phone (first run)

Welcome › Restore from a workbook uses the same pipeline. Every row is New, settings use the file's values, and the vault
comes with the file. Phone-only settings (app lock, biometrics) are not in the file and start at their defaults. After restore,
the app opens Home and shows: "Restored from OZONE-2026-10-13.xlsx · 1,240 rows".

## 4. Performance budgets (reference phone)

- Reading and classifying a 10,000-row file: under 8 s, with progress shown.
- The preview must stay scrollable while counts are computed (work runs in a background isolate).
- Files over 25 MB are refused with a message, because they can't be from OZONE use at this scale.

## Decisions (owner, 14 Oct 2026)

1. **Changed** rows default to **Keep mine**. The side with the newer Updated time is labelled "newer".
