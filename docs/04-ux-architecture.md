# UX architecture

Approved 13 Oct 2026. Clickable versions of these screens are on the design canvas ([06-design-progress.md](06-design-progress.md)).

## Sitemap

```
First run: Welcome → Start fresh | Restore from a workbook (→ import preview)
App lock gate (if on)

Home (tab)
├─ Dashboard: preset widgets, quick-add menu, search, hide amounts, settings
└─ Settings
   ├─ Appearance (theme)
   ├─ Dashboard (reorder / show / hide / reset)
   ├─ Security: app lock, notes vault (password, biometrics, recovery code, reset), hide amounts on open
   ├─ Finance: karat prices (shortcut), month-end reminder
   ├─ Lists: vendors, savings platforms
   ├─ Data & backup: export, import → preview, backup reminder, safety exports
   └─ About: version, licences, privacy

Finance (tab) — top tabs
├─ Savings: total card (Update balances, History), 12-month chart, accounts
│  ├─ Account detail: by month / all updates / chart; update, edit, archive
│  ├─ Update balances (all accounts)
│  ├─ Add account · History report · Archived accounts
├─ Gold: value / cost / gain / weight, price date, items
│  ├─ Item sheet (add, edit, dispose, delete; decision M3-1) · Karat prices (→ history) · Disposed items
└─ Expenses: year switcher, YTD vs last year, filters, list by month
   ├─ Expense detail (mark refunded, delete) · Add expense (sheet) · Spending by year

Library (tab): status filter, sort, list → book detail; add book; Library stats
Notes (tab): folders, tags, pinned, grid/list → editor; note menu; folders, tags, trash
Tools (tab): launcher grid of all tools; Edit bar
Global search: full screen, scope chips, grouped results
Vault unlock: sheet, wherever a locked note opens
```

## Navigation rules

- Bar: Home · up to 3 chosen tools · Tools. The active tab is a neutral pill on shell screens and a tool-tinted pill inside a tool.
- The bar is hidden in editors, forms and search. Each tab keeps its own back stack, and tapping the active tab returns to its main screen.
- System back gesture. Forms with unsaved changes ask before discarding; notes never ask (autosave).
- Each main screen has one add button for its main record. Home's opens the quick-add menu.
- Forms with 6 fields or fewer open as sheets; longer ones open full screen.

## Main flows

| # | Flow | Key rule |
|---|---|---|
| F1 | First run | The vault is set up the first time a note is locked, not at first run |
| F2 | Month-end balances | "Unchanged" counts as Recorded; untouched accounts become Carried |
| F3 | Add expense | "Save & add another" keeps the date and vendor; possible duplicates trigger a warning, not a block |
| F4 | Gold prices | An item can be saved before its karat has a price; values are always labelled "estimate, as of [date]" |
| F5 | Add book | The amount appears and is required only for Purchased |
| F6 | Write a note | Autosave; a blank note is discarded on exit |
| F7 | Lock / unlock a note | Biometrics only if available; 5 wrong passwords trigger a growing wait |
| F8 | Forgot vault password | Recovery code → new password; otherwise the vault can be reset (deletes locked notes) |
| F9 | Export | States plainly that the file is not encrypted |
| F10 | Import / restore | Preview (New / Changed / Same / Check), keep mine or use file's, safety export first, nothing deleted |

## Dashboard widgets (default order)

| # | Widget | Default | Opens |
|---|---|---|---|
| W1 | Needs attention (due balances, stale gold prices, overdue export) | on | the relevant fix |
| W2 | Total savings | on | Savings |
| W3 | Savings trend (12 months) | on | History report |
| W4 | Gold holdings | on | Gold |
| W5 | Spending this year | on | Spending by year |
| W6 | Recent expenses | off | Expense / list |
| W7 | Currently reading | on | Book / Library filtered to Reading |
| W8 | Library snapshot | off | Library stats |
| W9 | Pinned notes (locked ones show "Locked note") | on | Note |
| W10 | Recent notes | off | Note / Notes |

A new tool's widgets start hidden.

## Search

- Results start after 2 characters, ignoring case and accents. Every word must match from its start, and numbers also match amounts exactly.
- Results are grouped in bar order with counts, showing the top 3 per group and "See all".
- Archived, disposed and refunded records are included, with labels. Notes in the trash are excluded.
- **Locked notes are never indexed.** A fixed footer, "Locked notes aren't searched", appears on every search.
- The last 5 searches are kept on the phone and can be cleared.

## States

- **Empty:** one sentence plus the main action. Filtered-empty states offer "Clear filters". Reports with too little data say what is missing.
- **Loading:** local data is instant. A skeleton appears only after 300 ms, and import and export show step-by-step progress.
- **Validation:** checked when leaving a field and on Save, with inline messages in words. Amount > 0 with 2 decimals, grams > 0 with 3 decimals, no future dates.
- **Errors:** typed input is kept and "Try again" is offered. Bad import files explain what to do.
- **Confirmation:** Undo for anything reversible, a dialog for permanent actions, typing DELETE for a vault reset.

## Accessibility

- WCAG 2.2 AA in both themes. Gains and losses always carry a +/− sign and an arrow, never colour alone.
- Text scales to 200%. Touch targets are at least 48 dp. Screen-reader labels throughout: amounts are read in pesos and centavos, and ratings as "out of 5".
- Every chart has a "View as table" option. Reduce motion is respected. The app-switcher preview is blurred when the app lock is on.
