# Acceptance checklist (M9 · Finish)

Tick each item on your phone (or the emulator `OZONE_A03_API33`) with the M9 build. This is F3-03 §4 written as
steps. When every box is ticked, OZONE 1.0 is accepted.

**Before you start**
- Export a workbook first (Settings › Data & backup › Export) and copy it to your PC, so nothing can be lost.
- Use your own data where it fits. Items marked *(test data)* need a few throwaway records you delete afterwards.

## Shell
- [ ] The bar shows Home, the tools you chose in Edit bar, and Tools.
- [ ] In Finance, open an account, then tap Library and come back: Finance is still on the account (each tab keeps its place).
- [ ] Tapping the tab you are already on returns to its top screen.
- [ ] Change the bar in Tools › Edit bar: the bar changes at once.

## Savings
- [ ] *(test data)* Two accounts: A updated on 30 Sep (₱312,400.00); B with ₱414,000.00 on 30 Sep and ₱420,150.00 on 12 Oct.
      In October, A shows **Carried · 30 Sep**, October's total is ₱732,550.00 and the change is **▲ +₱6,150.00** (A is Not counted).
- [ ] "Balance is unchanged" on Update balances makes that month **Recorded** for the account.
- [ ] From the 25th, Home › Needs attention lists accounts that need this month's balance.

## Gold
- [ ] An item's value is its grams × the karat price, rounded once (check one item by hand).
- [ ] An item whose karat has no price is named ("No price for 21K") and not counted in the value.
- [ ] Prices older than 30 days show "Gold prices are N days old" on Gold and Home.

## Expenses
- [ ] Mark an expense Refunded: it stays in the list struck through, and every total drops by its amount.
- [ ] "This year vs the same period last year" compares the same dates (check around 29 Feb if you have data then).

## Library
- [ ] Purchased needs an amount; Free and Other don't.
- [ ] Ratings go 0–5 in halves; "Not rated" is different from 0 stars.
- [ ] Kindle sizes: 1,024 KB shows as 1.0 MB.

## Notes
- [ ] Type in a note and leave after a second: the text is saved (autosave after 1 s).
- [ ] Force-close OZONE while typing, reopen: "Recovered unsaved changes" appears.
- [ ] A note in the trash for 30 days is gone (or check that Trash says when each note will be deleted).
- [ ] Deleting a folder keeps its notes (they become Unfiled).
- [ ] Rename a tag to an existing tag's name: they merge.

## Vault
- [ ] Lock a note: set up a vault password, save the recovery code.
- [ ] Leave OZONE and come back: locked notes are locked again.
- [ ] Unlock with the password, and with fingerprint if you turned it on.
- [ ] Forgot password: the recovery code works, and you get a new code.
- [ ] *(test data)* Reset vault (type DELETE): only locked notes are deleted.

## App lock
- [ ] Turn on App lock: OZONE asks for your phone's PIN, pattern or fingerprint.
- [ ] It relocks after the delay you chose.
- [ ] The recent-apps screen shows a blank preview of OZONE.

## Search
- [ ] Partial words match ("gro" finds Groceries), accents don't matter, and an exact amount like 1,299 matches.
- [ ] Locked notes and notes in the trash never appear.
- [ ] Results appear as you type, with no noticeable wait.

## Backup
- [ ] Export opens the "Save to" screen; the file opens in Excel and in Google Sheets.
- [ ] Import your export back: the preview says every row is **Same** and nothing is deleted.
- [ ] After an import, Settings › Data & backup › Safety exports lists a safety copy.
- [ ] *(test data)* Edit the exported file on your PC (add a gold item, leave ID empty), import it: the preview shows 1 **New**.

## Reminders
- [ ] With the month-end reminder on, the notification arrives on the last day (within a few minutes), also after restarting the phone.
- [ ] The notification permission was asked once, at first run (or from Settings › Finance).

## Accessibility (M9)
- [ ] TalkBack reads an amount as "… pesos and … centavos" and a rating as "… out of 5".
- [ ] Every button is announced with a name.
- [ ] With the phone's font size at the largest setting, screens still fit (nothing cut off).
- [ ] Light and dark themes are both easy to read.

## Finish (M9)
- [ ] Screens appear without a visible wait; long lists scroll smoothly.
- [ ] Settings › About shows **1.0.0**, the licences, privacy and the error log.
- [ ] Import of a full backup finishes in a few seconds on your phone (M9-7).

## Recipes (1.2.0 · M14)

Tick these with build 19 or later. Add Recipes to the bar first (Tools › Edit bar) or open it from Tools.
Recipes you make for these checks are *(test data)*: delete them afterwards.

**Recipe**
- [ ] *(test data)* Type a recipe with 4 servings, an ingredient `½ cup` in a section "For the sauce", and two steps. Save,
      leave and reopen it: the same ingredients, section and steps are there.
- [ ] On that recipe, change servings 4 → 6: the `½ cup` line shows **¾ cup**; "to taste" lines stay as written.
- [ ] Delete it, tap **Undo**: it's back with its photo, ingredients and steps.
- [ ] Search (Home › search) for one of its ingredients: the recipe is found under Recipes.

**Scanning** (print a recipe page, or use a cookbook)
- [ ] Turn on airplane mode, then Add recipe › Scan a page: the text is read and **Check what was read** opens.
- [ ] A clean printed page gives the right title and every ingredient and step after at most 3 corrections on the
      check screen (long-press a line to fix it; the move button sends it to another group).
- [ ] After saving (or cancelling), no scanned page is left in your gallery or in OZONE's files; only a photo you chose
      to keep as the recipe's photo stays.

**What can I cook?**
- [ ] Tick a few ingredients: recipes move into **Ready to cook**, **Missing 1–2** and **Needs more**; salt, pepper,
      water and oil count as always there (Settings › Tools › Recipes lets you change them).
- [ ] Turn on the **What can I cook?** widget (Settings › Dashboard): it shows the same ready count and top recipes
      as the screen, and changes at once when you tick an ingredient.

**Backup**
- [ ] Export (Settings › Data & backup): the file is a `.zip`. Import it back: every recipe is **Same** and every photo
      is still there.
- [ ] *(test data)* Import a damaged backup (on your PC, cut a copy of the export `.zip` in half, or zip up any
      other files): the import refuses it, says why, and nothing changes.

**Accessibility and finish**
- [ ] TalkBack reads an ingredient line with its amount in words ("a half cup …") and every recipe button by name.
- [ ] At the largest font size, Recipes, a recipe, New recipe and What can I cook? still fit (nothing cut off).
- [ ] Settings › About shows **1.2.0** and, under licences, **Google ML Kit**.
