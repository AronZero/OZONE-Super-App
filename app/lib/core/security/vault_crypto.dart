import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// The vault's cryptography (docs/spec/F2-01 §2–3), free of Flutter and the
/// database so it can be tested on its own.
///
/// - Keys come from Argon2id (password or recovery code + salt).
/// - Everything is sealed with AES-256-GCM and a fresh random 12-byte nonce.
/// - Randomness comes from `Random.secure()`.

/// Argon2id cost, stored in `vault.kdf_params` so another phone uses the same.
class KdfParams {
  const KdfParams({required this.memoryKiB, required this.iterations, this.parallelism = 1});

  /// OWASP minimum (F2-01 §2): 19 MiB, 2 iterations, parallelism 1.
  static const minimum = KdfParams(memoryKiB: 19456, iterations: 2);

  final int memoryKiB;
  final int iterations;
  final int parallelism;

  String toJson() => jsonEncode({'alg': 'argon2id', 'v': 19, 'm': memoryKiB, 't': iterations, 'p': parallelism});

  /// Never weaker than [minimum], whatever the stored text says.
  static KdfParams fromJson(String json) {
    final m = jsonDecode(json) as Map<String, Object?>;
    return KdfParams(
      memoryKiB: max(m['m']! as int, minimum.memoryKiB),
      iterations: max(m['t']! as int, minimum.iterations),
      parallelism: max(m['p']! as int, 1),
    );
  }

  @override
  bool operator ==(Object other) => other is KdfParams && other.memoryKiB == memoryKiB && other.iterations == iterations && other.parallelism == parallelism;
  @override
  int get hashCode => Object.hash(memoryKiB, iterations, parallelism);
}

final _rng = Random.secure();

Uint8List randomBytes(int n) => Uint8List.fromList(List<int>.generate(n, (_) => _rng.nextInt(256)));

/// Argon2id → 32-byte key, run in a background isolate (F2-01 §2) so the
/// screen keeps drawing its progress indicator.
Future<Uint8List> deriveKey(List<int> secret, List<int> salt, KdfParams p) {
  final s = Uint8List.fromList(secret), n = Uint8List.fromList(salt);
  return Isolate.run(() => deriveKeySync(s, n, p));
}

/// The same derivation on the calling isolate (tests and the isolate body).
Future<Uint8List> deriveKeySync(List<int> secret, List<int> salt, KdfParams p) async {
  final a = Argon2id(memory: p.memoryKiB, iterations: p.iterations, parallelism: p.parallelism, hashLength: 32);
  final k = await a.deriveKey(secretKey: SecretKey(secret), nonce: salt);
  return Uint8List.fromList(await k.extractBytes());
}

/// Picks the iterations so one derivation takes about [target] on this phone,
/// never below the minimum (F2-01 §2). Memory stays at 19 MiB (decision M6-1).
Future<KdfParams> calibrate({Duration target = const Duration(seconds: 1), int maxIterations = 10}) async {
  final sw = Stopwatch()..start();
  await deriveKey(randomBytes(16), randomBytes(16), KdfParams.minimum);
  final perIteration = sw.elapsedMicroseconds / KdfParams.minimum.iterations;
  final t = (target.inMicroseconds / max(perIteration, 1)).floor().clamp(KdfParams.minimum.iterations, maxIterations);
  return KdfParams(memoryKiB: KdfParams.minimum.memoryKiB, iterations: t);
}

final _gcm = AesGcm.with256bits();

/// AES-256-GCM: `nonce (12) ‖ ciphertext ‖ tag (16)`. [aad] binds the box to its owner.
Future<Uint8List> seal(List<int> key, List<int> plain, {List<int> aad = const []}) async {
  final box = await _gcm.encrypt(plain, secretKey: SecretKey(key), nonce: randomBytes(12), aad: aad);
  return Uint8List.fromList(box.concatenation());
}

/// Opens a [seal]ed box. Throws [VaultCryptoError] when the key is wrong or
/// the box was changed.
Future<Uint8List> open(List<int> key, List<int> sealed, {List<int> aad = const []}) async {
  if (sealed.length < 12 + 16) throw const VaultCryptoError();
  try {
    final box = SecretBox.fromConcatenation(sealed, nonceLength: 12, macLength: 16, copy: true);
    return Uint8List.fromList(await _gcm.decrypt(box, secretKey: SecretKey(key), aad: aad));
  } on SecretBoxAuthenticationError {
    throw const VaultCryptoError();
  }
}

/// A wrong key or a damaged/tampered cipher. Never carries secret material.
class VaultCryptoError implements Exception {
  const VaultCryptoError();
  @override
  String toString() => 'VaultCryptoError';
}

/// What `vault.key_check` seals (F2-01 §2).
const String keyCheckText = 'ozone-vault-v1';

/// Locked note format version (F2-01 §3).
const int noteCipherVersion = 1;

/// A locked note's secret part: title, Delta and tag names.
class LockedNote {
  const LockedNote({required this.title, required this.content, required this.tags});
  final String? title;

  /// Delta JSON text.
  final String content;
  final List<String> tags;

  String toJson() => jsonEncode({'title': title, 'content': jsonDecode(content), 'tags': tags});

  static LockedNote fromJson(String s) {
    final m = jsonDecode(s) as Map<String, Object?>;
    return LockedNote(
      title: m['title'] as String?,
      content: jsonEncode(m['content']),
      tags: [for (final t in (m['tags'] as List?) ?? const []) t as String],
    );
  }
}

/// `notes.cipher` = base64(version ‖ nonce ‖ ciphertext + tag); the note ID is
/// the associated data, so a cipher can't be moved to another note (F2-01 §3).
Future<String> encryptNote(List<int> dk, String noteId, LockedNote note) async {
  final sealed = await seal(dk, utf8.encode(note.toJson()), aad: utf8.encode(noteId));
  return base64Encode([noteCipherVersion, ...sealed]);
}

Future<LockedNote> decryptNote(List<int> dk, String noteId, String cipher) async {
  final List<int> bytes;
  try {
    bytes = base64Decode(cipher);
  } on FormatException {
    throw const VaultCryptoError();
  }
  if (bytes.isEmpty || bytes.first != noteCipherVersion) throw const VaultCryptoError();
  final plain = await open(dk, bytes.sublist(1), aad: utf8.encode(noteId));
  return LockedNote.fromJson(utf8.decode(plain));
}

/// Any other secret text sealed with DK (encrypted drafts), base64.
Future<String> encryptText(List<int> dk, String context, String text) async =>
    base64Encode(await seal(dk, utf8.encode(text), aad: utf8.encode(context)));

Future<String> decryptText(List<int> dk, String context, String b64) async {
  try {
    return utf8.decode(await open(dk, base64Decode(b64), aad: utf8.encode(context)));
  } on FormatException {
    throw const VaultCryptoError();
  }
}

// ── Recovery code ─────────────────────────────────────────────────────────

/// 31 characters, without 0/O/1/I/L (F2-01 §4): 16 of them ≈ 79 bits.
const String recoveryAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

/// 16 characters from [recoveryAlphabet], uniformly chosen.
String newRecoveryCode() => String.fromCharCodes([for (var i = 0; i < 16; i++) recoveryAlphabet.codeUnitAt(_rng.nextInt(recoveryAlphabet.length))]);

/// "K7QF 2M9D XR4T 8BWL".
String formatRecoveryCode(String code) => [for (var i = 0; i < code.length; i += 4) code.substring(i, min(i + 4, code.length))].join(' ');

/// Typed code → the stored form: spaces and dashes dropped, upper case (F2-01 §4).
String normaliseRecoveryCode(String typed) => typed.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

// ── Password strength (W1 · Vault setup board) ────────────────────────────

/// 0 = empty, 1 = too short, 2 fair, 3 good, 4 strong (by length, as on the board).
int passwordStrength(String pw) {
  final n = pw.runes.length;
  if (n == 0) return 0;
  if (n < 8) return 1;
  if (n < 12) return 2;
  if (n < 16) return 3;
  return 4;
}

const List<String> strengthWords = [
  'Type a password',
  'Too short · use at least 8 characters',
  'Fair · 2 of 4 · a longer phrase is safer',
  'Good · 3 of 4 · add another word to make it strong',
  'Strong · 4 of 4',
];

// ── Wrong-password waits (F2-01 §4) ───────────────────────────────────────

/// After 5 wrong tries: 30 s, doubling per further miss, at most 15 min.
Duration? lockoutAfter(int failures) {
  if (failures < 5) return null;
  final s = 30 * pow(2, min(failures - 5, 10)); // capped before it could overflow
  return Duration(seconds: min(s, 15 * 60).toInt());
}
