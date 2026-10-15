import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/database.dart';
import 'package:ozone/core/data/deletions_repo.dart';
import 'package:ozone/core/security/biometric_key_store.dart';
import 'package:ozone/tools/notes/data/notes_repo.dart';

import '../../helpers/harness.dart';

Future<AppDatabase> seeded(WidgetTester tester) async {
  final db = memoryDb();
  await tester.runAsync(() async {
    final r = NotesRepo(db, DeletionsRepo(db));
    final id = await r.create();
    await r.save(id, title: 'Diary', ops: [
      {'insert': 'Dear diary\n'},
    ]);
  });
  return db;
}

/// Lets real async work (key derivation, database) finish, then settles.
Future<void> work(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await settle(tester);
  }
}

Future<void> tapText(WidgetTester tester, String s) async {
  await tester.ensureVisible(find.text(s).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(s).last);
  await work(tester);
}

void main() {
  testWidgets('lock a note: set up the vault, relock, unlock with the password', (tester) async {
    final db = await seeded(tester);
    final bio = FakeBiometricKeyStore();
    final vault = testVault(db, fastKdf: true, bio: bio);
    await pumpApp(tester, db: db, vault: vault);
    await tester.tap(find.byKey(const ValueKey('bar-Notes')));
    await settle(tester);
    await tester.tap(find.text('Diary'));
    await settle(tester);

    await tester.tap(find.byTooltip('Note options: folder, tags, lock, move to trash'));
    await settle(tester);
    await tapText(tester, 'Lock note');

    // W1 · Vault setup, step 1.
    expect(find.text('Set up your notes vault'), findsOneWidget);
    expect(find.text('Unlock with fingerprint'), findsOneWidget); // the fake phone has one
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'short');
    await tester.enterText(fields.at(1), 'short');
    await tapText(tester, 'Continue');
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    await tester.enterText(fields.at(0), 'harbor-lantern-42');
    await tester.pump();
    expect(find.text('Strong · 4 of 4'), findsOneWidget);
    await tester.enterText(fields.at(1), 'harbor-lantern-41');
    await tapText(tester, 'Continue');
    expect(find.text('The two passwords don’t match'), findsOneWidget);
    await tester.enterText(fields.at(1), 'harbor-lantern-42');
    await tapText(tester, 'Continue');

    // Step 2: the code must be confirmed as saved.
    expect(find.text('Save your recovery code'), findsOneWidget);
    // The four groups are numbered, in reading order: 1 2 / 3 4.
    final pos = [for (final n in ['1', '2', '3', '4']) tester.getCenter(find.text(n))];
    expect(pos[0].dy, pos[1].dy);
    expect(pos[0].dx, lessThan(pos[1].dx));
    expect(pos[2].dy, greaterThan(pos[0].dy));
    expect(pos[2].dx, lessThan(pos[3].dx));
    expect(find.text('Finish · tick the box first'), findsOneWidget);
    await tapText(tester, 'I’ve saved my recovery code');
    await tapText(tester, 'Finish · lock this note');

    // Back in the editor, now locked.
    expect(vault.isOpen.value, isTrue);
    expect(find.text('Locked'), findsOneWidget);
    final n = await tester.runAsync(() => db.select(db.notes).getSingle());
    expect(n!.isLocked, isTrue);
    expect(n.title, isNull);

    await tester.tap(find.byTooltip('Back to Notes'));
    await work(tester);
    expect(find.text('Locked note'), findsOneWidget);

    // Lock now, then open it again with the password.
    await tester.tap(find.byTooltip('Lock notes now'));
    await work(tester);
    expect(vault.isOpen.value, isFalse);
    expect(bio.stored, isNotNull, reason: 'fingerprint unlock was on by default at setup');
    bio.next = BiometricRead.cancelled; // the person taps "Use password" on the phone's prompt
    await tester.tap(find.text('Locked note'));
    await work(tester);
    expect(find.text('Unlock notes'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'wrong password');
    await tapText(tester, 'Unlock with password');
    expect(find.text('That password isn’t right. Check it and try again.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'harbor-lantern-42');
    await tapText(tester, 'Unlock with password');
    expect(vault.isOpen.value, isTrue);
    expect(find.text('Diary'), findsOneWidget); // the decrypted title in the editor
    await closeApp(tester, db);
  });

  testWidgets('Security shows the vault rows once set up', (tester) async {
    final db = memoryDb();
    final vault = testVault(db, fastKdf: true);
    await tester.runAsync(() => vault.create(password: 'harbor-lantern-42', recoveryCode: 'K7QF2M9DXR4T8BWL'));
    await pumpApp(tester, db: db, vault: vault);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    await tester.tap(find.text('Security'));
    await work(tester);
    for (final s in ['Change vault password', 'Unlock with fingerprint', 'Make a new recovery code', 'Forgot vault password', 'Reset vault']) {
      await tester.ensureVisible(find.text(s));
      expect(find.text(s), findsOneWidget);
    }
    await tapText(tester, 'Reset vault');
    expect(find.text('There are no locked notes to delete'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pump();
    await tapText(tester, 'Delete locked notes and reset');
    expect(find.text('Vault reset'), findsOneWidget);
    expect(await tester.runAsync(vault.exists), isFalse);
    await closeApp(tester, db);
  });
}
