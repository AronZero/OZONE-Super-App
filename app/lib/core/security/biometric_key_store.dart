import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../platform/platform_channel.dart';

/// How reading the fingerprint copy of the vault key went.
enum BiometricRead { ok, cancelled, invalidated }

/// The fingerprint-protected copy of the vault key (F2-01 §4). A seam so tests
/// can fake it.
abstract class BiometricKeyStore {
  /// An enrolled strong biometric on a phone that can bind keys to it.
  Future<bool> available();

  /// Stores [dk]; the phone asks for the fingerprint.
  Future<bool> save(Uint8List dk);

  /// Asks for the fingerprint and returns the key ([BiometricRead.ok]).
  Future<(BiometricRead, Uint8List?)> read();

  Future<void> delete();
}

class SecureStorageBiometricKeyStore implements BiometricKeyStore {
  static const _key = 'vault_dk';

  // A Keystore key that needs a strong biometric for every use. Android
  // invalidates it when a new fingerprint is enrolled (F2-01 §4).
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions.biometric(
      enforceBiometrics: true,
      requireBiometricsPerOperation: true,
      biometricType: AndroidBiometricType.strongBiometricOnly,
      resetOnError: false,
      storageNamespace: 'ozone_vault',
      biometricPromptTitle: 'Unlock notes',
      biometricPromptSubtitle: 'Use your fingerprint to open locked notes',
      biometricPromptNegativeButton: 'Use password',
    ),
  );

  @override
  Future<bool> available() async {
    try {
      if (await OzonePlatform.androidSdk() < 28) return false;
      final auth = LocalAuthentication();
      if (!await auth.canCheckBiometrics) return false;
      final kinds = await auth.getAvailableBiometrics();
      return kinds.contains(BiometricType.strong) || kinds.contains(BiometricType.fingerprint);
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> save(Uint8List dk) async {
    try {
      await _storage.write(key: _key, value: base64Encode(dk));
      return true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<(BiometricRead, Uint8List?)> read() async {
    try {
      final v = await _storage.read(key: _key);
      if (v == null) return (BiometricRead.invalidated, null);
      return (BiometricRead.ok, base64Decode(v));
    } on PlatformException catch (e) {
      // A new fingerprint on the phone makes the key unusable for good.
      final msg = '${e.code} ${e.message}'.toLowerCase();
      if (msg.contains('invalidated') || msg.contains('keypermanentlyinvalidated')) {
        await delete();
        return (BiometricRead.invalidated, null);
      }
      return (BiometricRead.cancelled, null);
    } on FormatException {
      await delete();
      return (BiometricRead.invalidated, null);
    }
  }

  @override
  Future<void> delete() async {
    try {
      await _storage.delete(key: _key);
    } on PlatformException {
      // Nothing to remove, or the key is already gone.
    }
  }
}
