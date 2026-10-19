import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';

import '../app_info.dart';
import '../data/database.dart';
import '../data/photo_store.dart';
import '../domain/dates.dart';
import '../domain/ids.dart';
import 'backup_zip.dart';
import 'ozone_export.dart';
import 'ozone_import.dart';
import 'workbook.dart';

/// Runs heavy work off the UI thread (F2-03 §8). Tests pass one that runs in place.
typedef HeavyRunner = Future<R> Function<R>(R Function() work);

Future<R> _isolate<R>(R Function() work) => Isolate.run(work);

/// A built export, waiting in app storage for "Save to" and "Share".
class BuiltExport {
  const BuiltExport(this.file, this.name, this.counts);
  final File file;
  final String name;
  final Map<String, int> counts;

  int get total => counts.values.fold(0, (a, b) => a + b);
}

/// Export, safety exports and import (docs/spec/F1-03), as a `.zip` with the
/// workbook and the recipe photos since 1.2.0 (F4-01 §5–6).
class BackupService {
  BackupService(this._db, {required this.workDir, required this.safetyDir, this.photos, HeavyRunner? heavy, int Function()? clock})
      : _heavy = heavy ?? _isolate,
        _clock = clock ?? (() => DateTime.now().toUtc().millisecondsSinceEpoch);

  final AppDatabase _db;

  /// Recipe photos; null in tests that don't need them.
  final PhotoStore? photos;

  /// Temporary exports (app cache).
  final Future<Directory> Function() workDir;

  /// Safety exports (app-private, F2-03 §2).
  final Future<Directory> Function() safetyDir;
  final HeavyRunner _heavy;
  final int Function() _clock;

  /// Files over this size can't be OZONE workbooks at this scale (F1-03 §4).
  static const maxBytes = 25 * 1024 * 1024;

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// `OZONE-YYYY-MM-DD.zip` (local date, F1-02 §1 and F4-01 §5).
  static String exportName(DateTime local) => 'OZONE-${local.year}-${_two(local.month)}-${_two(local.day)}.zip';

  /// `OZONE-safety-YYYY-MM-DD-HHmm.zip`.
  static String safetyName(DateTime local) =>
      'OZONE-safety-${local.year}-${_two(local.month)}-${_two(local.day)}-${_two(local.hour)}${_two(local.minute)}.zip';

  /// MIME type of the backup file, for "Save to" and Share.
  static const mime = 'application/zip';

  /// Steps 1–3 of F1-03 §1: a consistent snapshot, built off the UI thread,
  /// written to a temporary name and then moved into place.
  Future<BuiltExport> build({void Function(ExportStep)? onStep, bool Function()? cancelled, String? name}) async {
    final book = await buildWorkbook(_db, appVersion: appVersion, onStep: onStep, cancelled: cancelled);
    if (cancelled?.call() ?? false) throw const ExportCancelled();
    // The photos of this snapshot. One whose file is gone is left out, and its
    // Photo cell is cleared, so the backup never names a photo it doesn't hold.
    final photoFiles = <(String, String)>[];
    final sheet = book.sheet('Recipes');
    final col = sheet?.column('Photo');
    if (sheet != null && col != null) {
      for (final row in sheet.rows) {
        final name = row[col] as String?;
        if (name == null) continue;
        final file = await photos?.file(name);
        if (file != null && file.existsSync()) {
          photoFiles.add((name, file.path));
        } else {
          row[col] = null;
        }
      }
    }
    final bytes = await _heavy(() => XlsxCodec.encode(book));
    if (cancelled?.call() ?? false) throw const ExportCancelled();
    final dir = await workDir();
    await dir.create(recursive: true);
    // Old exports in the work folder are no longer needed.
    for (final f in dir.listSync().whereType<File>()) {
      try {
        f.deleteSync();
      } on FileSystemException {
        // In use by a share sheet; it goes next time.
      }
    }
    final fileName = name ?? exportName(DateTime.now());
    final tmp = File('${dir.path}/.$fileName.part');
    final workbookName = fileName.replaceFirst(RegExp(r'\.zip$'), '.xlsx');
    final wb = Uint8List.fromList(bytes);
    try {
      await _heavy(() => BackupZip.write(tmp.path, workbookName, wb, photoFiles));
    } on Object {
      if (tmp.existsSync()) await tmp.delete();
      rethrow;
    }
    final file = await tmp.rename('${dir.path}/$fileName');
    return BuiltExport(file, fileName, rowCounts(book));
  }

  /// After the file was saved where the person chose: "Last export" moves (F1-03 §1 step 4).
  Future<void> recordExport(BuiltExport e, {String kind = 'manual', String? savedAs}) => _db.into(_db.exportsLog).insert(ExportsLogCompanion.insert(
        id: newId(),
        kind: kind,
        fileName: savedAs ?? e.name,
        createdAt: _clock(),
        rowCounts: jsonEncode(e.counts),
      ));

  /// The newest manual export, if any.
  Stream<ExportLogRow?> watchLastExport() => (_db.select(_db.exportsLog)
        ..where((e) => e.kind.equals('manual'))
        ..orderBy([(e) => OrderingTerm.desc(e.createdAt)])
        ..limit(1))
      .watchSingleOrNull();

  /// A full export kept in app-private storage before an import (F1-03 §2 step 5).
  /// Only the newest 3 are kept.
  Future<File> safetyExport() async {
    final dir = await safetyDir();
    await dir.create(recursive: true);
    final e = await build(name: safetyName(DateTime.now()));
    var target = File('${dir.path}/${e.name}');
    for (var i = 2; target.existsSync(); i++) {
      target = File('${dir.path}/${e.name.replaceFirst('.zip', '-$i.zip')}');
    }
    final saved = await e.file.copy(target.path);
    await recordExport(e, kind: 'safety', savedAs: saved.uri.pathSegments.last);
    final all = await safetyExports();
    for (final old in all.skip(3)) {
      await old.delete();
    }
    await (_db.delete(_db.exportsLog)
          ..where((x) => x.kind.equals('safety') & x.fileName.isNotIn([for (final f in all.take(3)) f.uri.pathSegments.last])))
        .go();
    return saved;
  }

  /// Safety exports, newest first.
  Future<List<File>> safetyExports() async {
    final dir = await safetyDir();
    if (!dir.existsSync()) return const [];
    return [for (final f in dir.listSync().whereType<File>()) if (f.path.endsWith('.zip') || f.path.endsWith('.xlsx')) f]
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  }

  /// Steps 1–3 of F1-03 §2: read the file off the UI thread, then match and classify.
  Future<ImportPlan> read(List<int> bytes, {required String fileName, required LocalDate today, bool restore = false}) async {
    if (bytes.length > maxBytes) throw const ImportRefused('This file is over 25 MB, so it can’t be an OZONE workbook.');
    final Workbook book;
    try {
      book = await _heavy(() => XlsxCodec.decode(bytes));
    } on FormatException catch (e) {
      throw ImportRefused(e.message);
    }
    return planImport(_db, book, fileName: fileName, today: today, restore: restore);
  }

  /// Steps 1–3 for a picked file: a backup `.zip` is unpacked off the UI
  /// thread into a private folder (F4-01 §6); a plain `.xlsx` reads as before.
  Future<ImportPlan> readFile(File file, {required String fileName, required LocalDate today, bool restore = false}) async {
    final path = file.path;
    final kind = await _heavy(() => BackupZip.kind(path));
    // Decided by content, so a renamed file still opens; anything unreadable gets
    // the message for the type its name claims.
    if (kind == FileKind.backup || (kind == FileKind.other && fileName.toLowerCase().endsWith('.zip'))) {
      final out = '${(await workDir()).path}/import-${newId()}';
      final UnpackedZip z;
      try {
        z = await _heavy(() => BackupZip.unpack(path, out));
      } on BackupZipRefused catch (e) {
        _deleteDir(out);
        throw ImportRefused(e.message);
      }
      try {
        final book = await _heavy(() => XlsxCodec.decode(z.workbook));
        return await planImport(_db, book,
            fileName: fileName, today: today, restore: restore, filePhotos: z.photos, photoDir: z.photoDir, phonePhotos: await _phonePhotos());
      } on FormatException catch (e) {
        _deleteDir(out);
        throw ImportRefused(e.message);
      } on Object {
        _deleteDir(out);
        rethrow;
      }
    }
    if (file.lengthSync() > maxBytes) throw const ImportRefused('This file is over 25 MB, so it can’t be an OZONE workbook.');
    return read(await file.readAsBytes(), fileName: fileName, today: today, restore: restore);
  }

  Future<Set<String>> _phonePhotos() async {
    final p = photos;
    if (p == null) return const {};
    final dir = await p.folder();
    return {for (final f in dir.listSync().whereType<File>()) f.uri.pathSegments.last};
  }

  static void _deleteDir(String path) {
    final d = Directory(path);
    if (d.existsSync()) d.deleteSync(recursive: true);
  }

  /// On start: removes unpacked imports left behind when OZONE was stopped mid-import.
  Future<void> cleanUp() async {
    final dir = await workDir();
    if (!dir.existsSync()) return;
    for (final d in dir.listSync().whereType<Directory>()) {
      if (d.uri.pathSegments.where((s) => s.isNotEmpty).last.startsWith('import-')) d.deleteSync(recursive: true);
    }
  }

  /// The unpacked photos of a plan that won't be applied (Cancel, Back).
  void discard(ImportPlan plan) {
    final dir = plan.photoDir;
    if (dir != null) _deleteDir(Directory(dir).parent.path);
  }

  /// Steps 5–6: the safety export first (an import never starts without it),
  /// then the photos, then everything in one transaction. Returns the safety
  /// file and rows written. Photos copied for a failed import are removed.
  Future<(File?, Map<String, int>)> apply(ImportPlan plan, {bool restore = false}) async {
    try {
      // A restore onto an empty phone has nothing to protect.
      final safety = restore ? null : await safetyExport();
      final copied = <String>[];
      final store = photos;
      try {
        if (store != null && plan.photoDir != null) {
          for (final name in plan.photosToCopy) {
            await store.put(File('${plan.photoDir}/$name'), name);
            copied.add(name);
          }
        }
        final written = await applyImport(_db, plan);
        return (safety, written);
      } on Object {
        for (final name in copied) {
          await store!.delete(name);
        }
        rethrow;
      }
    } finally {
      discard(plan);
    }
  }

  /// A blank workbook with every sheet's headers (F1-02 §1).
  Future<BuiltExport> template() async {
    final blank = Workbook([
      WbSheet('Read me', ['Read me'], [for (final l in Layout.readMe) [l]]),
      WbSheet('_Meta', ['Key', 'Value'], [
        ['format', 'ozone-workbook'],
        ['format_version', '${Layout.formatVersion}'],
        ['app_version', appVersion],
      ]),
      WbSheet('Accounts', Layout.accounts),
      WbSheet('Balance updates', Layout.balanceUpdates),
      WbSheet('Gold items', Layout.goldItems),
      WbSheet('Gold prices', Layout.goldPrices),
      WbSheet('Expenses', Layout.expenses),
      WbSheet('Books', Layout.books),
      WbSheet('Folders', Layout.folders),
      WbSheet('Notes', Layout.notes),
      WbSheet('Notes_Content', Layout.notesContent),
      WbSheet('Settings', Layout.settings),
    ]);
    final bytes = await _heavy(() => XlsxCodec.encode(blank));
    final dir = await workDir();
    await dir.create(recursive: true);
    final f = File('${dir.path}/OZONE-template.xlsx');
    await f.writeAsBytes(bytes, flush: true);
    return BuiltExport(f, 'OZONE-template.xlsx', const {});
  }
}
