# F2-01 · Security: notes vault, app lock, privacy

Screens: W1 · Vault unlock, Vault setup 1/2 and 2/2; W3 · Security, App lock gate, Forgot vault password, Vault reset.

## 1. Threat model (what this protects against)

| Protects against | Does not protect against |
|---|---|
| Someone holding the unlocked phone opening locked notes | Malware with root access on the phone |
| Someone reading an exported workbook (locked notes stay encrypted) | Someone who knows the vault password or recovery code |
| Someone casually opening OZONE (app lock) | Finance, Library and unlocked notes in an export (not encrypted, by owner decision) |
| Locked notes leaking into search, screenshots or the app switcher | Forgetting both the password and the recovery code (data is lost, by design) |

## 2. Vault keys

```
data key (DK)   random 32 bytes, made once at vault setup; encrypts every locked note
password key    = Argon2id(password, salt)                → wraps DK  → vault.wrapped_key_password
recovery key    = Argon2id(recovery code, salt_recovery)  → wraps DK  → vault.wrapped_key_recovery
key check       = AES-GCM(DK, "ozone-vault-v1")           → vault.key_check
```

- **Algorithms:** Argon2id for key derivation, and AES-256-GCM with a fresh random 12-byte nonce for every encryption
  (wrapping and each note save). Package: `cryptography` (F3 pins the version). All randomness comes from a secure random source.
- **Argon2id cost:** calibrated once at setup on this phone to take about **1 second**, never below memory 19 MiB,
  iterations 2, parallelism 1 (OWASP minimum). The parameters are saved in `vault.kdf_params`, so another phone uses the same ones.
  Derivation always runs in a background isolate with a progress indicator.
- **Why a data key:** changing the password or making a new recovery code re-wraps DK only. Notes are not re-encrypted.
- **Vault sheet in the workbook:** `kdf_params`, `salt`, `salt_recovery`, both wrapped keys and `key_check`, as base64.
  None of these opens anything without the password or recovery code.

## 3. Locked note format

`notes.cipher` = base64 of `version (1 byte) ‖ nonce (12) ‖ AES-GCM ciphertext + tag` over the UTF-8 JSON
`{"title": …, "content": <Delta JSON>, "tags": ["travel"]}`. The note ID is passed as associated data, so a cipher can't be
moved to another note. Each save re-encrypts with a new nonce.

## 4. Flows

| Flow | Rules |
|---|---|
| **Set up** (first time a note is locked) | Password at least 8 characters, typed twice; strength meter (W1 board). Then show the 16-character recovery code (4 groups of 4, from an alphabet without 0/O/1/I/L), which must be confirmed as saved. DK is created only after both steps. |
| **Unlock** | Password → derive → unwrap DK. Success keeps DK **in memory only** until the vault relocks. Wrong password: a message in words, field kept. After 5 wrong tries: wait 30 s, doubling per further miss (max 15 min), and the wait survives an app restart (stored in settings). |
| **Biometric unlock** (optional, phone-only) | Shown only when the phone has an enrolled biometric (docs/03). Turning it on stores a copy of DK in `flutter_secure_storage` under a biometric-protected key (Android Keystore / iOS Keychain). Enrolling a new fingerprint on the phone invalidates that key; OZONE then falls back to the password and asks to turn biometrics on again. |
| **Relock** | When OZONE goes to the background, when the phone locks, or from the Lock button. DK is wiped from memory and open locked notes close. |
| **Lock a note** | Encrypt the title, content and tags into `cipher`; clear the plain columns and `note_tags`; remove it from the search index. One transaction. |
| **Unlock a note permanently** ("Remove lock") | The reverse; needs the vault open. |
| **Change password** | Old password, then new password twice; re-wraps DK. |
| **New recovery code** | Needs the vault open. Makes a new code and re-wraps DK; the old code stops working. |
| **Forgot password** (W3 board) | Recovery code → unwrap DK → new password → **a new recovery code is issued** (the used one is retired). Codes are matched ignoring spaces and case. |
| **Reset vault** (W3 board) | Type DELETE. Deletes every locked note (tombstones written), the vault row and the biometric key. Unlocked notes are untouched. |
| **Import a different vault** (F1-03) | Ask for that file's password, unwrap its DK in memory, decrypt its locked notes, re-encrypt them with this phone's DK. |

## 5. App lock

- Turning it on needs a phone screen lock. Without one, show the W3 States message "Set a screen lock first" with
  **Open phone settings**.
- Unlock uses `local_auth` with device credentials allowed (fingerprint, face or the phone PIN/password), as the owner chose.
  OZONE never sees the credential.
- **Relock timer:** when OZONE goes to the background, store the time. On return, if `relock_after_s` has passed
  (0, 60 or 300; default 60), show the App lock gate before any content is drawn.
- The App lock gate covers everything, including when the app opens from a notification.

## 6. Privacy on screen

| Situation | Android | iOS |
|---|---|---|
| Vault open, or a locked note on screen | `FLAG_SECURE` on: screenshots and recordings blocked, app-switcher preview blank | Cover view when the app is inactive; screenshots can't be blocked on iOS, so none is claimed |
| App lock on | `FLAG_SECURE` on for the whole app (the app-switcher preview is blank, not blurred, on Android) | A blurred cover when inactive |
| Neither | Normal | Normal |

"Hide amounts" (`₱ ••••`) is display only. Screen readers announce "amount hidden".

## 7. Never

- Never log passwords, codes, keys, note text or amounts. Debug logs in release builds are off.
- Never write DK or the password to disk, except the biometric-protected copy described above.
- Never put locked note content in the search index, notifications, widgets or crash reports.

## Decisions (owner, 14 Oct 2026)

1. On Android, while app lock is on, the app-switcher preview is **blank** and screenshots are blocked everywhere in OZONE.
