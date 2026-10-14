# Progress: design, specification and build

Last updated: 14 Oct 2026.

## Where things stand

| Phase | Status |
|---|---|
| Discovery, UX architecture (Task D), design (Task E: Waves 1–3, components, brand) | **Approved** |
| Build specification (Task F: F1 data, F2 behaviour, F3 build) | **Approved** 14 Oct 2026, in [spec/](spec/README.md) |
| PC setup (Flutter 3.47.5, Android Studio, NDK 28.2, osv-scanner, signing key) | **Done** 14 Oct 2026 |
| Build | M0–M3 approved; **M4 · Library built and committed, awaiting owner approval**; next M5 · Notes |

## Build log

Milestones are defined in [spec/F3-04-build-order.md](spec/F3-04-build-order.md). Each one ends with a signed APK
in `dist/` (not committed), and the owner's approval comes before the next milestone starts.

| Milestone | Date | Status | Branch | Notes |
|---|---|---|---|---|
| M0 · Project setup | 14 Oct 2026 | **Approved** (tested on the A03-like emulator) | `build/m0` (committed) | `app/` Flutter project, pinned packages, theme tokens, Manrope, adaptive icon, backups off, no INTERNET, release-check script; arm64 APK 18.7 MB; `dist/OZONE-0.1.0-build1-2026-10-14.apk` |
| M1 · Core and shell | 14 Oct 2026 | **Approved** 14 Oct 2026 | `build/m1` | Database v1 (all F1-01 tables + FTS5 search index), money/date/ID rules, settings with defaults, Undo, deletion records; Home dashboard frame; Settings, Appearance, Home dashboard arrange, Security with app lock (phone screen lock, relock delay, screenshots blocked); About; Tools launcher; Edit bar; edge-to-edge status bar. 42 tests; arm64 APK 20.3 MB; `dist/OZONE-0.2.0-build2-2026-10-14.apk`. App lock verified on the emulator. |
| M2 · Savings | 14 Oct 2026 | **Approved** 14 Oct 2026 (emulator) | `build/m2` | Finance with Savings · Gold · Expenses tabs (Gold and Expenses arrive in M3); Savings card with 12-month chart; accounts sorted by balance; Add/Edit account sheet with platform and type suggestions; Update balances (one date for all, "Balance is unchanged", one transaction); Account detail (By month, All updates with edit/delete + Undo, Chart); archive/restore with Undo, delete with tombstones; History report (5 years, vs last month / vs a year ago, table or chart); Archived accounts; Home widgets Total savings, Savings trend and Needs attention (balances). F1-04 monthly logic as pure functions; "today" refreshes at midnight and on resume. 80 tests; arm64 APK 20.9 MB; `dist/OZONE-0.3.0-build3-2026-10-14.apk`. Worked example (W1) reproduced on the emulator; app lock left on. |
| M3 · Gold and Expenses | 14 Oct 2026 | **Approved** 14 Oct 2026 (emulator) | `build/m3` | Gold tab (estimated value card, items by value, unpriced items named, "prices as of" the oldest price in use); one sheet to add/edit/dispose/delete an item (M3-1); Karat prices with live "New estimated value", price history with delete + Undo; Disposed items. Expenses tab (this year so far vs the same period last year, Vendor/Amount/Refunded filters and sort, month groups); Add expense sheet with "Save & add another" and the duplicate warning (M3-2); Expense detail with Refunded and delete + Undo; Spending by year (chart/table, by month). Settings › Lists (rename/hide vendors, platforms, types). Home widgets Gold holdings, Spending this year, Recent expenses; gold lines in Needs attention. Karat chips learn karats in use (M3-5); chip rows evenly spaced. Repos now watch table updates directly (fixes missed refreshes). 108 tests; arm64 APK 21.3 MB; `dist/OZONE-0.4.0-build4-2026-10-14.apk`. Checked on the emulator; app lock left on. |
| M4 · Library | 14 Oct 2026 | **Built; awaiting owner approval** (owner fix applied: Remarks full width) | `build/m4` (committed) | Library list (header counts, status filter, 4 sorts per M4-1, book rows with status, rating, Kindle size, acquisition); Add/Edit book full screen (amount only and required for Purchased; size in KB; On my Kindle; status; rating stepper per M4-2); Book detail (status and rating change in place, Edit, delete + Undo); Library stats (Kindle storage 1,024-based, spent on books, finished, average rating over rated books, books per year by acquired date with status filter and no-date note, by status, acquisition split). Home widgets Currently reading and Library snapshot (M4-3). Add button moved to core; card rows always full width. 125 tests; arm64 APK 21.4 MB; `dist/OZONE-0.5.0-build5-2026-10-14.apk`. Checked on the emulator; app lock left on. |

### Testing on the PC

An Android emulator, **OZONE A03 (Android 13)**, is set up to match the owner's phone: 720 × 1600, 3 GB RAM.
Its test PIN is **1234**. Start it from Android Studio › Virtual Device Manager, or ask Claude to start it and install the
latest APK. Emulator speed isn't phone speed; performance budgets are checked on the real Galaxy A03.

## Design canvas

All boards and the clickable prototype are on one private design canvas:
**https://claude.ai/artifact/S3CXJRBqxhXh27BtdUwjbS**

Open it, find **W1 · Home** or **W2 · Welcome**, and press Play. Sample data only.

| Canvas row | Contents | Status |
|---|---|---|
| 1 | Discovery: overview, requirements, problem register, MVP, decisions, baseline | Done |
| 2 | Task D UX architecture: sitemap, flows, widgets and search, states and accessibility | Approved |
| 3 | Task E: plan, 3 visual directions, scaling to 8+ tools, foundations | Approved (B · Soft Utility) |
| 4 | Brand: logo concepts, final logo | Approved (The Bond × Ozone Triad) |
| 5 | Components, light and dark | Approved |
| 6 | Wave 1 screens (10) | Approved |
| 7 | Wave 2 screens (13, including 2 dark) | Approved |
| 8–10 | Wave 3 screens (20 phone boards, including "Reminder ask (first run)") and the States board (light and dark) | Approved |
| 11 | Task F boards: F1 Data model, F2 Behaviour, F3 Build plan | Approved |

### Screens designed

**Wave 1:** Home · Savings overview · Update balances · Account detail · Note editor · Vault unlock ·
Vault setup (password) · Vault setup (recovery code) · Import preview · Settings › Data & backup

**Wave 2:** Welcome · Gold overview (light and dark) · Karat prices · Expenses · Add expense ·
Spending by year · Library · Add book · Library stats · Notes home (light and dark) · Global search

**Wave 3:** Settings menu (light and dark) · Appearance · Home dashboard arrange · Security and app lock ·
App lock gate · Export progress and done · Forgot vault password · Vault reset · Savings history report · Archived accounts ·
Expense detail (refunded) · Book detail · Note menu sheet · Folders & tags · Notes trash · Tools launcher (light and dark) · Edit bar ·
Reminder ask (first run) · States board (empty, error, confirmation, loading; light and dark).

Not drawn (simple list screens, specified in the spec): Settings › Finance, Lists; Change vault password.

## Brand files

Master SVGs, Android and iOS icon sources, and the brand sheet are in [../design/brand/](../design/brand/).
The Android launcher, themed and notification icons are vector drawables made from these SVGs (in `app/android`).
iOS icon PNGs are made when an iOS build is possible, which needs a Mac.
