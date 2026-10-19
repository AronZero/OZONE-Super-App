import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';

import '../data/photo_store.dart';

/// The backup `.zip` (docs/spec/F4-01 §5): the workbook at the root plus
/// `photos/<uuid>.jpg`. Entries are stored, not compressed (JPEGs don't shrink).
/// Both functions are synchronous so they can run in a background isolate.
abstract final class BackupZip {
  /// Limits from F4-01 §6.
  static const maxWorkbook = 25 * 1024 * 1024;
  static const maxPhoto = 4 * 1024 * 1024;
  static const maxTotal = 800 * 1024 * 1024;
  static const maxEntries = 5001;

  /// A compressed entry may not grow more than this much (a "zip bomb" guard;
  /// JPEGs and workbooks shrink far less than this).
  static const maxRatio = 100;

  /// Writes the zip at [outPath]: [workbookName] with [workbook], then each
  /// (name, path) photo.
  static void write(String outPath, String workbookName, Uint8List workbook, List<(String, String)> photos) {
    final enc = ZipFileEncoder()..create(outPath, level: ZipFileEncoder.STORE);
    try {
      enc.addArchiveFile(ArchiveFile(workbookName, workbook.length, workbook)..compress = false);
      for (final (name, path) in photos) {
        final input = InputFileStream(path);
        try {
          enc.addArchiveFile(ArchiveFile.stream('photos/$name', File(path).lengthSync(), input)..compress = false);
        } finally {
          input.closeSync();
        }
      }
    } finally {
      enc.closeSync();
    }
  }

  /// What the file at [path] is, by its content rather than its name: a
  /// workbook (an `.xlsx` is a zip too), a backup zip, or neither.
  static FileKind kind(String path) {
    final input = InputFileStream(path);
    try {
      final d = ZipDirectory.read(input);
      return d.fileHeaders.any((h) => h.filename == '[Content_Types].xml') ? FileKind.workbook : FileKind.backup;
    } on Object {
      return FileKind.other;
    } finally {
      input.closeSync();
    }
  }

  /// Unpacks the backup at [zipPath]: returns the workbook's bytes and writes
  /// the photos to `[outDir]/photos/`. Photos that are too big or aren't JPEGs
  /// are left out (they count as missing). Throws [BackupZipRefused] with a
  /// message for the person when the file can't be a safe OZONE backup.
  static UnpackedZip unpack(String zipPath, String outDir) {
    final input = InputFileStream(zipPath);
    try {
      final ZipDirectory dir;
      try {
        dir = ZipDirectory.read(input);
      } on Object {
        throw const BackupZipRefused('This file can’t be opened as an OZONE backup (.zip).');
      }
      final headers = dir.fileHeaders;
      if (headers.length > maxEntries) throw const BackupZipRefused('This backup has too many files in it to be from OZONE.');
      var total = 0;
      ZipFile? workbook;
      var workbooks = 0;
      final photos = <ZipFile>[];
      for (final h in headers) {
        final zf = h.file!;
        final name = zf.filename;
        if (_unsafe(name)) throw const BackupZipRefused('This backup file is damaged.');
        final size = zf.uncompressedSize ?? 0;
        total += size;
        if (total > maxTotal) throw const BackupZipRefused('This backup is over 800 MB, so it can’t be from OZONE.');
        final compressed = zf.compressedSize ?? 0;
        if (zf.compressionMethod != ZipFile.zipCompressionStore && size > (compressed + 1) * maxRatio) {
          throw const BackupZipRefused('This backup file is damaged.');
        }
        if (!name.contains('/') && name.toLowerCase().endsWith('.xlsx')) {
          workbooks++;
          workbook = zf;
        } else if (name.startsWith('photos/') && PhotoStore.namePattern.hasMatch(name.substring(7))) {
          photos.add(zf);
        }
        // Anything else is ignored (F4-01 §6).
      }
      if (workbooks != 1 || workbook == null) {
        throw const BackupZipRefused('This isn’t an OZONE backup. It should hold one workbook (.xlsx).');
      }
      if ((workbook.uncompressedSize ?? 0) > maxWorkbook) throw const BackupZipRefused('The workbook in this backup is over 25 MB.');
      final book = _bytes(workbook);
      if (book.length > maxWorkbook) throw const BackupZipRefused('The workbook in this backup is over 25 MB.');

      final folder = Directory('$outDir/photos')..createSync(recursive: true);
      final ok = <String>{};
      for (final zf in photos) {
        final name = zf.filename.substring(7);
        if ((zf.uncompressedSize ?? 0) > maxPhoto) continue;
        final bytes = _bytes(zf);
        if (bytes.length > maxPhoto || bytes.length < 3 || bytes[0] != 0xFF || bytes[1] != 0xD8 || bytes[2] != 0xFF) continue;
        File('${folder.path}/$name').writeAsBytesSync(bytes, flush: true);
        ok.add(name);
      }
      return UnpackedZip(book, ok, folder.path);
    } finally {
      input.closeSync();
    }
  }

  static List<int> _bytes(ZipFile zf) {
    final c = zf.content;
    return c is Uint8List ? c : Uint8List.fromList(c);
  }

  /// Names that could reach outside the unpack folder.
  static bool _unsafe(String name) =>
      name.contains('..') || name.startsWith('/') || name.contains('\\') || RegExp(r'^[A-Za-z]:').hasMatch(name) || name.contains('\u0000');
}

enum FileKind { workbook, backup, other }

class UnpackedZip {
  const UnpackedZip(this.workbook, this.photos, this.photoDir);
  final List<int> workbook;

  /// Photo names that unpacked as real JPEGs.
  final Set<String> photos;

  /// Where they are (`<outDir>/photos`).
  final String photoDir;
}

class BackupZipRefused implements Exception {
  const BackupZipRefused(this.message);
  final String message;
}
