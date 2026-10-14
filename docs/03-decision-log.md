# Decision log

All decisions were made by the product owner on 13 Oct 2026 unless noted.
"Rec." means the owner accepted the recommended option.

## Discovery: batch 1

| # | Topic | Decision |
|---|---|---|
| Q1 | Existing data | Start fresh |
| Q2 | Platforms | Both platforms via Flutter; Android is the daily phone |
| Q3 | Savings history | Worked out from dated balance updates (Recorded / Carried / No data) (rec.) |
| Q4 | Explaining changes | Net change only; no breakdown |
| Q5 | Locked notes | One vault password, optional biometrics, recovery code (rec.) |
| Q6 | Backup | Excel only; no database or backup encryption |
| N1 | Gold | No stones; manual price per karat |
| N2 | Currency | PHP only |
| N3 | Book purchases | Kept separate from Expenses |
| N4 | Widgets | Preset only: arrange and show/hide |

## Discovery: batch 2

| # | Topic | Decision |
|---|---|---|
| Q7 | Navigation | Bottom bar (rec.) |
| Q8 | Book values | Not started / Reading / Finished / Abandoned; Purchased / Free / Other; **no finished date** |
| Q9 | Notes organization | Folders + pinning **and** tags |
| Q10 | Expense "where" | Vendor only |
| Q11 | OS cloud backup | Off (rec.) |
| Q12 | Locked notes in export | Included, still encrypted (rec.) |
| — | Notes storage in Excel | Delegated; Notes + Notes_Content (JSON) sheets |
| — | Refunded | Tag that excludes the expense from totals; the record is kept |
| — | Books per year | By acquired date only |

## UX architecture review

| # | Topic | Decision |
|---|---|---|
| R1 | Deleting records | Undo message; trash only for notes (rec.) |
| R2 | Savings add button | **Add account**; "Update balances" is a button on the total card |
| R3 | Notes home default | Two-column grid with a list toggle (rec.) |
| R4 | Home quick-add | One add button with a 5-item menu (rec.) |

## Design

| Topic | Decision |
|---|---|
| Visual direction | **B · Soft Utility** (Manrope, rounded tonal cards, a tint per tool) |
| Scaling to more tools | Bar = Home + up to 3 chosen tools + Tools launcher; **Home and Tools always present**, even with only 3 tools |
| Foundations | Approved: neutral shell, colour belongs to the tools, Manrope type scale, 4 dp spacing |
| Logo | **Concept C · The Bond**: three overlapping atoms; overlaps are fixed colours; the centre is the "ozone core" |
| Tool palette | **P1 · Ozone Triad**: Finance teal `#16676A`, Library blue `#1F5A8F`, Notes violet `#5B3E99` |
| Biometrics | Shown only on phones with an enrolled sensor; otherwise hidden |
| Import entry point | Settings › Data & backup › Import workbook; also first run "Restore from a workbook" |
| Components | Approved |
| Wave 1 screens | Approved |
| Wave 2 review | Expense filters are enough; Library stats and Notes home stay as designed |
| App lock method (14 Oct) | The phone's own screen lock; no separate OZONE PIN |
| App lock relock (14 Oct) | After 1 minute in the background by default; Immediately / 1 min / 5 min (rec.) |
| Folders and tags (14 Oct) | One "Folders & tags" screen with two tabs; tags can be renamed, merged and deleted (rec.) |
| Wave 3 review pace (14 Oct) | Build all of Wave 3, then one review |
| Wave 3 review (14 Oct) | Approved; Settings uses a cog icon; Edit bar preview shows tool icons |

## Task F (build specification)

| # | Topic | Decision |
|---|---|---|
| F-Q1 | Spec format | Markdown in `docs/spec/` plus one canvas board per part |
| F-Q2 | Audience | Claude Code builds it milestone by milestone; must stay readable for a Flutter developer without AI |
| F-Q3 | Technical choices | Claude proposes well-known, verified, safe packages in one table for approval |
| F-Q4 | Devices | Android 8+ and iOS 15+; reference phone Samsung Galaxy A03, Android 13 |
| F-Q5 | Review pace | Review after each part (F1, F2, F3) |
| F1-1 | Zero balance | Allowed |
| F1-2 | Active account names | Must be unique (rec.) |
| F1-3 | Import without Account ID | Match by exact account name, else Check (rec.) |
| F1-4 | Changed rows on import | Default Keep mine; newer side labelled (rec.) |
| F1-5 | "Needs a balance" | From the 25th, and through the next month if the month ended Carried (rec.) |
| F1-6 | New accounts in change | Not counted; a note says so (rec.) |
| F1 | Data spec | **Approved** 14 Oct 2026 |
| F2-1 | Android app lock privacy | Blank app-switcher preview and screenshots blocked while app lock is on (rec.) |
| F2-2 | First-run reminder screen | Add "Get a month-end reminder?" after Welcome (rec.) |
| F2 | Behaviour spec | **Approved** 14 Oct 2026 |
| F3-1 | Distribution | Signed `.apk` built on the PC and copied to the phone to install by hand; no app store for now (rec.) |
| F3-2 | PC setup | Owner installs Flutter SDK + Android Studio before M0, with step-by-step help (rec.) |
| F3 | Build spec | **Approved** 14 Oct 2026. **Task F complete.** |

## Build

| # | Topic | Decision |
|---|---|---|
| M1 | Core and shell | **Approved** 14 Oct 2026 |
| M2-1 | Add / Edit account | Sheet: Name, Platform, Type, Starting balance, "Balance as of" (default today, past allowed), Remarks. Edit has no balance or date (rec.) |
| M2-2 | Single balance update | Tap one in Account detail › All updates to edit balance, remarks or "unchanged"; delete with Undo. The date stays fixed (rec.) |
| M2-3 | Savings Home widgets | Total savings and Savings trend are built in M2 with Needs attention (balances), not M7 (rec.) |
| M2-4 | Accounts order | By balance, highest first, as on W1 · Savings; no manual reorder (rec.) |
| M2 | Savings | **Approved** 14 Oct 2026 |
| M3-1 | Gold item form | One tall sheet for add and edit (all 7 fields, status Held/Disposed with its date, Delete with Undo); no separate item detail screen. Exception to docs/04 "forms over 6 fields open full screen" |
| M3-2 | Duplicate expense warning | Same vendor (ignoring case) and amount within ±3 days; a warning with "Save anyway", never a block (rec.) |
| M3-3 | Expense filters | Year from the card arrows; Vendor (one or more), Amount (min/max), Refunded only; sort Newest/Oldest/Highest/Lowest; month headers show month totals (rec.) |
| M3-4 | M3 extras | Settings › Lists (rename/hide vendor, platform, type), Home widgets Gold holdings / Spending this year / Recent expenses + gold lines in Needs attention, Karat price history with delete + Undo (rec.) |
| M3-5 | Karat chips | The 6 common karats (24, 22, 21, 18, 14, 10) plus any karat used by an item or a saved price, high to low (rec.) |
| M3 | Gold and Expenses | **Approved** 14 Oct 2026 |

## Open

- Trademark search for "OZONE", needed only before any public app-store release.
