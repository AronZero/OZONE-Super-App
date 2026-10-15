import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/domain/dates.dart';
import 'package:ozone/core/security/vault_service.dart';
import 'package:ozone/core/workbook/foreign_vault.dart';
import 'package:ozone/core/workbook/ozone_export.dart';
import 'package:ozone/core/workbook/ozone_import.dart';
import 'package:ozone/core/workbook/workbook.dart';
import 'package:ozone/tools/notes/data/notes_repo.dart';
import 'package:ozone/tools/notes/state/notes_vault.dart';

import '../../helpers/harness.dart';

/// Importing locked notes from a file locked with another vault (F1-03 §2,
/// F2-01 §4): the file's password re-encrypts them with this phone's key.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const filePw = 'harbor-lantern-42', phonePw = 'meadow-copper-17';
  late AppDatabase fileDb, phoneDb;
  late VaultService fileVault, phoneVault;
  late String noteId;

  setUp(() async {
    fileDb = memoryDb();
    phoneDb = memoryDb();
    fileVault = testVault(fileDb, fastKdf: true);
    phoneVault = testVault(phoneDb, fastKdf: true);
    await fileVault.create(password: filePw, recoveryCode: 'K7QF2M9DXR4T8BWL');
    await phoneVault.create(password: phonePw, recoveryCode: 'M3PX7QK2ZR8D4TWB');
    final repo = NotesRepo(fileDb, DeletionsRepo(fileDb));
    noteId = await repo.create(tagIds: [await repo.ensureTag('diary')]);
    await repo.save(noteId, title: 'Secret plan', ops: [
      {'insert': 'meet at noon\n'},
    ]);
    await NotesVault(fileVault, repo).lock(noteId);
  });
  tearDown(() async {
    await fileDb.close();
    await phoneDb.close();
  });

  Future<ImportPlan> plan() async {
    final bytes = XlsxCodec.encode(await buildWorkbook(fileDb, appVersion: 't'));
    return planImport(phoneDb, XlsxCodec.decode(bytes), fileName: 'other.xlsx', today: LocalDate(2026, 10, 15));
  }

  ImportRow lockedRow(ImportPlan p) => p.rows.singleWhere((r) => r.table == 'notes' && r.fields['is_locked'] == true);

  test('a note locked with another vault waits for that vault’s password', () async {
    final p = await plan();
    expect(lockedRow(p).cls, RowClass.otherVault);
    expect(lockedRow(p).apply, isFalse);
  });

  test('a wrong password changes nothing', () async {
    final p = await plan();
    expect(await unlockOtherVault(p, 'not the password', phoneVault), isNull);
    expect(lockedRow(p).cls, RowClass.otherVault);
  });

  test('the phone’s vault must be open', () async {
    final p = await plan();
    await phoneVault.lock();
    expect(await unlockOtherVault(p, filePw, phoneVault), isNull);
  });

  test('the right password re-encrypts the note for this phone; it imports and opens with the phone’s key', () async {
    final p = await plan();
    expect(await unlockOtherVault(p, filePw, phoneVault), 1);
    final r = lockedRow(p);
    expect(r.cls, RowClass.newRow);
    expect(r.apply, isTrue);

    await applyImport(phoneDb, p);
    final row = await (phoneDb.select(phoneDb.notes)..where((n) => n.id.equals(noteId))).getSingle();
    expect(row.isLocked, isTrue);
    expect(row.title, isNull, reason: 'locked notes keep nothing readable');
    final note = await phoneVault.openNote(noteId, row.cipher!);
    expect(note.title, 'Secret plan');
    expect(note.content, contains('meet at noon'));
    expect(note.tags, ['diary']);
  });

  test('a damaged locked note becomes an error row, the rest still import', () async {
    final p = await plan();
    lockedRow(p).fields['cipher'] = 'AAAA${(lockedRow(p).fields['cipher']! as String).substring(4)}';
    expect(await unlockOtherVault(p, filePw, phoneVault), 0);
    expect(lockedRow(p).cls, RowClass.error);
    expect(lockedRow(p).reason, contains('can’t be opened with that password'));
  });
}
