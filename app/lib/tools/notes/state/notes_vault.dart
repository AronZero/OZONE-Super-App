import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/vault_crypto.dart';
import '../../../core/security/vault_service.dart';
import '../../../core/state/providers.dart';
import '../data/notes_repo.dart';
import '../domain/notes.dart';
import 'notes_providers.dart';

/// Locking and unlocking single notes (F2-01 §4): the vault seals, the repo writes.
class NotesVault {
  NotesVault(this._vault, this._repo);
  final VaultService _vault;
  final NotesRepo _repo;

  /// Encrypts title, content and tag names into `cipher` (vault open).
  Future<void> lock(String noteId) async {
    final n = await _repo.note(noteId);
    if (n == null || n.isLocked) return;
    final data = await _repo.load();
    final cipher = await _vault.sealNote(
      noteId,
      LockedNote(title: n.title, content: n.content ?? jsonEncode(sanitizeDelta(const [])), tags: [for (final t in data.tagsOf(noteId)) t.name]),
    );
    await _repo.lockNote(noteId, cipher);
  }

  /// "Remove lock" (vault open).
  Future<void> removeLock(String noteId) async {
    final n = await _repo.note(noteId);
    if (n == null || !n.isLocked || n.cipher == null) return;
    final p = await _vault.openNote(noteId, n.cipher!);
    await _repo.unlockNote(noteId, title: p.title, content: p.content, tagNames: p.tags);
  }

  Future<LockedNote> read(String noteId, String cipher) => _vault.openNote(noteId, cipher);

  /// Autosave of a locked note: same tags, new title and text, new nonce.
  Future<void> save(String noteId, {required String title, required List<Object?> ops, required List<String> tags}) async {
    final n = await _repo.note(noteId);
    if (n == null || !n.isLocked || n.cipher == null) return;
    final content = jsonEncode(sanitizeDelta(ops));
    final t = normaliseTitle(title);
    final cur = await _vault.openNote(noteId, n.cipher!);
    if (cur.title == t && cur.content == content) {
      await _repo.discardDraft(noteId);
      return;
    }
    await _repo.saveLocked(noteId, await _vault.sealNote(noteId, LockedNote(title: t, content: content, tags: tags)));
  }

  /// Encrypted draft (F2-02 §3: locked notes' drafts are encrypted with DK).
  Future<void> writeDraft(String noteId, {required String title, required List<Object?> ops}) async =>
      _repo.writeSealedDraft(noteId, await _vault.sealDraft(noteId, NoteDraft(title: title, ops: ops, savedAt: 0).encode()));

  /// A recoverable draft of a locked note, opened with DK.
  Future<NoteDraft?> recoverableDraft(String noteId) async {
    final row = await _repo.sealedDraft(noteId);
    if (row == null) return null;
    try {
      final text = await _vault.openDraft(noteId, row.content);
      final m = jsonDecode(text) as Map<String, Object?>;
      return NoteDraft(title: (m['title'] as String?) ?? '', ops: (m['ops']! as List).cast<Object?>(), savedAt: row.savedAt);
    } on Object {
      return null; // unreadable drafts are ignored
    }
  }
}

final notesVaultProvider = Provider<NotesVault>((ref) => NotesVault(ref.watch(vaultServiceProvider), ref.watch(notesRepoProvider)));
