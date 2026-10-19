# F2-03 · Platform: files, reminders, permissions, accessibility, performance

## 1. No network

OZONE has no network features. The Android release manifest must **not** request `INTERNET` (Flutter adds it in debug only),
and no package may make network calls. A release-build check fails if `INTERNET` appears in the merged manifest (F3).
Fonts (Manrope) are bundled, not downloaded.

## 2. Files

| Action | Android | iOS |
|---|---|---|
| **Export** | Build the file in app storage, then open the system "Save to" dialog (Storage Access Framework, `ACTION_CREATE_DOCUMENT`) with the suggested name, starting in Downloads. Then show W3 · Export done with **Share or save a copy…** | Build the file, then open the Files "Save to" sheet |
| **Share a copy** | Share sheet with the `.xlsx` | Share sheet |
| **Import / Restore** | System file picker limited to `.xlsx` (`ACTION_OPEN_DOCUMENT`). The file is read once into memory and never kept. | Files picker, same rule |
| **Safety exports** | App-private files folder (not visible to other apps); newest 3 kept | App support folder |

No storage permission is requested on either platform. Proposed packages: `file_picker` (pick and save) and `share_plus`
(share). F3 completes their safety check; file_picker's verified publisher has changed, so F3 must review it or replace it.

## 3. Backups by the phone

- Android: `android:allowBackup="false"` and empty backup rules (`fullBackupContent`, `dataExtractionRules`), so neither Google
  backup nor device-to-device transfer copies the database or keys (owner decision Q11, and required by flutter_secure_storage).
- iOS: set "exclude from backup" on the database file, drafts and safety exports.
- The workbook export is the only backup (F1-03).

## 4. Reminders

| Reminder | How it shows |
|---|---|
| **Month-end balances** (default on, 8:00 pm on the last day of each month) | A local notification: "Update your savings balances for October". Tapping it opens Update balances (behind the App lock gate if on). |
| **Backup overdue** | **In the app only** (Needs attention on Home, and Data & backup). No notification. |
| **Stale gold prices** | In the app only. |

Scheduling rules (`flutter_local_notifications`):

- Keep **one** pending notification: the next month-end. Re-schedule on every app start, after a settings change,
  after a reboot (`RECEIVE_BOOT_COMPLETED`), and when the time zone or clock changes. This stays far under the iOS limit of
  64 pending notifications and Samsung's limit of 500 alarms.
- Use **inexact** scheduling (`inexactAllowWhileIdle`). It may arrive a few minutes late, but it needs no exact-alarm
  permission and no extra Play Store review.
- Ask for notification permission (Android 13+ `POST_NOTIFICATIONS`, iOS alert permission) at the **first moment it matters**:
  when Welcome finishes, as a short screen "Get a month-end reminder?", or when the user turns the reminder on. Never on
  launch. If it's denied, Settings › Finance shows "Notifications are off for OZONE" with **Open settings**.
- Samsung battery optimisation can delay alarms. If the reminder was missed (the app opens after month-end with no update
  that month), Needs attention covers it, so nothing depends on the notification arriving.

## 5. Permissions (complete list)

| Permission | Platform | Why |
|---|---|---|
| `USE_BIOMETRIC` | Android | App lock and vault biometric unlock |
| `USE_FINGERPRINT` | Android 8.0–8.1 | The same, on older Android (added by local_auth) |
| `<app id>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | Android | Internal AndroidX permission that only OZONE itself holds; harmless |
| `POST_NOTIFICATIONS` | Android 13+ | Month-end reminder |
| `RECEIVE_BOOT_COMPLETED` | Android | Re-schedule the reminder after restart |
| `NSFaceIDUsageDescription` | iOS | "OZONE uses Face ID to unlock the app and your locked notes." |

Anything else is a build failure (F3 check). `VIBRATE`, which flutter_local_notifications adds, is removed in the manifest.

## 6. App lifecycle

| Event | Actions |
|---|---|
| Start | Open the database → run migrations if needed → purge trash older than 30 days → re-schedule the reminder → App lock gate if on → Home (or Welcome on first run) |
| Background | Save the note being edited → relock the vault → start the app-lock timer → commit any pending Undo deletes |
| Foreground | App lock check → refresh "today" → purge trash → refresh Needs attention |

## 7. Accessibility (WCAG 2.2 AA, docs/04)

- Every control has a TalkBack/VoiceOver label. Amounts are read as "1,234 pesos and 56 centavos"; hidden amounts as
  "amount hidden"; ratings as "3.5 out of 5"; changes as "up 18,420 pesos".
- Text scales to 200% without clipping. Rows grow and wrap; the bar labels may drop to icons-only, but keep their labels for
  screen readers.
- Touch targets are at least 48 dp. Focus order follows the visual order. Reduce motion turns off all animation.
- Every chart has a "View as table" option.
- Contrast is checked for both themes in widget tests (F3).

## 8. Performance budgets (reference phone: Galaxy A03, Android 13)

| Measure | Budget |
|---|---|
| Cold start to Home with sample data (10,000 rows, 500 notes) | under 2.5 s |
| Opening any main screen | under 300 ms; skeleton only after 300 ms (docs/04) |
| Scrolling lists | 60 fps target, no frame over 32 ms in profile mode |
| Search query | under 100 ms |
| Vault unlock (Argon2id) | about 1 s, never over 2 s |
| Export / import of 10,000 rows | under 10 s / 8 s (F1-03) |
| App download size (Android, arm64) | under 25 MB; 36 MB from 1.2.0 with the OCR model (R-3) |

Heavy work (export, import, Argon2id, index rebuild) runs in background isolates. The UI thread never waits on it.

## Decisions (owner, 14 Oct 2026)

1. Add a one-time first-run screen after Welcome: **"Get a month-end reminder?"** with **Turn on** (asks for notification
   permission) and **Not now**. Its canvas board is "W3 · Reminder ask (first run)".
