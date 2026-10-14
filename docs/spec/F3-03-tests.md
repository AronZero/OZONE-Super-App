# F3-03 · Tests and acceptance criteria

A milestone is done only when its tests pass, its acceptance checks pass on the reference phone, and the owner approves.

## 1. Test layers

| Layer | Tool | What | Must cover |
|---|---|---|---|
| Unit | `flutter test` | Pure Dart domain code | Every rule and worked example in F1-04; money parsing and formatting; validation; workbook cell conversion (F1-02 §3); import classification (F1-03 table); search query parsing; recovery-code format |
| Database | `flutter test` with in-memory drift | Repositories | Unique rules; one update per account per date; tombstones; search index kept in step; trash purge; transactions roll back on failure |
| Migration | drift's schema tests | Every schema version | Opening a database saved by each older version keeps all data |
| Crypto | `flutter test` | Vault service | Known-answer tests for Argon2id and AES-GCM; wrong password fails; changing the password keeps notes readable; the recovery code works once; a tampered cipher is rejected; the note ID is bound as associated data |
| Round-trip | `flutter test` | Export → import | Export a sample database, import into an empty one: every row is **Same**. Import it again into the original: zero New, zero Changed |
| Widget + golden | `flutter test` | Components and key screens | Light and dark goldens per Components board item; 200% text without overflow; semantics labels present |
| Integration | `integration_test` on the reference phone or an emulator | Main flows F1–F10 (docs/04) | First run → add account → update balances → export → reset app → restore → same totals |

Coverage target: domain and data at least 90% of lines; UI is covered by goldens and integration tests rather than a number.

## 2. Sample data

`test/fixtures/sample_workbook.xlsx` is built by a script from the canvas's sample data (clearly labelled), plus a
generated large set (10,000 rows, 500 notes) for performance checks. It is never shipped in the app.

## 3. Release checks (a script run before every build given to the owner)

1. `flutter analyze` with zero warnings.
2. All tests pass.
3. The merged Android manifest has no `INTERNET` permission and only the permissions in F2-03 §5.
4. `osv-scanner` on `pubspec.lock`: no unresolved findings.
5. Secret scan: no keys, tokens or `.env` files committed. The signing keystore lives outside the repo.
6. App size under 25 MB (arm64).
7. Performance budgets (F2-03 §8), measured on the reference phone with the large sample set.

## 4. Acceptance criteria per area (checked on the phone)

| Area | Accept when |
|---|---|
| Shell | The bar matches the settings; each tab keeps its own back stack; tapping the active tab returns to its top; Edit bar changes show at once |
| Savings | The W1 worked example reproduces exactly (Carried, Not counted, totals); "Unchanged" makes a month Recorded; "needs a balance" follows F1-04 decisions |
| Gold | Values match grams × price with one rounding per item; items without a price are named; stale after 30 days |
| Expenses | Refunded items are excluded from every total but listed struck through; this year vs the same period last year is correct across 29 Feb |
| Library | The Purchased amount rule; ratings 0–5 in halves with "Not rated" distinct from 0; storage units 1,024-based |
| Notes | Autosave after 1 s; crash recovery banner; trash purge after 30 days; folders delete safely; tags merge |
| Vault | Setup → lock → relock on background → unlock with password and biometrics; forgot flow issues a new code; reset deletes only locked notes |
| App lock | Uses the phone password; relock after the chosen delay; blank recents preview on Android |
| Search | Prefix and accent-insensitive; exact amounts; never shows locked or trashed notes; under 100 ms |
| Backup | Export opens "Save to"; the file opens in Excel and Google Sheets; import preview counts are correct; a safety export exists; nothing is deleted |
| Reminders | The month-end notification arrives (within a few minutes) after a reboot too; permission asked once, at first run |
| Accessibility | TalkBack reads amounts in pesos and centavos; every control is labelled; 200% text works; contrast passes in both themes |
