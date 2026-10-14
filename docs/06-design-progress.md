# Progress: design, specification and build

Last updated: 14 Oct 2026.

## Where things stand

| Phase | Status |
|---|---|
| Discovery, UX architecture (Task D), design (Task E: Waves 1–3, components, brand) | **Approved** |
| Build specification (Task F: F1 data, F2 behaviour, F3 build) | **Approved** 14 Oct 2026, in [spec/](spec/README.md) |
| PC setup (Flutter 3.47.5, Android Studio, NDK 28.2, osv-scanner, signing key) | **Done** 14 Oct 2026 |
| Build | M0, M1 approved; **M2 · Savings in progress** |

## Build log

Milestones are defined in [spec/F3-04-build-order.md](spec/F3-04-build-order.md). Each one ends with a signed APK
in `dist/` (not committed), and the owner's approval comes before the next milestone starts.

| Milestone | Date | Status | Branch | Notes |
|---|---|---|---|---|
| M0 · Project setup | 14 Oct 2026 | **Approved** (tested on the A03-like emulator) | `build/m0` (committed) | `app/` Flutter project, pinned packages, theme tokens, Manrope, adaptive icon, backups off, no INTERNET, release-check script; arm64 APK 18.7 MB; `dist/OZONE-0.1.0-build1-2026-10-14.apk` |
| M1 · Core and shell | 14 Oct 2026 | **Approved** 14 Oct 2026 | `build/m1` | Database v1 (all F1-01 tables + FTS5 search index), money/date/ID rules, settings with defaults, Undo, deletion records; Home dashboard frame; Settings, Appearance, Home dashboard arrange, Security with app lock (phone screen lock, relock delay, screenshots blocked); About; Tools launcher; Edit bar; edge-to-edge status bar. 42 tests; arm64 APK 20.3 MB; `dist/OZONE-0.2.0-build2-2026-10-14.apk`. App lock verified on the emulator. |
| M2 · Savings | — | In progress | `build/m2` | Accounts, Update balances, account detail, history report, archived accounts, monthly logic, Needs attention (balances) |

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
