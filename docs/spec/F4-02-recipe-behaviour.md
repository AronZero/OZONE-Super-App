# F4-02 · Recipe: screens, scanning, matching

Screens are the canvas boards in the row "OZONE · Recipe tool" (R1–R8). Copy, layout and states follow the boards and the
States board; sample data in the boards is never shipped.

## 1. Tool definition (F3-01 §3)

| Field | Value |
|---|---|
| id / name | `recipe` / Recipes |
| tint | olive (R-1): light accent `#565F14`, tile `#ECEEDC`; dark accent `#C7CF85`, tile `#2B2E1A`. Monochrome via `ToolTint` like every tool |
| icon | Material Symbols Rounded `cooking` (outline; solid when active) |
| routes | `/recipe` list · `/recipe/:id` detail · `/recipe/new` and `/recipe/:id/edit` form · `/recipe/scan` · `/recipe/scan/check` · `/recipe/cook` (What can I cook?) |
| widgets | `recipe_cook` "What can I cook?" (off by default) |
| quick add | "Add recipe" (form) · "Scan a recipe" (camera) |
| search | Recipe entity (F4-01 §7) |
| workbook | the 4 sheets in F4-01 §4 |
| settings | Settings › Tools › Recipe: Always-there ingredients (staples) · Clear my kitchen. Settings › Lists gains "Recipe categories". |

Not in the bar by default (`bar.tools` unchanged). The first time Recipes opens, the one-time tip offers "Add it to your bar?" (E4 rule).

## 2. Screens

| Screen (board) | Behaviour |
|---|---|
| **Recipes list** (R1) | Header count; What can I cook? card with "N ready with what you have" (or "Pick what's in your kitchen" when the kitchen is empty); category chips: All · Favourites · categories in use (most used first); 2-column grid, sort per `recipe.list_sort`; card = photo (or plate icon on the tint), title (1 line), "1 h 10 min · 4 servings" (parts left out when empty). The add button opens the sheet: Type it in · Scan a page · From a photo. Empty: "No recipes yet." + Add recipe. |
| **Recipe detail** (R2) | Photo (280 dp) or tinted plate; favourite toggle; Edit; title; chips for category, prep, cook; Source line. Servings stepper (only when servings is set; 1–100) scales amounts (§6) with "As written" / "Amounts scaled from 4". Tabs Ingredients · Steps (`SegmentTabs`). Ingredient rows tick off while cooking; ticks live in memory only and reset when the screen closes. Sections show as small headings. Menu: Delete (Undo). |
| **New / Edit recipe** (R5) | Full screen (more than 6 fields, docs/04). Photo area: Add photo → sheet Take a photo · Choose from gallery; Change; Remove. Title (required), Servings, Prep, Cook, Category chips + New, Ingredients (drag to reorder, amount field with fraction keyboard row ½ ⅓ ¼ ¾, unit, name, "Matches as: garlic" tappable to edit the key name), "+ Ingredient", "+ Section heading", Steps (numbered, drag handle like the ingredients' (owner, M12), reorder, "+ Step"), Source, Notes. Unsaved changes ask before discarding. When opened from a scan, the banner "Filled in from your scan. Give it a look." shows. |
| **Scan a page** (R3) | See §3. |
| **Check what was read** (R4) | See §3. |
| **What can I cook?** (R6) | See §5. |
| **Home widget** (R7) | See §7. |

Validation in words, on leaving a field and on Save: "Give the recipe a title", "Servings is a whole number from 1 to 100",
"Amount isn't a number" (accepts `2`, `1.5`, `1,5`, `½`, `1 1/2`, `2-3`).

## 3. Scanning (R-2, R-6, R-9)

```
Scan a page:  camera app ─┐
From a photo: gallery ────┴→ Scan a page (corners, rotate, add page ≤ 4) → Read text (ML Kit, on the phone)
            → parse (§4) → Check what was read → New recipe form (filled) → Save
```

1. **Capture.** image_picker opens the phone's camera app or the system photo picker. OZONE declares no camera or storage
   permission. Pictures are requested at a longest side of 2,400 px, quality 90 (enough for print text; 1,600 px is not).
2. **Scan a page board.** The picture with four corner handles, placed 5% in from the edges (no automatic edge detection in
   v1). Rotate turns 90°. "Add page" captures another page (up to 4, read in order); "Retake" replaces the current one.
3. **Straighten.** The four corners are mapped to a rectangle with a perspective transform drawn by `dart:ui` (`Canvas.transform`
   with a 4×4 matrix built from the homography), output width = the longer of top/bottom edges, capped at 2,400 px. Written as
   PNG to the cache folder. No package.
4. **Read text.** `TextRecognizer(script: latin)` on each page, in a single recognizer reused across pages and closed afterwards.
   Progress shows "Reading page 1 of 2…" with Cancel. Budget: under 4 s per page on the reference phone.
5. **From a photo** asks once, after reading: "Use this picture as the recipe's photo?" Yes → it's resized to 1,600 px by the
   files channel and set on the form. Scanned camera pages are never offered as the photo.
6. All cache files are deleted when the check screen closes (F4-01 §3).

Errors: no text found → "No text found on this page. Try more light, or hold the phone straight above the page." with
Retake. Recognizer failure → "Couldn't read the text." with Try again (States board).

**Check what was read** (R4): page count and line count; Title field (prefilled); found Servings and Time chips; then groups
Ingredients · Steps · Notes · Not used. Each line has a move button (Material Symbols `move_item`, tinted with its group's colour) that opens a menu headed "Move to" with the
four groups and a tick on the current one; the line moves only when another is picked, with the row animation from UR3-1
and the message "Moved to Steps" (floating above Continue) (owner M12 Q5 a; this replaces the tap-to-cycle label on board R4). Long-press a line to edit its text, or split it at the cursor. Lines flagged **Check** show the
amber chip with an icon and the reason (for example "Check: vinegar?"). A banner counts flagged lines. "Continue to recipe"
opens the form filled from the groups; Notes lines join into Notes; Not used lines are dropped.

## 4. Sorting the text (rules, no AI)

Input: ML Kit blocks → lines with bounding boxes. Output: title, servings, times, and labelled lines.

1. **Reading order.** Cluster line left edges. If there are two clusters more than 30% of the page width apart, each with at
   least 4 lines, read the left column top to bottom, then the right. Otherwise top to bottom. Lines whose middles are within
   half a line height are one row, read left to right; pieces of one printed line that the recognizer split (`1` + `pack sinigang
   mix`) are joined when the gap is under 2.5 line heights (M12, seen on the emulator).
2. **Title:** the line in the top 25% of the first page whose height is at least 1.3 × the median line height; if none, the first
   line. It isn't added to any group.
3. **Headings** (case-insensitive, optional trailing colon, the whole line) switch the current section and aren't kept:
   ingredients: `ingredients`, `ingredient`, `you will need`, `what you need`, `mga sangkap`, `sangkap` ·
   steps: `method`, `directions`, `procedure`, `instructions`, `steps`, `preparation`, `how to cook`, `paraan ng pagluluto`,
   `paraan`, `pamamaraan` · notes: `notes`, `note`, `tips`, `tip`.
   Inside ingredients, a line of at most 5 words ending in `:` becomes a **section** ("For the sauce:").
4. **Details** (only on a line that starts with one of these words or has "N servings", outside Steps, at most 14 words, so
   "…and cook 5 minutes." stays a step): `serves|servings|makes|yield` + a number → servings (line goes to Not used). `prep|preparation` / `cook|cooking`
   / `total` + a duration (`1 h 10 min`, `1 hr`, `45 mins`, `1½ hours`) → prep / cook minutes (total only when neither is found,
   counted as cook).
5. **Labels.** In a known section, lines take its label. Before any heading: starts with an amount or a unit → Ingredient;
   starts with `1.`, `1)`, `Step 1` or is 8+ words ending in `.` → Step; page numbers (`112`, `p. 112`, `Page 112`) and lines of 1–2
   characters → Not used; anything else → Not used.
6. **Joining.** A step line that doesn't start a new number joins the previous step when that one doesn't end in `.`, `!` or `?`.
   An ingredient line without an amount joins the previous ingredient when that one ends with `,` or this one starts lower case.
7. **Cleaning.** Step numbers (`1.`, `Step 2:`) and bullets (`•`, `-`, `*`) are removed.
8. **Ingredient parse:** amount (whole, decimal with `.` or `,`, `1/2`, `1 1/2`, `1½`, unicode `¼ ⅓ ½ ⅔ ¾ ⅛`, ranges `2-3`, `2–3`,
   `2 to 3`), then an optional unit from the table below (case-insensitive, optional `.` or plural), then the name.

| Unit | Also read as |
|---|---|
| `tsp` | teaspoon(s), t, kutsarita |
| `tbsp` | tablespoon(s), T, tbs, kutsara |
| `cup` | cups, c, tasa |
| `g` / `kg` | gram(s), gr / kilo(s), kilogram(s) |
| `ml` / `l` | millilitre(s), milliliter(s) / litre(s), liter(s) |
| `oz` / `lb` | ounce(s) / pound(s), lbs |
| `clove` | cloves, butil |
| `pc` | piece(s), pcs, piraso |
| `head` | heads, ulo |
| `can`, `pack`, `bunch`, `slice`, `stalk`, `pinch`, `thumb` | plurals |

9. **Check flags** (amber, with the reason): ML Kit line confidence under 0.6 where the platform gives one; a word mixing letters
   and digits (`1O`, `vlnegar` is caught by the next rule); an ingredient whose key name (§5) is neither in the built-in word list
   nor among the phone's existing key names. The built-in list is about 400 common ingredient words in English and Filipino,
   written by us in `tools/recipe/domain/ingredient_words.dart` (no third-party list, so no licence issue).

The parser is pure Dart in `tools/recipe/domain/scan_parser.dart` and is tested with text fixtures (F4-03 §2).

## 5. Key names and What can I cook? (R-7)

**Key name** (suggested on save, editable on the form):
lower case → drop text after the first `,` or `(` → drop descriptor words (`fresh`, `chopped`, `minced`, `crushed`, `sliced`,
`diced`, `large`, `small`, `medium`, `whole`, `boneless`, `skinless`, `ground`, `dried`, `cooked`, `raw`, `peeled`, `finely`,
`roughly`, `thinly`) → apply the built-in synonym and plural table (`eggs`→`egg`, `itlog`→`egg`, `talong`→`eggplant`,
`spring onion`/`scallion`→`green onion`, `peppercorns`/`black pepper`→`pepper`, `cooking oil`/`vegetable oil`→`oil`,
`brown sugar`/`white sugar`→`sugar`, …, about 80 pairs in `ingredient_words.dart`) → trim. Empty result → the whole name.

**Screen** (R6): "In my kitchen" with a search field and chips of every key name used in saved recipes (most used first;
staples left out), ticked ones first. Ticking writes `kitchen` at once. Clear (with Undo) empties it.
Below, the groups, computed from saved recipes that use at least one ticked or staple key name:

| Group | Rule | Each row shows |
|---|---|---|
| Ready to cook | nothing missing | "Uses chicken, garlic, …" |
| Missing 1–2 | 1 or 2 key names missing | "Missing: bay leaves, sugar" |
| Needs more | 3 or more missing; folded behind "Show N more that need 3+ items" | the same |

Within a group: more ticked key names used first, then title. Staples always count as present. Recomputed in memory (no
index needed): budget under 50 ms for 1,000 recipes. Empty kitchen: "Tap the ingredients you have to see which recipes fit."

## 6. Servings scaling (R-8)

`factor = chosen ÷ recipe servings`. Each amount (and range end) × factor, shown as:
whole numbers plain; otherwise the nearest of `¼ ⅓ ½ ⅔ ¾` when within 0.04 of it (`1 ½`); otherwise one decimal for amounts under
10, whole numbers above. `g` and `ml` show whole numbers. Ingredients without an amount stay as written. Scaling never changes
the saved recipe. TalkBack reads "1 and a half cups soy sauce".

## 7. Home widget "What can I cook?" (R-12)

Board R7. Tinted card: header (icon, "What can I cook?", "2 ready" badge) → up to 3 rows (Ready first, then Missing 1–2), each
with photo thumbnail, title and "Ready · 15 min" or "Missing: …" → footer "From 8 ingredients in your kitchen · Update ›".
Header and footer open What can I cook?; a row opens the recipe. Empty kitchen or no matching recipes: one sentence and
"Pick ingredients". Starts hidden (docs/04 rule); it watches `recipes`, `recipe_ingredients` and `kitchen`, so it updates
right away. Entrance and press animations as UR3-1.

## 8. Accessibility and states

- Every control from F2-03 §7 rules: 48 dp targets, labels ("Add photo", "Ingredient. Tap to make it Step"), 200% text without
  overflow, contrast on tokens (olive pairs added to the contrast test).
- Check flags use an icon and words, never colour alone.
- The camera, gallery and file dialogs don't relock the app (as M8-8).
- States board patterns: list and detail skeleton after 300 ms, "Couldn't be loaded" + Try again, failed save keeps the form.

## Decisions (owner, 19 Oct 2026)

1. **F4-Q2** Only the What can I cook? widget; no Recently added recipes widget (rec.).
2. **F4-Q3** No automatic page-edge detection in v1; manual corners (rec.).

<!-- Questions as asked: -->

- **F4-Q2** Also add the "Recently added recipes" widget listed on board R0, or only What can I cook? (R-12 named only that)?
  Rec.: **only What can I cook?** for now.
- **F4-Q3** Automatic page-edge detection on the Scan board (finds the corners for you)? It needs either ML Kit Document
  Scanner (needs Google Play services and downloads a model, so not fully offline) or our own edge finder (about a milestone
  of tuning). Rec.: **no**, manual corners in v1.
