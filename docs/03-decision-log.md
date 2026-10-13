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

## Open

- Trademark search for "OZONE", needed only before any public app-store release.
