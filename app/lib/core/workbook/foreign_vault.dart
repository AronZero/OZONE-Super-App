import 'dart:convert';
import 'dart:typed_data';

import '../security/vault_crypto.dart';
import '../security/vault_service.dart';
import 'ozone_import.dart';

/// Locked notes from a file locked with another vault (F1-03 §2, F2-01 §4
/// "Import a different vault"): the file's vault password unwraps that file's
/// key in memory, each note is decrypted and re-encrypted with this phone's
/// key, and the file's key is wiped. The phone's vault must be open.
///
/// Returns how many notes can now be imported, or null when the password is wrong.
Future<int?> unlockOtherVault(ImportPlan plan, String password, VaultService phone) async {
  final v = plan.fileVault;
  if (v == null || !phone.isOpen.value) return null;
  final params = KdfParams.fromJson(v.values['kdf_params']!);
  final pk = await phone.derive(utf8.encode(password), base64Decode(v.values['salt']!), params);
  Uint8List? fileKey;
  try {
    fileKey = await open(pk, base64Decode(v.values['wrapped_key_password']!));
    await open(fileKey, base64Decode(v.values['key_check']!));
  } on VaultCryptoError {
    return null;
  } finally {
    pk.fillRange(0, pk.length, 0);
  }
  var n = 0;
  try {
    for (final r in plan.rows.where((r) => r.cls == RowClass.otherVault)) {
      final id = r.fileId!;
      try {
        final note = await decryptNote(fileKey, id, r.fields['cipher']! as String);
        r.fields['cipher'] = await phone.sealNote(id, note);
        r
          ..cls = r.matchId == null ? RowClass.newRow : RowClass.changed
          ..apply = r.matchId == null
          ..reason = null;
        n++;
      } on VaultCryptoError {
        r.reason = 'Row ${r.rowNo}: this locked note can’t be opened with that password';
        r.cls = RowClass.error;
      }
    }
  } finally {
    fileKey.fillRange(0, fileKey.length, 0);
  }
  return n;
}
