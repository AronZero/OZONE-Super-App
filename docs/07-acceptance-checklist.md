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
