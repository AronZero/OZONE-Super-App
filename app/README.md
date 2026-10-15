# OZONE app (Flutter)

The OZONE app itself. What to build and why is in [../docs/spec/](../docs/spec/README.md). Read that first.

## Toolchain (pinned)

| Tool | Version | Notes |
|---|---|---|
| Flutter | 3.47.5 stable (Dart 3.13.4) | Installed at `C:\dev\flutter`; analytics off |
| Android SDK | platform 36/37, build-tools 36.0.0 | Through Android Studio 2026.2 |
| Android NDK | 28.2.13676358 | Needed by the SQLite build hook |
| JDK | Android Studio's bundled JBR | |
| osv-scanner | 2.6.0 | Vulnerability scan of `pubspec.lock` |
| analyzer (dev only) | 14.4.0 | Pinned so `build_runner` 2.16.1 works; see F3-02 |

Packages are pinned exactly in `pubspec.yaml`, and `pubspec.lock` is committed. Before changing any package, follow the
safety procedure in `docs/spec/F3-02-packages.md` §4.

## Everyday commands

```powershell
flutter pub get --enforce-lockfile   # install the exact locked packages
flutter analyze                      # must be clean
flutter test                         # unit and widget tests
dart run build_runner build --delete-conflicting-outputs   # regenerate drift code after changing tables
flutter run                          # run on a connected phone (USB debugging) for development
powershell -ExecutionPolicy Bypass -File tool\release_check.ps1   # all release checks + APK in ..\dist\
```

## Release signing

The release key is **outside the repository**: `%USERPROFILE%\.ozone-keys\` (`ozone-release.jks` + `key.properties`).
`android/app/build.gradle.kts` reads it from there, and a release build fails if it's missing, so a debug-signed APK can
never be shipped by mistake. Losing the key means future versions can't install over the current app: keep two backups.

## Installing on the phone

Copy `dist\OZONE-<version>-<date>.apk` to the phone (USB cable, Google Drive, …), open it in the file manager, and allow
"install unknown apps" for that file manager when Android asks. Updates install over the old version and keep the data,
as long as they're signed with the same key.

## Project notes

- `android/gradle.properties` sets `kotlin.incremental=false`, because the project (D:) and the pub cache (C:) are on
  different drives, which breaks Kotlin's incremental caches.
- Core library desugaring is on (`desugar_jdk_libs` 2.1.4) because flutter_local_notifications requires it.
- `VIBRATE` is removed from the merged manifest. Allowed permissions are listed in `docs/spec/F2-03-platform.md` §5,
  and the release check enforces them.
- Phone backups are off (`allowBackup=false`, `data_extraction_rules.xml`).
- Icons are Android vector drawables made from `design/brand/android/*.svg`. iOS icons are made when an iOS build is
  possible (that needs a Mac).
- Folder layout and the tool registry are described in `docs/spec/F3-01-architecture.md`.
- Database: `lib/core/data/tables.dart` (schema v1, every F1-01 table) and `database.dart` (opens `ozone.db`; creates the
  FTS5 `search_index`). A schema change needs a new `schemaVersion`, a migration step and a migration test.
- `MainActivity.kt` has a small `ozone/platform` channel: `setSecure` (FLAG_SECURE for app lock) and `openSecuritySettings`.
- Widget tests use an in-memory database (`test/helpers/harness.dart`). Close it with `closeApp()`, which closes the
  database inside the test clock. `tester.runAsync(db.close)` hangs.
- Emulator for PC testing: AVD `OZONE_A03_API33` (Android 13, 720 × 1600, 3 GB), test PIN 1234.
- Tools plug in through `ToolDefinition` (`lib/shell/tool_registry.dart`): `routes` (screens that hide the bar use the
  root navigator key), `widgets` (Home dashboard content by widget ID) and `attention` (Needs attention lines).
- "Today" comes from `todayProvider` (`lib/core/state/today.dart`), refreshed at midnight and on resume. Widget tests
  pin it with `FixedToday` (the harness uses 13 Oct 2026, the date on the W1 boards).
- Screenshots of the emulator come out blank while app lock is on (`FLAG_SECURE`, by design). Turn the lock off in
  Settings › Security for screenshots and back on afterwards.
- Edit source files with the editor tools or Git Bash `sed`, not PowerShell 5.1 `Get-Content`/`Set-Content`: they read
  UTF-8 as ANSI and write a BOM, which garbles `’`, `·` and `§` in strings.
- Repositories watch screens' tables with `watchTables` (`lib/core/data/watch.dart`), which listens to drift's table
  updates. A stream query over `SELECT 1` can skip a refresh when its result looks the same.

- Search (M7): `core/search/`. The FTS5 index is kept in step by SQLite triggers (schema v2, `search_keys`); a new
  indexed table needs a source in `search_index.dart`, a schema bump and a migration step that rebuilds the index.
- Hide amounts (M7): display screens format money with `money(context, …)` (`core/ui/amounts.dart`), never
  `Money.format` directly; forms where amounts are typed keep `Money.format`.
- Workbook (M8): `core/workbook/` (cells, xlsx codec over `excel`, export builder, import planner, backup service).
  Don't put a per-cell style on text cells: it made exports 4× slower.
- `FilesChannel.kt` is the "Save to" dialog (`ACTION_CREATE_DOCUMENT`, starts in Download, no storage permission).
- System screens OZONE opens itself (Save to, file picker, share sheet, permission prompt) must run inside
  `ExternalActivity.run`, or app lock and the vault relock when they pause the app.
- `res/raw/keep.xml` keeps resources used only by name (the reminder's `ic_stat_ozone`); release resource shrinking
  removes them otherwise. Optional platform set-up (reminders) must never throw before `runApp`.
- Widget tests: `testVault(db, fastKdf: true)` (cryptography's Argon2 isolates time out under fake time);
  `pumpApp(overrides: …)` swaps the file picker (`pickWorkbookProvider`) and Save to (`saveAsProvider`).
