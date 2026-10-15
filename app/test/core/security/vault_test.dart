import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/data/settings_repo.dart';
import 'package:ozone/core/security/biometric_key_store.dart';
import 'package:ozone/core/security/vault_crypto.dart';
import 'package:ozone/core/security/vault_service.dart';
import 'package:ozone/tools/notes/data/notes_repo.dart';
import 'package:ozone/tools/notes/state/notes_vault.dart';

import '../../helpers/harness.dart';

String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

List<Object?> _text(String s) => [
      {'insert': '$s\n'},
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // the secure-screen channel needs it
  group('known answers (F3-03 crypto)', () {
    test('Argon2id matches RFC 9106 §5.3', () async {
      final a = Argon2id(parallelism: 4, memory: 32, iterations: 3, hashLength: 32);
      final k = await a.deriveKey(
        secretKey: SecretKey(List.filled(32, 1)),
        nonce: List.filled(16, 2),
        optionalSecret: List.filled(8, 3),
        associatedData: List.filled(12, 4),
      );
      expect(_hex(await k.extractBytes()), '0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659');
    });

    test('AES-256-GCM matches NIST GCM test case 14', () async {
      final box = await AesGcm.with256bits().encrypt(List.filled(16, 0), secretKey: SecretKey(List.filled(32, 0)), nonce: List.filled(12, 0));
      expect(_hex(box.cipherText), 'cea7403d4d606b6e074ec5d3baf39d18');
      expect(_hex(box.mac.bytes), 'd0d1c8a799996bf0265b98b5d48ab919');
    });
  });

  group('sealing', () {
    final dk = List<int>.generate(32, (i) => i);
    const note = LockedNote(title: 'Diary', content: '[{"insert":"secret\\n"}]', tags: ['personal']);

    test('a note round-trips; every save uses a new nonce', () async {
      final a = await encryptNote(dk, 'n1', note), b = await encryptNote(dk, 'n1', note);
      expect(a, isNot(b));
      final back = await decryptNote(dk, 'n1', a);
      expect(back.title, 'Diary');
      expect(back.tags, ['personal']);
      expect(jsonDecode(back.content), [{'insert': 'secret\n'}]);
      expect(base64Decode(a).first, noteCipherVersion);
    });

    test('the note ID is bound as associated data', () async {
      final c = await encryptNote(dk, 'n1', note);
      expect(() => decryptNote(dk, 'n2', c), throwsA(isA<VaultCryptoError>()));
    });

    test('a tampered cipher or a wrong key is rejected', () async {
      final bytes = base64Decode(await encryptNote(dk, 'n1', note));
      bytes[20] ^= 1;
      expect(() => decryptNote(dk, 'n1', base64Encode(bytes)), throwsA(isA<VaultCryptoError>()));
      final c = await encryptNote(dk, 'n1', note);
      expect(() => decryptNote(List.filled(32, 9), 'n1', c), throwsA(isA<VaultCryptoError>()));
      expect(() => decryptNote(dk, 'n1', 'not base64!'), throwsA(isA<VaultCryptoError>()));
    });

    test('KDF params never go below the OWASP minimum', () {
      expect(KdfParams.fromJson('{"m":1024,"t":1,"p":1}'), KdfParams.minimum);
      expect(KdfParams.fromJson(const KdfParams(memoryKiB: 19456, iterations: 5).toJson()).iterations, 5);
    });
  });

  group('recovery code and password rules', () {
    test('16 characters from the safe alphabet', () {
      for (var i = 0; i < 200; i++) {
        final c = newRecoveryCode();
        expect(c.length, 16);
        expect(c.split('').every(recoveryAlphabet.contains), isTrue);
      }
      expect(recoveryAlphabet.contains(RegExp('[0O1IL]')), isFalse);
    });

    test('codes match ignoring spaces, dashes and case', () {
      expect(normaliseRecoveryCode(' k7qf 2m9d-xr4t 8bwl '), 'K7QF2M9DXR4T8BWL');
      expect(formatRecoveryCode('K7QF2M9DXR4T8BWL'), 'K7QF 2M9D XR4T 8BWL');
    });

    test('strength by length, as on the board', () {
      expect([for (final p in ['', 'abc', 'abcdefgh', 'abcdefghijkl', 'abcdefghijklmnop']) passwordStrength(p)], [0, 1, 2, 3, 4]);
    });

    test('waits: none before 5 misses, then 30 s doubling, at most 15 min', () {
      expect(lockoutAfter(4), isNull);
      expect(lockoutAfter(5), const Duration(seconds: 30));
      expect(lockoutAfter(6), const Duration(seconds: 60));
      expect(lockoutAfter(10), const Duration(minutes: 15));
      expect(lockoutAfter(500), const Duration(minutes: 15));
    });
  });

  group('vault service (F2-01 §4)', () {
    late AppDatabase db;
    late VaultService vault;
    late FakeBiometricKeyStore bio;
    late NotesRepo repo;
    late NotesVault notes;
    var now = 1000000;
    const pw = 'harbor-lantern-42';
    const code = 'K7QF2M9DXR4T8BWL';

    setUp(() {
      db = memoryDb();
      bio = FakeBiometricKeyStore();
      now = 1000000;
      vault = testVault(db, bio: bio, clock: () => now);
      repo = NotesRepo(db, DeletionsRepo(db), clock: () => now);
      notes = NotesVault(vault, repo);
    });
    tearDown(() => db.close());

    Future<String> lockedNote(String title, String body, {List<String> tags = const []}) async {
      final ids = [for (final t in tags) await repo.ensureTag(t)];
      final id = await repo.create(tagIds: ids);
      now += 10;
      await repo.save(id, title: title, ops: _text(body));
      await notes.lock(id);
      return id;
    }

    test('setup opens the vault; relock wipes it; the password reopens it', () async {
      expect(await vault.exists(), isFalse);
      await vault.create(password: pw, recoveryCode: code);
      expect(vault.isOpen.value, isTrue);
      final row = await db.select(db.vault).getSingle();
      expect(KdfParams.fromJson(row.kdfParams), KdfParams.minimum);
      await vault.lock();
      expect(vault.isOpen.value, isFalse);
      expect(await vault.unlock('wrong password'), isA<WrongSecret>());
      expect(vault.isOpen.value, isFalse);
      expect(await vault.unlock(pw), isA<Unlocked>());
      expect(vault.isOpen.value, isTrue);
    });

    test('lock a note: plain columns, tags and draft go; Remove lock brings them back', () async {
      await vault.create(password: pw, recoveryCode: code);
      final id = await lockedNote('Diary', 'dear diary', tags: ['personal']);
      final n = (await repo.note(id))!;
      expect(n.isLocked, isTrue);
      expect([n.title, n.content, n.plainText], [null, null, null]);
      expect(n.cipher, isNotNull);
      expect(n.cipher!.contains('diary'), isFalse);
      expect(await db.select(db.noteTags).get(), isEmpty);

      await notes.removeLock(id);
      final back = (await repo.note(id))!;
      expect(back.isLocked, isFalse);
      expect(back.title, 'Diary');
      expect(back.plainText, 'dear diary');
      expect((await repo.load()).tagsOf(id).map((t) => t.name), ['personal']);
    });

    test('changing the password keeps notes readable; the old one stops working', () async {
      await vault.create(password: pw, recoveryCode: code);
      final id = await lockedNote('Diary', 'kept');
      await vault.lock();
      expect(await vault.changePassword('nope', 'new-password-1'), isFalse);
      expect(await vault.changePassword(pw, 'new-password-1'), isTrue);
      expect(await vault.unlock(pw), isA<WrongSecret>());
      expect(await vault.unlock('new-password-1'), isA<Unlocked>());
      final p = await notes.read(id, (await repo.note(id))!.cipher!);
      expect(jsonDecode(p.content), [{'insert': 'kept\n'}]);
    });

    test('forgot password: the code works once and a new code is issued', () async {
      await vault.create(password: pw, recoveryCode: code);
      final id = await lockedNote('Diary', 'kept');
      await vault.lock();
      expect(await vault.openWithRecoveryCode('AAAA BBBB CCCC DDDD'), isFalse);
      expect(await vault.openWithRecoveryCode('k7qf 2m9d xr4t 8bwl'), isTrue);
      const newCode = 'P3WN6HTA9C2ELQ5V';
      await vault.finishRecovery(newPassword: 'fresh-password', newCode: newCode);
      await vault.lock();
      expect(await vault.openWithRecoveryCode(code), isFalse, reason: 'the used code is retired');
      expect(await vault.unlock('fresh-password'), isA<Unlocked>());
      await vault.lock();
      expect(await vault.openWithRecoveryCode(newCode), isTrue);
      expect((await notes.read(id, (await repo.note(id))!.cipher!)).title, 'Diary');
    });

    test('a new recovery code retires the old one', () async {
      await vault.create(password: pw, recoveryCode: code);
      await vault.replaceRecoveryCode('P3WN6HTA9C2ELQ5V');
      await vault.lock();
      expect(await vault.openWithRecoveryCode(code), isFalse);
      expect(await vault.openWithRecoveryCode('P3WN6HTA9C2ELQ5V'), isTrue);
    });

    test('5 wrong passwords start a wait that survives a restart', () async {
      await vault.create(password: pw, recoveryCode: code);
      await vault.lock();
      for (var i = 0; i < 4; i++) {
        expect(await vault.unlock('x$i'), isA<WrongSecret>().having((w) => w.wait, 'wait', isNull));
      }
      expect(await vault.unlock('x4'), isA<WrongSecret>().having((w) => w.wait, 'wait', const Duration(seconds: 30)));
      expect(await vault.unlock(pw), isA<MustWait>(), reason: 'even the right password waits');
      // A "restart": a new service on the same database still waits.
      final again = testVault(db, bio: bio, clock: () => now);
      expect(await again.unlock(pw), isA<MustWait>());
      now += 31000;
      expect(await vault.unlock('x5'), isA<WrongSecret>().having((w) => w.wait, 'wait', const Duration(seconds: 60)));
      now += 61000;
      expect(await vault.unlock(pw), isA<Unlocked>());
      expect((await SettingsRepo(db).get(SettingKeys.vaultLockout)).failures, 0);
    });

    test('fingerprint unlock; a changed fingerprint falls back to the password', () async {
      await vault.create(password: pw, recoveryCode: code, biometric: true);
      expect(await vault.biometricOn(), isTrue);
      await vault.lock();
      expect(await vault.unlockWithFingerprint(), isA<Unlocked>());
      await vault.lock();
      bio.next = BiometricRead.cancelled;
      expect(await vault.unlockWithFingerprint(), isA<FingerprintCancelled>());
      expect(await vault.biometricOn(), isTrue);
      bio.next = BiometricRead.invalidated;
      expect(await vault.unlockWithFingerprint(), isA<FingerprintChanged>());
      expect(await vault.biometricOn(), isFalse);
      expect(vault.isOpen.value, isFalse);
    });

    test('locked notes save sealed; relock removes their drafts', () async {
      await vault.create(password: pw, recoveryCode: code);
      final id = await lockedNote('Diary', 'one');
      now += 1000;
      await notes.save(id, title: 'Diary', ops: _text('two'), tags: const []);
      expect(jsonDecode((await notes.read(id, (await repo.note(id))!.cipher!)).content), [{'insert': 'two\n'}]);
      now += 1000;
      await notes.writeDraft(id, title: 'Diary', ops: _text('three'));
      final draft = (await db.select(db.noteDrafts).getSingle()).content;
      expect(draft.contains('three'), isFalse, reason: 'drafts of locked notes are encrypted');
      expect((await notes.recoverableDraft(id))!.ops, _text('three'));
      var saved = false;
      Future<void> hook() async => saved = true;
      vault.addBeforeLock(hook);
      await vault.lock();
      expect(saved, isTrue);
      expect(await db.select(db.noteDrafts).get(), isEmpty);
    });

    test('reset deletes only locked notes, with tombstones', () async {
      await vault.create(password: pw, recoveryCode: code, biometric: true);
      final locked = await lockedNote('Diary', 'x');
      final open = await repo.create();
      now += 10;
      await repo.save(open, title: 'Groceries', ops: _text('rice'));
      expect(await vault.lockedNoteCount(), 1);
      expect(await vault.reset(), 1);
      expect(await vault.exists(), isFalse);
      expect(vault.isOpen.value, isFalse);
      expect(await repo.note(locked), isNull);
      expect(await DeletionsRepo(db).isDeleted('note', locked), isTrue);
      expect((await repo.note(open))!.title, 'Groceries');
      expect(bio.stored, isNull);
      expect(await vault.biometricOn(), isFalse);
    });
  });
}
