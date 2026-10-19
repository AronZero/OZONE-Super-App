# F4-01 · Recipe: data, photos and backup

Part F4 specifies the Recipe tool (decisions R-1..R-12 in docs/03, the Recipe section of docs/02, canvas boards R0–R8).
It extends F1–F3; where it doesn't say otherwise, their rules hold (IDs, timestamps, trimming, tombstones, Undo).

## 1. Tables (schema v3)

Migration v2 → v3 only adds tables, indexes and search triggers (F1-01 §6). Nothing existing changes.

| Table | Columns | Notes |
|---|---|---|
| `recipes` | `id`, `title`, `category` (nullable), `servings INTEGER` (nullable, 1–100), `prep_min INTEGER` (nullable, 0–6000), `cook_min INTEGER` (nullable, 0–6000), `source` (nullable), `notes` (nullable), `is_favourite`, `photo_file` (nullable), `created_at`, `updated_at` | `title` 1–200 characters. `category` is short text (1–40) with suggestions, like vendors (F1-01 §3). `source` up to 200, `notes` up to 2,000. `photo_file` is a file name, see §3. |
| `recipe_ingredients` | `recipe_id` → `recipes.id`, `position INTEGER`, `section` (nullable), `amount_milli INTEGER` (nullable), `amount_max_milli INTEGER` (nullable), `unit` (nullable), `name`, `key_name`; PK (`recipe_id`, `position`) | Part of the recipe, never edited on its own (no own ID). `name` 1–200, `section` 1–60 ("For the sauce"), `key_name` 1–80, lower case. 1–100 rows per recipe. |
| `recipe_steps` | `recipe_id` → `recipes.id`, `position INTEGER`, `text`; PK (`recipe_id`, `position`) | `text` 1–2,000 characters. 0–60 steps per recipe. |
| `kitchen` | `key_name TEXT PK`, `updated_at` | The ingredients ticked on What can I cook? A row means "I have it". Clearing removes all rows. |

**Amounts** are stored in thousandths so no floating point is used: `½` = `500`, `1⅓` = `1333`, `2` = `2000`.
`amount_max_milli` is set only for ranges ("2–3 cloves" = `2000`/`3000`) and must be greater than `amount_milli`.
An ingredient with no number ("salt to taste") has both `NULL`. Range 1 to 99,999,000.

**Units** are stored in their canonical short form from the unit table in F4-02 §4 (`tbsp`, `cup`, `g`, `clove`…), or `NULL`.
Unknown words stay part of `name`.

Saving a recipe writes `recipes` plus all its ingredient and step rows in **one transaction**, replacing the old child rows.
`updated_at` changes when any user-visible field of the recipe **or its children** changes.

Indexes: `recipes(title)`, `recipes(category)`, `recipe_ingredients(key_name)`.

## 2. Settings keys (add to F1-01 §4)

| Key | Default | In workbook |
|---|---|---|
| `recipe.staples` | `["salt","pepper","water","oil"]`, key names that always count as in the kitchen (R-7) | Yes |
| `recipe.list_sort` | `recent` (`title`, `favourites`) | Yes |
| `lists.hidden` | gains `"category": []` | Yes |
| `dashboard.widgets` | gains `recipe_cook` (off), after the existing 10 | Yes |

## 3. Photos (R-5)

- One optional photo per recipe. Files live in app-private storage: `<app support>/recipe_photos/<uuid>.jpg`. `photo_file` holds
  only `<uuid>.jpg`. Android auto-backup stays off (F2-03 §3); on iOS the folder is excluded from backup.
- Every photo is stored as JPEG, **longest side at most 1,600 px, quality 85** (about 200–400 KB), turned upright. Every
  picture, from the gallery, the camera or a scan, is converted by the files channel with the phone's own encoder (F4-03 §1),
  so PNG and HEIC pictures become JPEGs too (built in M11).
- Changing a photo writes a **new** file name, so the old and new photos never share a name (import relies on this).
- The old file is deleted when the recipe saves. A removed or replaced photo is kept until its Undo expires.
- **Orphan sweep** on start and resume: delete files in `recipe_photos/` that no recipe uses and that are older than 10 minutes.
- **Scanned pages are never stored** (R-5). The camera capture and the straightened page live in the cache folder and are
  deleted when the check screen closes (saved or not), and on the next start if the app was killed.

## 4. Workbook sheets (add to F1-02 §2)

The sheets are inserted after `Notes_Content`, so the order becomes … 11 `Notes_Content` · 12 `Recipes` · 13 `Recipe ingredients` ·
14 `Recipe steps` · 15 `Kitchen` · 16 `Vault` · 17 `Settings` · 18 `Deleted`. `format_version` stays **1**: older apps ignore
unknown sheets, and files without these sheets import as before.

| Sheet | Columns |
|---|---|
| `Recipes` | ID · Title · Category · Servings · Prep min · Cook min · Source · Notes · Favourite · Photo · Created · Updated |
| `Recipe ingredients` | Recipe ID · Recipe † · Position · Section · Amount · Amount max · Unit · Name · Key name |
| `Recipe steps` | Recipe ID · Recipe † · Position · Text |
| `Kitchen` | Key name · Updated |

- Amount is written as a number with up to 3 decimals (`0.5`, `1.333`). Import also accepts `½`, `1/2`, `1 1/2`.
- Photo holds the file name (`<uuid>.jpg`) or is empty. In a `.xlsx` without photos it's informational only.
- Required: Recipes › Title · Recipe ingredients › Recipe ID, Position, Name · Recipe steps › Recipe ID, Position, Text.
  An empty Key name is rebuilt from Name (F4-02 §5).
- Deleted sheet type: `Recipe`.

## 5. Backup file: `.zip` (R-4)

```
OZONE-2026-10-19.zip
├─ OZONE-2026-10-19.xlsx        the workbook (F1-02 + §4)
└─ photos/
   └─ 3f1c…-….jpg               one per recipe photo, named as in the Photos column
```

- Every export (manual and safety) writes a `.zip`, also when there are no photos, so there is one backup format (F4-Q1).
  Entries are **stored, not compressed** (JPEGs don't shrink; storing is faster).
- Names: `OZONE-YYYY-MM-DD.zip` and safety `OZONE-safety-YYYY-MM-DD-HHmm.zip` (F1-02 §1 rules otherwise).
  The "not encrypted" message adds "Recipe photos are included."
- Built in a background isolate, streamed to a temporary file entry by entry (never the whole file in memory), then moved
  into place, as in F1-03 §1. Photos are read inside the same snapshot: the list of files comes from the read transaction.
- The workbook alone stays available as **Settings › Data & backup › Blank template** (`OZONE-template.xlsx`, unchanged).

## 6. Import changes (F1-03)

**Pick:** the file picker accepts `.zip` and `.xlsx` (MIME `application/zip`, `application/x-zip-compressed`, and the xlsx type).
A `.xlsx` imports exactly as today; its recipes keep their phone photo or get none.

**1 · Check the file (zip).** Unpack into `<cache>/import-<uuid>/` with these limits, else stop with one message and change nothing:

| Rule | Limit / action |
|---|---|
| Entries allowed | exactly one `*.xlsx` at the root, plus `photos/<uuid>.jpg`. Any other entry is ignored. |
| Path safety | names with `..`, a leading `/`, `\`, or a drive letter are refused ("This backup file is damaged.") |
| Sizes | workbook ≤ 25 MB (as today); each photo ≤ 4 MB; whole archive ≤ 800 MB unpacked; at most 5,001 entries |
| Photo content | must start with the JPEG bytes `FF D8 FF`; otherwise that photo counts as missing |

Unpacking is streamed and checks sizes **while** writing, so a crafted file can't fill the phone.

**3 · Classify.** A recipe compares all its fields, ingredients and steps (in position order) and its Photo name.
Natural key for duplicates: title (case-insensitive). Kitchen rows match by key name (Same or New only; never Changed).

**4 · Preview** adds one line under Recipes: "Photos: 14 new · 2 same · 1 missing from the file". A Photo name that points to a
missing or broken file imports the recipe **without** changing the phone's photo, and is listed as Check · error
("Photo for Chicken adobo is missing from the file").

**6 · Apply.** Before the transaction, copy the needed photos into `recipe_photos/` under their names (copying only rows that will
be written: New, Use file's, Restore). Then run the transaction (order: … notes → recipes → recipe ingredients → recipe steps →
kitchen → settings). On failure, delete the photos copied in this import. After success, delete `<cache>/import-<uuid>/`.
Replaced phone photos follow §3 (deleted after the import, never during).

**Safety export** is a `.zip` too; the newest 3 are kept. Restore on first run (F1-03 §3) accepts both types.

Budgets (reference phone): export of 10,000 rows + 500 notes + 300 photos (≈ 90 MB) in under 20 s; reading and classifying
the same file in under 15 s. Without photos the F1-03 budgets hold.

## 7. Search (add to F2-02 §1)

| Entity | title | body | extra | label |
|---|---|---|---|---|
| Recipe | title | ingredient names, step text, source, notes | category, key names | Favourite |

Kept in step by triggers on `recipes`, `recipe_ingredients` and `recipe_steps`. Results open `/recipe/:id`. Group name: "Recipes".

## 8. Deletion

Delete with Undo (R-10). When the Undo expires: delete the recipe and its children, write a `Recipe` tombstone, then delete its photo file.

## Decisions (owner, 19 Oct 2026)

1. **F4-Q1** Every export is a `.zip`, also without photos (rec.).
