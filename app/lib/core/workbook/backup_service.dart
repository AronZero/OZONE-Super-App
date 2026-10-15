import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';

import '../app_info.dart';
import '../data/database.dart';
import '../domain/dates.dart';
import '../domain/ids.dart';
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

/// Export, safety exports and import (docs/spec/F1-03).
class BackupService {
  BackupService(this._db, {required this.workDir, required this.safetyDir, HeavyRunner? heavy, int Function()? clock})
      : _heavy = heavy ?? _isolate,
        _clock = clock ?? (() => DateTime.now().toUtc().millisecondsSinceEpoch);

  final AppDatabase _db;

  /// Temporary exports (app cache).
  final Future<Directory> Function() workDir;

  /// Safety exports (app-private, F2-03 §2).
  final Future<Directory> Function() safetyDir;
  final HeavyRunner _heavy;
  final int Function() _clock;

  /// Files over this size can't be OZONE workbooks at this scale (F1-03 §4).
  static const maxBytes = 25 * 1024 * 1024;

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// `OZONE-YYYY-MM-DD.xlsx` (local date, F1-02 §1).
  static String exportName(DateTime local) => 'OZONE-${local.year}-${_two(local.month)}-${_two(local.day)}.xlsx';

  /// `OZONE-safety-YYYY-MM-DD-HHmm.xlsx`.
  static String safetyName(DateTime local) =>
      'OZONE-safety-${local.year}-${_two(local.month)}-${_two(local.day)}-${_two(local.hour)}${_two(local.minute)}.xlsx';

  /// Steps 1–3 of F1-03 §1: a consistent snapshot, built off the UI thread,
  /// written to a temporary name and then moved into place.
  Future<BuiltExport> build({void Function(ExportStep)? onStep, bool Function()? cancelled, String? name}) async {
    final book = await buildWorkbook(_db, appVersion: appVersion, onStep: onStep, cancelled: cancelled);
    if (cancelled?.call() ?? false) throw const ExportCancelled();
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
    await tmp.writeAsBytes(bytes, flush: true);
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
      target = File('${dir.path}/${e.name.replaceFirst('.xlsx', '-$i.xlsx')}');
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
    return [for (final f in dir.listSync().whereType<File>()) if (f.path.endsWith('.xlsx')) f]
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

  /// Steps 5–6: the safety export first (an import never starts without it),
  /// then everything in one transaction. Returns the safety file and rows written.
  Future<(File?, Map<String, int>)> apply(ImportPlan plan, {bool restore = false}) async {
    // A restore onto an empty phone has nothing to protect.
    final safety = restore ? null : await safetyExport();
    final written = await applyImport(_db, plan);
    return (safety, written);
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
