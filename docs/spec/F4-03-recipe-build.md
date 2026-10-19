# F4-03 · Recipe: packages, tests and build order

## 1. Packages (checked 19 Oct 2026, F3-02 §4 steps 1–3; steps 4–8 run when each is added)

| Package | Pin | Age | Publisher (verified) | Licence | Used for | Notes |
|---|---|---|---|---|---|---|
| google_mlkit_text_recognition | 0.17.1 | 63 d | flutter-ml.dev | MIT | Reading text (R-2) | Community plugin over Google's ML Kit SDK (free, closed source, Google's ML Kit terms). Needs Dart ≥ 3.12 and Flutter ≥ 3.44 (we have 3.13.4 / 3.47.5). |
| google_mlkit_commons | 0.13.0 | 63 d | flutter-ml.dev | MIT | Pulled in by the above | Flutter SDK only |
| image_picker | 1.2.3 | ~3 mo | flutter.dev | BSD-3 | Camera app and system photo picker (R-6) | 1.2.4 is 13 days old today, so not yet allowed. Added in M11 with two sub-packages pinned (below) |
| image_picker_ios | 0.8.13+9 | 19 d | flutter.dev | BSD-3 | Pulled in by image_picker | Pinned in M11: the resolver chose 0.8.13+12, 5 days old |
| image_picker_platform_interface | 2.11.1 | ~1 yr | flutter.dev | BSD-3 | Pulled in by image_picker | Pinned in M11: the resolver chose 2.11.2, 13 days old. Depends on `http`, already in the lockfile |
| archive | 3.6.1 (already in the lockfile through excel) | ~2 yr | loki3d.com | MIT | Writing and reading the backup `.zip` | Becomes a direct dependency at the same version, so nothing new is downloaded. excel 4.0.6 needs archive ^3.6.1, so archive 4.x isn't possible without replacing excel. |

**Not added:** a crop or edge-detection package (corners and the perspective transform use `dart:ui`, F4-02 §3); `image`
(every photo is turned into a 1,600 px JPEG by the existing files channel with the phone's own encoder:
`Bitmap.compress` on Android in `JpegConverter.kt` (M11), `UIImage.jpegData` on iOS when a Mac build happens). Fallback if that channel is refused in review:
`image` 4.3.0 (loki3d.com, MIT, the last version that works with archive 3.6.1).

**Things to verify when adding ML Kit (stop and report if any fails):**

1. **No network.** ML Kit's Android libraries merge `INTERNET` and `ACCESS_NETWORK_STATE` (through Google's data transport
   library, used for usage logging). Remove both with `tools:node="remove"` in the app manifest, and remove the transport
   services they add (`TransportBackendDiscovery`, `JobInfoSchedulerService`, `AlarmManagerSchedulerBroadcastReceiver`). The release
   check (F3-03 §3) must still find only the permissions in F2-03 §5. Then run a scan in airplane mode on the emulator.
2. **Bundled model.** The plugin must use `com.google.mlkit:text-recognition` (the model inside the APK), not the Play-services
   variant that downloads it. Check the merged dependencies (`gradlew app:dependencies`).
3. **Size.** Measure the arm64 APK. Budget is now **30 MB** (R-3); expected about 22.5 + 4–5 MB. Other scripts (Chinese,
   Japanese, Korean, Devanagari) are **not** included.
4. **iOS** (later, on a Mac): ML Kit needs iOS 15.5 or newer, so the deployment target rises from 15.0 to 15.5.
   `NSCameraUsageDescription`: "OZONE uses the camera to scan recipe pages and take recipe photos."
5. **image_picker** must not add `CAMERA` or any storage permission to the merged manifest (it uses the system photo picker on
   Android 13+, and the camera app through `ACTION_IMAGE_CAPTURE`).

**Licences shipped:** the plugins' licences are collected automatically. ML Kit's Android libraries aren't, so About › Licences
adds an entry "Google ML Kit" with a link-free note: "Text recognition by Google ML Kit, used under Google's ML Kit terms."

## 2. Tests (add to F3-03)

| Layer | Must cover |
|---|---|
| Unit | Amount parsing and formatting (every form in F4-02 §4.8 and §6); scaling (factor, fractions, ranges, g/ml rounding); key names (descriptors, synonyms, plurals); scan parser on **at least 12 text fixtures**: single column, two columns, Filipino headings, no headings, multi-page, sections, ranges, run-on steps, page numbers, "Serves 4", times, OCR typos flagged; What can I cook? grouping and order; zip entry rules (path safety, size limits, JPEG check) |
| Database | Recipe save replaces children in one transaction; tombstone and photo deletion after Undo; orphan sweep keeps photos younger than 10 min; search triggers for recipes, ingredients, steps; kitchen clear |
| Migration | v2 → v3 with the owner-shaped sample keeps every existing row and builds the recipe search rows |
| Round trip | Export `.zip` with recipes, photos and kitchen → import into an empty database: all Same, photos byte-identical. Import again: zero New, zero Changed. A `.xlsx` from 1.1.0 still imports. A zip with a missing photo, a `../` entry, an oversized entry and a non-JPEG photo gives the messages in F4-01 §6 |
| Widget | Recipes list, detail, form, scan check, What can I cook?, Home widget: light/dark, 200% text, semantics labels, Monochrome |
| Integration | Add a recipe with a photo → export → wipe → import → photo and recipe present. Scan flow with a fixture image fed to the recognizer (emulator) |

The perf test gains 1,000 recipes (8 ingredients and 6 steps each, 300 with photos) in the large sample.

## 3. Release check changes (app/tool/release_check.ps1)

- Size budget 25 → **30 MB** arm64 (R-3).
- Permission list unchanged (F2-03 §5): `INTERNET`, `ACCESS_NETWORK_STATE`, `CAMERA` and storage permissions fail the check.
- New: fail if the merged manifest contains the ML Kit transport services listed in §1.

## 4. Build order (version 1.2.0, branches `build/m11`… from `build/m10-ui`)

Each milestone ends with a signed APK, a "what to try" list, the emulator check, and the owner's approval (owner rule).

| # | Milestone | Builds | Done when |
|---|---|---|---|
| **M11** | Recipe core and backup | Schema v3 and migration; tool definition (olive, icon, routes, Tools launcher, bar tip); Recipes list, Recipe detail with scaling and ticks, New/Edit form with drag reorder and key names; photo via camera app or gallery (image_picker), orphan sweep; favourites, categories, Settings › Lists › Recipe categories; delete + Undo + tombstones; search entity; quick add "Add recipe"; workbook sheets; `.zip` export and import with photos (archive), safety `.zip`, first-run restore from `.zip` | A recipe with a photo survives export → wipe → import on the emulator; 1.1.0 workbooks still import |
| **M12** | Scanning | ML Kit (with the §1 checks); Scan a page board (corners, rotate, up to 4 pages); straightening; Read text with progress; scan parser and fixtures; Check what was read; From a photo with "Use as the recipe's photo"; quick add "Scan a recipe"; cache clean-up; release check at 30 MB | A printed page scanned in airplane mode fills the form; no `INTERNET` in the merged manifest; APK ≤ 30 MB |
| **M13** | What can I cook? and widget | Kitchen table and screen; staples setting and Settings › Tools › Recipe; grouping; list card count; Home widget `recipe_cook` with empty state; Settings › Dashboard entry | Ticking ingredients updates the groups and the Home widget at once |
| **M14** | Finish | States, accessibility pass (TalkBack, 200%, contrast with olive), performance with the 1,000-recipe sample on the A03-sized emulator, motion (UR3-1 moments on the new screens), About › Licences entry, docs/07 acceptance items for Recipe | Release check passes; owner ticks the Recipe acceptance items |
| *Later* | Recipe 2 · Nutrition (R-11) | Specified separately after 1.2.0 ships | — |

## 5. Acceptance (add to F3-03 §4)

| Area | Accept when |
|---|---|
| Recipe | A typed recipe saves and reopens with the same ingredients, sections and steps; scaling 4 → 6 shows `¾ cup` for `½ cup`; delete + Undo restores it; search finds it by an ingredient |
| Scanning | A clean printed page gives the right title and every ingredient and step after at most 3 corrections on the check screen; a scanned page leaves no file behind; works in airplane mode |
| What can I cook? | Groups follow F4-02 §5 with staples counted; the Home widget matches the screen |
| Backup | The `.zip` round trip keeps every photo; a damaged zip changes nothing and says why |

## Decisions (owner, 19 Oct 2026)

1. **F4-Q4** Ships as 1.2.0, one build per milestone (builds 15–18) (rec.).
2. **F4-Q5** `build/m11` starts from `build/m10-ui` (rec.).

<!-- Questions as asked: -->

- **F4-Q4** Version: ship the Recipe tool as **1.2.0** (rec.), with one build per milestone (builds 15–18)?
- **F4-Q5** Branches: start `build/m11` from `build/m10-ui` (rec.; it has everything in 1.1.0 plus the README commits).
