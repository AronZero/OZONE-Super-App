<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="design/brand/ozone-mark-dark.svg">
    <img src="design/brand/ozone-mark.svg" alt="OZONE logo" width="112">
  </picture>
</p>

<h1 align="center">OZONE</h1>

<p align="center">
  <b>Money, books and notes, bonded in one app.</b><br>
  A personal, private, offline-only Android app. No account, no cloud, no internet permission.
</p>

<p align="center">
  <a href="../../releases/latest">Download the APK</a> ·
  <a href="#features">Features</a> ·
  <a href="#privacy">Privacy</a> ·
  <a href="#build-it-yourself">Build it yourself</a>
</p>

<p align="center">
  <img src="docs/screenshots/home-light.png" alt="Home dashboard" width="220">
  <img src="docs/screenshots/finance-savings.png" alt="Finance: savings" width="220">
  <img src="docs/screenshots/library.png" alt="Library" width="220">
  <img src="docs/screenshots/notes.png" alt="Notes" width="220">
</p>

<p align="center"><sub>All screenshots use made-up sample data.</sub></p>

## What it is

Ozone (O₃) is three oxygen atoms bonded into one molecule. OZONE bonds three everyday tools into one calm app:

- **Finance** tracks savings, gold and expenses.
- **Library** keeps your books and your reading.
- **Notes** holds checklists and notes, with a locked vault for the private ones.

Everything stays on your phone. Backups are ordinary `.xlsx` workbooks that you export yourself and can open in any
spreadsheet app.

## Features

### Finance

<p>
  <img src="docs/screenshots/finance-gold.png" alt="Gold holdings" width="200" align="right">
</p>

- **Savings:** accounts with month-end balances, a 12-month trend, change versus last month, and a History report
  across five years. Update all balances at once in a single step.
- **Gold:** items by karat and weight, today's estimated value from your own karat prices, and gain against cost.
- **Expenses:** this year so far against the same period last year, filters by vendor, amount and refunds, and a
  yearly report.
- **Month-end reminder:** one optional notification a month. It never shows amounts.

<br clear="right">

### Library

- Books with author, status (reading, not started, finished, abandoned), half-star ratings, Kindle size and how you
  got the book.
- Stats: Kindle storage, books finished per year, average rating and spending on books.

### Notes

- Folders, tags, pinned notes, checklists and simple formatting. Notes save themselves as you type.
- **Locked notes:** a vault protected by your password (Argon2id + AES-256-GCM), with an optional fingerprint unlock
  and a recovery code.
- Trash keeps deleted notes for 30 days.

### Across the app

<p>
  <img src="docs/screenshots/home-dark.png" alt="Home in dark mode" width="200">
  <img src="docs/screenshots/home-monochrome.png" alt="Home in Monochrome" width="200">
  <img src="docs/screenshots/finance-monochrome.png" alt="Finance in Monochrome" width="200">
</p>

- **Home dashboard** with widgets you can show, hide and reorder, plus a "Needs attention" line.
- **Search** across every tool, including exact amounts.
- **Hide amounts** with one tap; every ₱ figure becomes `₱ ••••`.
- **Light, dark and Monochrome** themes. Monochrome keeps only green and red for gains, losses and warnings.
- **Floating bottom bar** with your three favourite tools, and gentle motion that switches off with the phone's
  Reduce motion setting.
- **App lock** with the phone's own screen lock. Screenshots are blocked while the vault is open.
- **Accessibility:** 48 dp touch targets, text up to 200 %, and TalkBack reads amounts in words.

## Privacy

- **No internet permission.** OZONE cannot send anything anywhere.
- **No account, no analytics, no ads.**
- **Your data lives in the app's private storage** and is excluded from cloud backups.
- **You own the backups:** export a workbook whenever you like. Importing shows a preview of every change first, and a
  safety copy is kept before anything is replaced.

## Download

Get the latest signed APK from [Releases](../../releases/latest) and install it on Android 8.0 or newer. You may
need to allow installs from your browser or file manager. The app is built and tested for Android first; iOS is kept
ready in the code but not released.

## Build it yourself

You need Flutter 3.47.5 (Dart 3.13.4) and the Android SDK; the exact toolchain is listed in
[app/README.md](app/README.md).

```powershell
cd app
flutter pub get --enforce-lockfile
flutter test
flutter run            # on a phone with USB debugging
```

Release builds are signed with a key that is not in this repository. Use your own key, as described in
[app/README.md](app/README.md#release-signing).

## Built with

Flutter · Riverpod · go_router · drift (SQLite with FTS5 search) · flutter_quill · cryptography · excel. Every
package is pinned to an exact version and checked with osv-scanner before each release.

## How it was made

OZONE was designed and specified before any code was written, then built in ten reviewed milestones. The documents are
all here:

| Where | What |
|---|---|
| [docs/02-requirements-baseline.md](docs/02-requirements-baseline.md) | Requirements |
| [docs/03-decision-log.md](docs/03-decision-log.md) | Every decision, with its reason |
| [docs/04-ux-architecture.md](docs/04-ux-architecture.md), [docs/05-design-system.md](docs/05-design-system.md) | UX rules and design tokens |
| [docs/spec/](docs/spec/README.md) | The build specification: data, behaviour, architecture, tests, build order |
| [docs/06-design-progress.md](docs/06-design-progress.md) | Build log |
| [design/brand/](design/brand/README.md) | Logo and brand rules |

## Licence

The code is released under the [MIT Licence](LICENSE). The OZONE name and logo are not covered by it; please don't
use them for your own apps. Bundled fonts keep their own licences: Manrope (SIL Open Font Licence 1.1) and Material
Symbols Rounded (Apache-2.0).
