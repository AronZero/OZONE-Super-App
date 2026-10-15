import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';

import '../data/database.dart';
import '../data/deletions_repo.dart';
import '../data/settings_repo.dart';
import 'biometric_key_store.dart';
import 'secure_screen.dart';
import 'vault_crypto.dart';

/// Result of an unlock attempt.
sealed class UnlockResult {
  const UnlockResult();
}

class Unlocked extends UnlockResult {
  const Unlocked();
}

class WrongSecret extends UnlockResult {
  const WrongSecret({this.wait});

  /// Set when this miss started a wait.
  final Duration? wait;
}

class MustWait extends UnlockResult {
  const MustWait(this.left);
  final Duration left;
}

class FingerprintCancelled extends UnlockResult {
  const FingerprintCancelled();
}

/// The phone's fingerprints changed, so the fingerprint copy of the key is gone.
class FingerprintChanged extends UnlockResult {
  const FingerprintChanged();
}

/// The notes vault (docs/spec/F2-01 §2–4). Holds the data key (DK) in memory
/// only while open; never logs or stores the password, code or keys.
class VaultService with WidgetsBindingObserver {
  VaultService(this._db, this._settings, this._deletions, this._bio, {int Function()? clock, this.calibrateKdf = calibrate, this.derive = deriveKey})
      : _clock = clock ?? (() => DateTime.now().toUtc().millisecondsSinceEpoch);

  final AppDatabase _db;
  final SettingsRepo _settings;
  final DeletionsRepo _deletions;
  final BiometricKeyStore _bio;
  final int Function() _clock;

  /// Argon2id calibration (tests pass a fast one).
  final Future<KdfParams> Function() calibrateKdf;

  /// Argon2id; a background isolate in the app (tests run it in place).
  final Future<Uint8List> Function(List<int> secret, List<int> salt, KdfParams p) derive;

  Uint8List? _dk;

  /// True while locked notes can be read.
  final ValueNotifier<bool> isOpen = ValueNotifier(false);

  /// Work that must finish before DK is wiped (open editors save first).
  final List<Future<void> Function()> _beforeLock = [];

  /// While the phone's own prompt is up, OZONE isn't "leaving".
  bool _prompting = false;

  void start() => WidgetsBinding.instance.addObserver(this);

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wipe();
    isOpen.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Relock when OZONE goes to the background or the phone locks (F2-01 §4).
    if (!_prompting && (state == AppLifecycleState.paused || state == AppLifecycleState.hidden)) unawaited(lock());
  }

  void addBeforeLock(Future<void> Function() f) => _beforeLock.add(f);
  void removeBeforeLock(Future<void> Function() f) => _beforeLock.remove(f);

  Future<VaultRow?> _row() => (_db.select(_db.vault)..where((v) => v.id.equals(1))).getSingleOrNull();

  Future<bool> exists() async => await _row() != null;

  Stream<bool> watchExists() => (_db.select(_db.vault)..where((v) => v.id.equals(1))).watchSingleOrNull().map((r) => r != null);

  void _open(Uint8List dk) {
    _dk = dk;
    isOpen.value = true;
    SecureScreen.set(SecureReason.vault, true);
  }

  void _wipe() {
    final dk = _dk;
    if (dk != null) dk.fillRange(0, dk.length, 0);
    _dk = null;
    if (isOpen.value) isOpen.value = false;
    SecureScreen.set(SecureReason.vault, false);
  }

  Uint8List get _key {
    final dk = _dk;
    if (dk == null) throw StateError('The vault is locked');
    return dk;
  }

  // ── Set up ───────────────────────────────────────────────────────────────

  /// Creates DK and the vault row after both setup steps (F2-01 §4), and opens it.
  Future<void> create({required String password, required String recoveryCode, bool biometric = false}) async {
    if (await exists()) throw StateError('A vault already exists');
    final params = await calibrateKdf();
    final dk = randomBytes(32);
    final salt = randomBytes(16), saltRecovery = randomBytes(16);
    final pk = await derive(utf8.encode(password), salt, params);
    final rk = await derive(utf8.encode(normaliseRecoveryCode(recoveryCode)), saltRecovery, params);
    final now = _clock();
    await _db.into(_db.vault).insert(VaultCompanion.insert(
          id: const Value(1),
          kdfParams: params.toJson(),
          salt: salt,
          saltRecovery: saltRecovery,
          wrappedKeyPassword: await seal(pk, dk),
          wrappedKeyRecovery: await seal(rk, dk),
          keyCheck: await seal(dk, utf8.encode(keyCheckText)),
          createdAt: now,
          updatedAt: now,
        ));
    _wipeAll([pk, rk]);
    _open(dk);
    if (biometric) await setBiometric(true);
  }

  // ── Unlock and lock ──────────────────────────────────────────────────────

  /// The wait left before another password try, if any.
  Future<Duration?> waitLeft() async {
    final l = await _settings.get(SettingKeys.vaultLockout);
    final left = l.untilMs - _clock();
    return left > 0 ? Duration(milliseconds: left) : null;
  }

  Future<UnlockResult> unlock(String password) async {
    final wait = await waitLeft();
    if (wait != null) return MustWait(wait);
    final row = await _row();
    if (row == null) throw StateError('No vault');
    final dk = await _unwrap(password, row.salt, row.wrappedKeyPassword, row);
    final l = await _settings.get(SettingKeys.vaultLockout);
    if (dk == null) {
      final failures = l.failures + 1;
      final w = lockoutAfter(failures);
      await _settings.set(SettingKeys.vaultLockout, VaultLockout(failures: failures, untilMs: w == null ? 0 : _clock() + w.inMilliseconds));
      return WrongSecret(wait: w);
    }
    if (l.failures != 0) await _settings.set(SettingKeys.vaultLockout, const VaultLockout(failures: 0, untilMs: 0));
    _open(dk);
    return const Unlocked();
  }

  Future<Uint8List?> _unwrap(String secret, List<int> salt, List<int> wrapped, VaultRow row) async {
    final k = await derive(utf8.encode(secret), salt, KdfParams.fromJson(row.kdfParams));
    try {
      final dk = await open(k, wrapped);
      // The key check proves this is the vault's key, not just any 32 bytes.
      await open(dk, row.keyCheck);
      return dk;
    } on VaultCryptoError {
      return null;
    } finally {
      _wipeAll([k]);
    }
  }

  Future<bool> biometricAvailable() => _bio.available();

  Future<bool> biometricOn() => _settings.get(SettingKeys.vaultBiometric);

  Future<UnlockResult> unlockWithFingerprint() async {
    _prompting = true;
    try {
      final (r, dk) = await _bio.read();
      switch (r) {
        case BiometricRead.cancelled:
          return const FingerprintCancelled();
        case BiometricRead.invalidated:
          await _settings.set(SettingKeys.vaultBiometric, false);
          return const FingerprintChanged();
        case BiometricRead.ok:
          final row = await _row();
          try {
            await open(dk!, row!.keyCheck);
          } on VaultCryptoError {
            await _bio.delete();
            await _settings.set(SettingKeys.vaultBiometric, false);
            return const FingerprintChanged();
          }
          _open(dk);
          return const Unlocked();
      }
    } finally {
      _prompting = false;
    }
  }

  /// Turns fingerprint unlock on (needs the vault open) or off.
  Future<bool> setBiometric(bool on) async {
    if (!on) {
      await _bio.delete();
      await _settings.set(SettingKeys.vaultBiometric, false);
      return true;
    }
    _prompting = true;
    try {
      final ok = await _bio.save(Uint8List.fromList(_key));
      if (ok) await _settings.set(SettingKeys.vaultBiometric, true);
      return ok;
    } finally {
      _prompting = false;
    }
  }

  /// Relock: open editors save, encrypted drafts go, DK is wiped (F2-01 §4, F2-02 §3).
  Future<void> lock() async {
    if (_dk == null) return;
    for (final f in [..._beforeLock]) {
      try {
        await f();
      } on Object {
        // A failed save must never keep the vault open.
      }
    }
    await _db.customStatement('DELETE FROM note_drafts WHERE note_id IN (SELECT id FROM notes WHERE is_locked = 1)');
    _wipe();
  }

  // ── Password and recovery code ───────────────────────────────────────────

  /// Re-wraps DK with a new password; notes aren't re-encrypted (F2-01 §2).
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final row = await _row();
    if (row == null) return false;
    final dk = await _unwrap(oldPassword, row.salt, row.wrappedKeyPassword, row);
    if (dk == null) return false;
    await _rewrapPassword(dk, newPassword, row);
    _wipeAll([dk]);
    return true;
  }

  Future<void> _rewrapPassword(Uint8List dk, String password, VaultRow row) async {
    final salt = randomBytes(16);
    final pk = await derive(utf8.encode(password), salt, KdfParams.fromJson(row.kdfParams));
    await (_db.update(_db.vault)..where((v) => v.id.equals(1))).write(VaultCompanion(
      salt: Value(salt),
      wrappedKeyPassword: Value(await seal(pk, dk)),
      updatedAt: Value(_clock()),
    ));
    _wipeAll([pk]);
  }

  /// "Make a new recovery code" (vault open): the old code stops working.
  Future<void> replaceRecoveryCode(String code) async {
    final row = await _row();
    if (row == null) throw StateError('No vault');
    final salt = randomBytes(16);
    final rk = await derive(utf8.encode(normaliseRecoveryCode(code)), salt, KdfParams.fromJson(row.kdfParams));
    await (_db.update(_db.vault)..where((v) => v.id.equals(1))).write(VaultCompanion(
      saltRecovery: Value(salt),
      wrappedKeyRecovery: Value(await seal(rk, _key)),
      updatedAt: Value(_clock()),
    ));
    _wipeAll([rk]);
  }

  /// Forgot password, step 1: a right code opens the vault.
  Future<bool> openWithRecoveryCode(String code) async {
    final row = await _row();
    if (row == null) return false;
    final dk = await _unwrap(normaliseRecoveryCode(code), row.saltRecovery, row.wrappedKeyRecovery, row);
    if (dk == null) return false;
    _open(dk);
    return true;
  }

  /// Forgot password, last step: new password and a new code together (the used code is retired).
  Future<void> finishRecovery({required String newPassword, required String newCode}) async {
    final row = (await _row())!;
    await _rewrapPassword(_key, newPassword, row);
    await replaceRecoveryCode(newCode);
    await _settings.set(SettingKeys.vaultLockout, const VaultLockout(failures: 0, untilMs: 0));
  }

  // ── Reset ────────────────────────────────────────────────────────────────

  Future<int> lockedNoteCount() async =>
      (await (_db.select(_db.notes)..where((n) => n.isLocked.equals(true))).get()).length;

  /// Type DELETE (W3 board): every locked note (with tombstones), the vault row
  /// and the fingerprint key go. Unlocked notes are untouched.
  Future<int> reset() async {
    _wipe();
    final n = await _db.transaction(() async {
      final locked = await (_db.select(_db.notes)..where((n) => n.isLocked.equals(true))).get();
      for (final note in locked) {
        await (_db.delete(_db.noteTags)..where((l) => l.noteId.equals(note.id))).go();
        await (_db.delete(_db.noteDrafts)..where((d) => d.noteId.equals(note.id))).go();
        await (_db.delete(_db.notes)..where((x) => x.id.equals(note.id))).go();
        await _deletions.record('note', note.id);
      }
      await _db.delete(_db.vault).go();
      return locked.length;
    });
    await setBiometric(false);
    await _settings.set(SettingKeys.vaultLockout, const VaultLockout(failures: 0, untilMs: 0));
    return n;
  }

  // ── Sealing with DK (vault open) ─────────────────────────────────────────

  Future<String> sealNote(String noteId, LockedNote note) => encryptNote(_key, noteId, note);
  Future<LockedNote> openNote(String noteId, String cipher) => decryptNote(_key, noteId, cipher);
  Future<String> sealDraft(String noteId, String text) => encryptText(_key, 'draft:$noteId', text);
  Future<String> openDraft(String noteId, String b64) => decryptText(_key, 'draft:$noteId', b64);

  static void _wipeAll(List<Uint8List> keys) {
    for (final k in keys) {
      k.fillRange(0, k.length, 0);
    }
  }
}
