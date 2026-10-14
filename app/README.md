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

Packages are pinned exactly in `pubspec.yaml`, and `pubspec.lock` is committed. Before changing any package, follow the
safety procedure in `docs/spec/F3-02-packages.md` §4.

## Everyday commands

```powershell
flutter pub get --enforce-lockfile   # install the exact locked packages
flutter analyze                      # must be clean
flutter test                         # unit and widget tests
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
