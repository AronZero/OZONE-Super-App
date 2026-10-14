# OZONE build specification (Task F)

The specification for building OZONE in Flutter. It is written so that Claude Code can build the app milestone by milestone,
and so that a Flutter developer can read and maintain it without AI help.

Product rules come from [../02-requirements-baseline.md](../02-requirements-baseline.md), [../03-decision-log.md](../03-decision-log.md),
[../04-ux-architecture.md](../04-ux-architecture.md) and [../05-design-system.md](../05-design-system.md).
Screens are on the design canvas (see [../06-design-progress.md](../06-design-progress.md)). If this spec and those documents disagree,
stop and ask the owner. Don't guess.

## Parts and status

| Part | File | Status |
|---|---|---|
| F1 · Data | [F1-01-data-model.md](F1-01-data-model.md): database tables and field rules | Approved 14 Oct 2026 |
| | [F1-02-workbook.md](F1-02-workbook.md): the `.xlsx` format | Approved 14 Oct 2026 |
| | [F1-03-import-export.md](F1-03-import-export.md): export, import, restore, conflicts | Approved 14 Oct 2026 |
| | [F1-04-calculations.md](F1-04-calculations.md): money, monthly history, totals, reports | Approved 14 Oct 2026 |
| F2 · Behaviour | [F2-01-security.md](F2-01-security.md): notes vault, app lock, privacy | Approved 14 Oct 2026 |
| | [F2-02-search-notes.md](F2-02-search-notes.md): search index, editor, autosave, trash, Undo | Approved 14 Oct 2026 |
| | [F2-03-platform.md](F2-03-platform.md): files, reminders, permissions, accessibility, performance | Approved 14 Oct 2026 |
| F3 · Build | [F3-01-architecture.md](F3-01-architecture.md): layers, folders, tool registry, theme | Approved 14 Oct 2026 |
| | [F3-02-packages.md](F3-02-packages.md): exact versions and the safety procedure | Approved 14 Oct 2026 |
| | [F3-03-tests.md](F3-03-tests.md): tests, release checks, acceptance criteria | Approved 14 Oct 2026 |
| | [F3-04-build-order.md](F3-04-build-order.md): milestones M0–M9 | Approved 14 Oct 2026 |

## Conventions used in every part

- **Must** is required. **Should** is the default unless there is a written reason not to. "(Owner)" marks an owner decision.
- Code names are `snake_case` for database columns and `camelCase` for Dart. Screen names match the canvas board titles.
- Sizes and limits are given as numbers, never "small" or "large".
- Each part ends with **Open questions**. They are resolved before that part is marked approved.

## Technical stack

The full list with exact versions, publishers, licences and the safety procedure is in [F3-02-packages.md](F3-02-packages.md).
Summary: drift (SQLite + FTS5), Riverpod, go_router, cryptography (Argon2id + AES-GCM), local_auth, flutter_secure_storage,
flutter_local_notifications, flutter_quill, excel (behind `WorkbookCodec`), file_selector + a small own "Save to" channel,
share_plus. There is no network access, no analytics and no ads.

## Target devices

- Android 8.0 (API 26) and newer; iOS 15 and newer.
- **Reference phone:** Samsung Galaxy A03 on Android 13 (the owner's daily phone). It is an entry-level phone, so every
  performance budget in this spec is measured on it, or on an emulator limited to 3 GB RAM if the phone isn't available.
