# F3-02 · Packages and supply-chain safety

Checked on **14 Oct 2026**. "Age" is relative to that date. Every pinned version is at least 14 days old (owner rule).
Versions are pinned **exactly** (no `^`) in `pubspec.yaml`, and `pubspec.lock` is committed.

## 1. Runtime packages

| Package | Pin | Age | Publisher (verified) | Licence | Used for |
|---|---|---|---|---|---|
| drift | 2.35.0 | 34 d | simonbinder.eu | MIT | Database, migrations, FTS5 |
| drift_flutter | 0.3.1 | ~3 mo | simonbinder.eu | MIT | Opens SQLite on Android/iOS |
| flutter_riverpod | 3.4.3 | 40 d | dash-overflow.net | MIT | App state |
| go_router | 18.0.2 | 15 d | flutter.dev | BSD-3 | Navigation |
| cryptography | 2.9.0 | ~10 mo | dint.dev | Apache-2.0 | Argon2id, AES-256-GCM |
| local_auth | 3.0.2 | ~3 mo | flutter.dev | BSD-3 | App lock, vault biometrics |
| flutter_secure_storage | 11.2.0 | 27 d | steenbakker.dev | BSD-3 | Biometric copy of the vault key |
| flutter_local_notifications | 22.3.1 | 31 d | dexterx.dev | BSD-3 | Month-end reminder |
| timezone | 0.11.1 | ~3 mo | labs.dart.dev | BSD-2 | Required by notifications scheduling |
| flutter_quill | 11.6.0 | 28 d | bulletjournal.us | MIT | Note editor (Delta JSON) |
| excel | 4.0.6 | ~2 yr | justkawal.dev | MIT | `.xlsx` read/write, behind `WorkbookCodec` |
| file_selector | 1.1.0 | ~10 mo | flutter.dev | BSD-3 | Import: pick a `.xlsx` |
| share_plus | 13.3.0 | ~2 mo | fluttercommunity.dev | BSD-3 | "Share or save a copy" |
| path_provider | 2.1.6 | ~4 mo | flutter.dev | BSD-3 | App folders |
| intl | 0.20.3 | ~3 mo | dart.dev | BSD-3 | Date and number formatting (en_PH) |

## 2. Development-only packages (never shipped)

| Package | Pin | Age | Publisher | Licence |
|---|---|---|---|---|
| drift_dev | 2.35.0 | 34 d | simonbinder.eu | MIT |
| build_runner | 2.16.1 | 41 d | tools.dart.dev | BSD-3 |
| analyzer | 14.4.0 | 32 d | tools.dart.dev | BSD-3 | (pinned 14 Oct: the resolver had picked 14.5.0, which was 7 days old and breaks build_runner 2.16.1) |
| flutter_lints | 6.0.0 | 16 mo | flutter.dev | BSD-3 |
| flutter_test, integration_test | from the Flutter SDK | — | flutter.dev | BSD-3 |

## 3. Removed or not used, and why

| Instead of | We use | Reason |
|---|---|---|
| file_picker | file_selector (open) + our own ~60-line "Save to" channel | file_picker recently moved to a new owner (credited in its README). It's a legitimate handover, but a supply-chain risk for a package that touches files. The Flutter team's file_selector can't "save" on phones, so that small part is ours. |
| A chart package | `CustomPaint` | Small needs; full control of accessibility |
| An icon package | Built-in Material rounded icons | No extra dependency |
| uuid | `Random.secure()` (F1-01) | 10 lines of code |
| syncfusion xlsio | — | Commercial licence terms |
| Any analytics, crash or ads SDK | — | Offline, private app; no network permission (F2-03) |

## 4. Safety procedure (every add or update)

1. **Publisher:** verified on pub.dev. Check that the repository link matches and that ownership hasn't changed recently
   (read the README and changelog). An ownership change → stop and ask the owner.
2. **Licence:** MIT, BSD, Apache-2.0 or similar permissive. No GPL/AGPL in shipped code.
3. **Age:** the version is at least 14 days old. Prefer the newest version that meets that.
4. **Read the changelog** from the current version to the new one. Look for new permissions, network calls or native code.
5. **No network:** `dart pub deps` → no new package that makes network calls. The release-manifest check (no `INTERNET`) must pass.
6. **Build-time code:** some packages run code during the build (build hooks / native assets, for example sqlite3).
   Check what they do. For `sqlite3`, confirm it builds the bundled SQLite source, or that any downloaded binary is
   checksum-verified, before the first release (M0 task).
7. **Vulnerabilities:** run `osv-scanner --lockfile=pubspec.lock` (Google's open-source scanner) and fix or justify every finding.
8. **Lockfile:** `flutter pub get --enforce-lockfile` in every build, so nothing changes silently.
9. Record the change in this table, with the date.

Dart and Flutter packages have no install scripts like npm. Steps 5–6 cover the code that does run at build time.

## 5. Licences shipped

Settings › About › Licences uses Flutter's built-in licence page, which collects every package's licence automatically.
Manrope's SIL OFL 1.1 text is registered with `LicenseRegistry` because fonts aren't collected automatically.

## 6. Toolchain (installed 14 Oct 2026)

| Tool | Version | Where | Notes |
|---|---|---|---|
| Flutter SDK | **3.47.5** stable (18 Sep 2026), Dart 3.13.4 | `C:/dev/flutter` | Official zip, SHA-256 verified; analytics off. The newest release at least 14 days old on install day |
| Android Studio | 2026.2.1.8 (winget `Google.AndroidStudio`, installer hash verified) | default | Bundled JDK; Android SDK 36, platform android-37; licences accepted |
| Git | 2.56 | already installed | |
| Android NDK | 28.2.13676358 | Android SDK | Required by the SQLite build hook; from Google's SDK repository |
| osv-scanner | 2.6.0 (winget `Google.OSVScanner`, 14 Sep 2026) | user PATH | Vulnerability scan in the release check |
| desugar_jdk_libs | 2.1.4 (Google) | Gradle | Required by flutter_local_notifications |

Desktop and web targets are switched off (`flutter config`), so only Android and iOS are built.
Android `minSdk 26`, `targetSdk` = the current Play requirement. iOS deployment target 15.0.
**iOS builds need a Mac with Xcode.** This PC builds Android only. The code stays iOS-ready, and an iOS build is only possible
later on a Mac.
