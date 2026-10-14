# F3-04 · Build order

Ten milestones. Each one ends with an APK the owner installs on the reference phone, a short "what to try" list, and the
owner's approval before the next starts (owner working rule). Within a milestone, work in small commits with tests.
Commit or push only when the owner asks.

Distribution is personal (owner, 14 Oct 2026): a signed release `.apk` file is built on the PC, copied to the phone (USB cable,
Google Drive or similar) and installed by hand, now or later. USB debugging is optional, used only for faster testing. The Play Store and App Store are out of
scope until the owner decides otherwise (and the open "OZONE" trademark search in docs/03 would come first).

| # | Milestone | Builds | Done when |
|---|---|---|---|
| **M0** | Project setup | Flutter project `ozone` (Android + iOS); folder layout (F3-01 §2); pinned packages (F3-02); lints; theme tokens and bundled Manrope; app icon from `design/brand/android` and `ios`; release-check script (F3-03 §3); backup off; no `INTERNET`; sqlite3 build-hook check; FTS5 self-test | App opens to an empty neutral shell in light and dark; the release checks pass |
| **M1** | Core and shell | drift database v1 with all F1-01 tables; settings, deletions and Undo framework; money/date/ID domain; tool registry; bottom bar with per-tab stacks; Home skeleton; Settings menu, Appearance, Home dashboard arrange, Tools launcher, Edit bar; App lock (phone password, relock delay, secure screen) | The Wave 3 shell boards work on the phone; app lock relocks after 1 minute |
| **M2** | Savings | Accounts, Update balances (with Unchanged), Account detail (by month, all updates, chart), History report, Archived accounts, Needs attention (balances), Total savings and Savings trend widgets (decision M2-3), monthly logic | The F1-04 worked example matches on the phone; all Savings unit tests pass |
| **M3** | Gold and Expenses | Gold overview, items, Karat prices and history, disposed; Expenses list, filters, Add expense sheet (save & add another, duplicate warning), Expense detail with Refunded, Spending by year, Settings › Lists, Gold/Spending/Recent expenses widgets (decision M3-4) | Totals match F1-04; refunded rules hold everywhere |
| **M4** | Library | Library list, filters and sort, Add/Edit book, Book detail, Library stats | Every Library acceptance item in F3-03 §4 passes |
| **M5** | Notes | Notes home (grid/list, folders, tags, pinned), editor (flutter_quill toolbar), autosave and drafts, note menu, Folders & tags, Trash with purge | Typing never loses text, including after a forced stop |
| **M6** | Notes vault | Vault setup with recovery code, lock/unlock, relock on background, biometrics where available, change password, new code, Forgot password, Vault reset, `FLAG_SECURE` | All crypto tests pass; unlock takes about 1 s on the A03 |
| **M7** | Search and dashboard | FTS5 index and triggers, Global search (grouping, recent, footer), deep links; all 10 dashboard widgets; quick-add menu; Hide amounts | Search budgets met; widgets follow the arrange settings |
| **M8** | Backup and first run | Workbook codec; export with progress and "Save to"; import preview (New/Changed/Same/Check), safety export, apply; Welcome with Start fresh / Restore; "Get a month-end reminder?" screen; month-end notification | Round-trip test passes; a restore onto a wiped phone gives identical totals |
| **M9** | Finish | States board everywhere (empty, error, confirmation, skeleton); accessibility pass (TalkBack, 200% text, contrast); performance on the A03 with the large sample; About page with licences; final release checks | Every acceptance item in F3-03 §4 is checked off by the owner |

## Before M0 (owner setup, once)

- On the Windows PC: install the Flutter SDK and Android Studio (with the Android SDK). Claude Code can walk through this.
- On the phone: allow installing apps from your file manager (Android asks the first time you open the `.apk`).
  USB debugging is optional.
- Create the release signing key, kept **outside** the repository and backed up by the owner.

## Rules for every milestone

- Follow the spec. If something is missing or wrong in it, stop and ask; update the spec and docs/03 when the owner decides.
- Each screen matches its canvas board (layout, copy, states, both themes). Sample data in the boards is never shipped.
- Run the release checks (F3-03 §3) before handing over an APK.
- Run the security pass after each milestone: package audit (F3-02 §4), secret scan, permissions check.
- Update `docs/06-design-progress.md`, renamed to a build log at M0, with what was built and what the owner approved.
