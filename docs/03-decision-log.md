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
| M4-1 | Library sort | Recently acquired (default; no date last) · Title A–Z · Author A–Z · Highest rated (not rated last) (rec.) |
| M4-2 | Rating input | The − / + half-star stepper with "Clear rating" on both the book form and Book detail (rec.) |
| M4-3 | Library Home widgets | Currently reading and Library snapshot are built in M4 (rec.) |
| M4 | Library | **Approved** 15 Oct 2026 |
| M5-1 | Notes Home widgets | Pinned notes (up to 4) and Recent notes (last 3) are built in M5 (rec.) |
| M5-2 | Lock note before M6 | Shown in the note menu but disabled, saying the vault arrives in M6 (rec.) |
| M5-3 | New note from a filter | A new note made while a folder or tag filter is on goes into that folder and gets that tag (rec.) |
| M5-4 | Grid or list | Notes home remembers the layout in settings key `notes.view` (grid by default) (rec.) |
| M5-5 | Editor content | Drafts hold the title and the Delta; anything the toolbar can't make (links, fonts, sizes, images, quotes) is removed on save, typed web addresses stay plain text, and pasting from other apps brings plain text (rec.) |
| M5-6 | Notes filters | Folder chips (All, Unfiled, folders in creation order) plus one tag at a time from the tags in use; Restore in Trash has Undo, as on the W3 board (rec.) |
| M6-1 | Argon2id cost | Memory fixed at 19 MiB, parallelism 1; iterations calibrated at setup for about 1 s (2–10) (rec.) |
| M6-2 | Tags of locked notes | Sealed inside the lock and read-only while locked; change them after Remove lock (rec.) |
| M6-3 | Lock now | A "Lock notes now" button on Notes home while the vault is open (F2-01 "Lock button") (rec.) |
| M6-4 | Wrong-password wait | Stored in phone-only setting `vault.lockout`; applies to the password, not the recovery code (rec.) |
| M6-5 | Screens not drawn | Change vault password: current, new, again, strength meter. New recovery code: shown with the saved checkbox; the old code keeps working until "Use this code" (rec.) |
| M6-6 | Codes commit on Done | Setup, Forgot password and New code only write the vault when the last button is pressed, so leaving midway changes nothing (rec.) |
| M6-7 | Recovery code order | The four groups are numbered 1–4 and read left to right, then down (owner) |
| M6 | Notes vault | **Approved** 15 Oct 2026 |
| Process | Commits | Commit automatically whenever the owner approves a milestone (owner, 15 Oct 2026) |
| M7-1 | Search groups order | Bar order as in F2-02 (Finance · Library · Notes as arranged), not the fixed order on the W2 board; scope chips follow the same order (rec.) |
| M7-2 | Search scope from a tool | Finance preselects the tab in view (Accounts, Gold or Expenses), Library → Books, Notes → Notes, Home → All (rec.) |
| M7-3 | Hide amounts reach | Every display screen and Home widget; forms where amounts are typed keep showing them; chart axis labels go blank; percentages stay (rec.) |
| M7-4 | Quick-add menu | The 5 actions on the Components board (Update balances, Add expense, Add gold item, Add book, New note), grouped in bar order (rec.) |
| M7-5 | Gold results | Open the gold item sheet above the search, since items have no screen of their own (M3-1) (rec.) |
| M7-6 | Widget gaps (UX3 board) | Needs attention collapses to "All up to date"; Library snapshot adds "spent in <year>"; locked notes on Home ask to unlock, then open (rec.) |
| M7 | Search and dashboard | **Approved** 15 Oct 2026 |
| M8-1 | Workbook code | The sheets are built and read in one core module (core/workbook), not per-tool registry sections; the layout is exactly F1-02 (confirmed with M8, 15 Oct 2026) |
| M8-2 | Who sees Welcome | Only a phone with no data. Installs that already have records (yours) skip it, and get the reminder through Settings › Finance (confirmed with M8, 15 Oct 2026) |
| M8-3 | Deleted sheet | Exported for reference; an import never applies it, because an import never deletes (confirmed with M8, 15 Oct 2026) |
| M8-4 | Backup reminder with no export yet | Counted from the first run: "No backup exported yet" after the reminder period; otherwise "Last export was N days ago" (confirmed with M8, 15 Oct 2026) |
| M8-5 | Settings › Finance (not drawn) | Month-end reminder on/off and time, "Notifications are off" with Allow notifications, flag karat prices after 14/30/60 days, Karat prices (confirmed with M8, 15 Oct 2026) |
| M8-6 | Export finishing | After building, the Save to dialog opens; if it's cancelled the screen offers Save to… and Share. Sharing the file also counts as an export. Android names a clash "(1)" itself (confirmed with M8, 15 Oct 2026) |
| M8-7 | Safety exports screen | Lists the newest 3 with Share and Import (confirmed with M8, 15 Oct 2026) |
| M8-8 | System screens | Save to, the file picker, Share and the notification permission dialog don't count as leaving OZONE: app lock and the vault don't relock for them (confirmed with M8, 15 Oct 2026) |
| M8-9 | Locked note tags in workbooks | A locked note's tags travel inside its cipher; the readable Tags column is empty, as F1-02 says (confirmed with M8, 15 Oct 2026) |
| M8 | Backup and first run | **Approved** 15 Oct 2026; M8-1..M8-9 confirmed |
| M9-1 | Failed save | A dialog "Couldn’t save" with Try again / Not now (not a snackbar, which sheets would hide); the form stays open with everything typed (confirmed 15 Oct 2026) |
| M9-2 | Error log contents | Time, where (e.g. "save expense"), error type and up to 8 code locations; never the error message, which could quote typed data; 64 KB cap. Settings › About › Error log shares or clears it (confirmed 15 Oct 2026) |
| M9-3 | Load errors | "<Screen> couldn’t be loaded" with Try again (re-reads the data), replacing "close and reopen OZONE" (confirmed 15 Oct 2026) |
| M9-4 | Touch targets | Every tappable control is at least 48 dp tall (docs/04). Chips, pills and compact buttons drawn at 40–44 dp on the boards grow to 48 dp; OzoneButton never goes below 48 (confirmed 15 Oct 2026) |
| M9-5 | Chart tables | "View as table" stays on History and Spending by year. The other charts (Savings card, Account detail, Library stats) keep their numbers one tap away or in the list below, and their spoken summary reads every value (confirmed 15 Oct 2026) |
| M9-6 | How contrast is checked | Exactly, on the colour tokens (test/a11y/contrast_test.dart): every text pair is 4.5:1 or more in both themes (lowest 5.58:1). Flutter's screenshot check is not used because it mixes icons and highlight pills into the text colour. The outline colour (1.4–1.7:1) is decorative only (confirmed 15 Oct 2026) |
| M9-7 | Where performance is measured | On a temporary emulator with the A03's screen, RAM and 4 cores, in profile mode, with the generated large sample. A real A03 is slower, and the import (5.2 s of 8 s) has the least headroom. The perf test must never run on the phone with the owner's data, because it writes the sample into the app's database (confirmed 15 Oct 2026) |
| M9-8 | Test plan for 1.0 (owner Q12 A) | Data-layer coverage 92.9% (target 90%), counting logic only: table declarations (tables.dart) and the phone plugin wrapper (biometric_key_store.dart) are left out. New tests: importing locked notes from another vault, backup service (template, refused files, cancel, newest 3 safety exports), app lock settings. One on-device main-flow test (integration_test/main_flow_test.dart). Golden tests and test/fixtures/sample_workbook.xlsx are dropped: the accessibility sweep checks layout in both themes at 100% and 200%, and round trips build their data in code (confirmed 15 Oct 2026) |
| M9-9 | Smaller APK (owner Q13 A) | Release builds use --split-debug-info and --obfuscate (arm64 23.8 → 22.3 MB). Symbols and the obfuscation map are kept per version in ~/.ozone-keys/symbols/<version>/, outside the repo, to read error logs (confirmed 15 Oct 2026) |
| M5 | Notes | **Approved** 15 Oct 2026 (owner fixes: tags on one line with ellipsis; date always right-aligned) |

| UR1-1 | Bottom bar (owner B1–B2, 15 Oct 2026) | Floating rounded pill (64 dp, radius 32, 16 dp from the edges, no border, no shadow; owner removed the hairline on review), at most 440 dp wide and centred on tablets. Inactive items show an outline icon only; the active item gets a pill in the tool's accent (ink for Home and Tools) holding its solid icon and label. The bar hides while scrolling down and returns on scroll up or at the top; tab screens' add buttons move with it. With TalkBack on it never hides. Canvas boards "UI refresh · Bottom bar" (approved 15 Oct 2026) |
| UR1-2 | Icons (owner B3) | Material Symbols Rounded (Apache-2.0), one variable font asset pinned to google/material-design-icons commit bd8cb85 (25 Sep 2026), not a package. All icons live in lib/core/ui/theme/oz_icons.dart. Outline by default (theme fill 0); solid (fill 1) only for active or selected states: bar item, pinned, stars, checked radio, saved tick. Release builds keep only the glyphs used (15.2 MB → 155 KB) |
| UR1-3 | Motion (owner B4) | Replaces "150–200 ms, functional only": press 120 ms, icon fill 240, screen change 260, hide on scroll 280, label 300, pill 340 with slight overshoot, icon pop 380. Tab changes and pushed screens fade in and rise 10 dp (iOS keeps its own transition so swipe-back works). Light selection haptic on tab change. Reduce motion makes every change instant |
| UR1-4 | Version | The UI refresh ships as 1.1.0; step 1 is build 11, the review fixes build 12 |
| UR1-5 | Review fixes (owner, 15 Oct 2026) | Add buttons lose their shadow (flat like the bar). Home's top bar shows the OZONE mark (36 dp, full colour, light/dark variants) before the title |

| UR2-1 | Monochrome (owner M1–M6, canvas approved 15 Oct 2026) | A Monochrome switch in Settings › Appearance (setting `theme.monochrome`, in workbooks) recolours whichever theme is active. Light: screen #F4F4F4, cards #FFFFFF, inputs #EBEBEB, bar #E8E8E8, ink #111111, secondary #5C5C5C. Dark (near-black, from the owner's samples): #0B0B0B, #161616, #1F1F1F, #1A1A1A, ink #F2F2F2, secondary #A6A6A6. Every text pair ≥ 5.4:1 |
| UR2-2 | What keeps colour | Only green and red, at their existing values: gains, losses, form errors, Needs attention (red, M3) and delete/destructive actions. Tool accents become ink; tinted cards become plain cards; chips, avatars and small tiles use the input grey; selected tabs, chips, pills and buttons are solid ink. Charts: current period ink, past periods ink at 45% (M4). The user's note colours stay (M5). Search highlight becomes grey |
| UR2-3 | Logo in Monochrome (owner, 15 Oct 2026; replaces M2's silhouette) | The greyscale mark. Dark uses the iOS tinted source greys (design/brand/ios/AppIcon-1024-tinted.svg); light uses greys matched to the colour light mark's brightness (#7A7A7A, #6F6F6F, #8D8D8D circles; #5B5B5B, #6A6A6A, #686868 overlaps; core #363636), so the core stays dark on a light screen. App icon and splash keep the colour brand |
| UR2-4 | Owner fixes with step 2 | Finance › Expenses "Yearly report" stays on one line (shrinks instead of wrapping). Pill chips (Library status, Notes folders and tags, Expenses filters, Search scopes) are at least 72 dp wide (PillSize.minWidth), the width of a "Gold" pill, so "All" stays a pill. Version 1.1.0 build 13 |

## Open

- Trademark search for "OZONE", needed only before any public app-store release.
