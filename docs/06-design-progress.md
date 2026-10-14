# Design progress

Last updated: 14 Oct 2026.

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
| 7 | Wave 2 screens (13, including 2 dark) | Reviewed; no changes requested |
| 8–10 | Wave 3 screens (19 phone boards, 2 dark) and the States board (light and dark) | Approved (settings icon changed to a cog; Edit bar preview icons added) |

## Screens done

**Wave 1:** Home · Savings overview · Update balances · Account detail · Note editor · Vault unlock ·
Vault setup (password) · Vault setup (recovery code) · Import preview · Settings › Data & backup

**Wave 2:** Welcome · Gold overview (light and dark) · Karat prices · Expenses · Add expense ·
Spending by year · Library · Add book · Library stats · Notes home (light and dark) · Global search

**Wave 3 (approved 14 Oct):** Settings menu (light and dark) · Appearance · Home dashboard arrange · Security and app lock ·
App lock gate · Export progress and done · Forgot vault password · Vault reset · Savings history report · Archived accounts ·
Expense detail (refunded) · Book detail · Note menu sheet · Folders & tags · Notes trash · Tools launcher (light and dark) · Edit bar ·
States board (empty, error, confirmation, loading; light and dark).
The Tools tab and Settings button on Wave 1 and 2 screens now open these boards.

Not drawn (simple list screens, specified in Task F): Settings › Finance, Lists, About; Change vault password.

## Build log

| Milestone | Date | Status | Notes |
|---|---|---|---|
| M0 · Project setup | 14 Oct 2026 | **Built; awaiting owner check on the phone** | `app/` Flutter project; all release checks pass; arm64 APK 18.7 MB; install file `dist/OZONE-0.1.0-build1-2026-10-14.apk` |

## Task F (build specification)

Spec files live in [spec/](spec/README.md). F1 · Data is approved (canvas board "Task F · F1 Data model"). F2 · Behaviour and F3 · Build are approved. **Task F is complete (14 Oct 2026).** PC setup done 14 Oct (Flutter 3.47.5 + Android Studio). Next: M0 · Project setup
(docs/spec/F3-04-build-order.md), started only on the owner's go-ahead.
Then F2 · Behaviour and F3 · Build, with a review after each.


## Task F (Flutter-ready specification, no app code)

Local storage and data model, workbook schema (sheets, columns, IDs, versioning), import and conflict rules,
locked-note encryption and key handling, search indexing, monthly derivation logic, reminders and platform limits,
the tool-registry architecture (so new tools can plug in), dependencies (well-known and pinned), tests and acceptance criteria.

## Brand files

Master SVGs, Android and iOS icon sources, and the brand sheet are in [../design/brand/](../design/brand/).
PNG exports are generated during Flutter setup.
