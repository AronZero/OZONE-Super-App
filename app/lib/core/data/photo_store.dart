import 'dart:io';

import '../domain/ids.dart';

/// Turns any picture into a JPEG of at most [maxSide] px on its longest side.
/// On the phone this is the files channel (the phone's own encoder, F4-03 §1);
/// tests pass one that copies.
typedef JpegConverter = Future<void> Function(String from, String to, {required int maxSide, required int quality});

/// Recipe photos in app-private storage (docs/spec/F4-01 §3): one folder,
/// files named `<uuid>.jpg`. A changed photo always gets a new name.
class PhotoStore {
  PhotoStore(this._dir, this._convert, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final Future<Directory> Function() _dir;
  final JpegConverter _convert;
  final DateTime Function() _clock;

  static const maxSide = 1600;
  static const quality = 85;

  /// `<uuid>.jpg`, as stored in `recipes.photo_file` and the backup's `photos/` folder.
  static final RegExp namePattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$');

  Future<Directory> folder() async {
    final d = await _dir();
    await d.create(recursive: true);
    return d;
  }

  /// The photo's file (it may not exist, for example after a damaged import).
  Future<File> file(String name) async => File('${(await folder()).path}/$name');

  /// Shrinks the picture at [path] into the store and returns its new name.
  Future<String> adopt(String path) async {
    final name = '${newId()}.jpg';
    final dir = await folder();
    final tmp = '${dir.path}/.$name.part';
    try {
      await _convert(path, tmp, maxSide: maxSide, quality: quality);
      await File(tmp).rename('${dir.path}/$name');
    } on Object {
      final t = File(tmp);
      if (t.existsSync()) t.deleteSync();
      rethrow;
    }
    return name;
  }

  /// Copies a photo that is already a store-sized JPEG (from a backup) under its own name.
  Future<void> put(File source, String name) async {
    assert(namePattern.hasMatch(name));
    final dir = await folder();
    final tmp = File('${dir.path}/.$name.part');
    await source.copy(tmp.path);
    await tmp.rename('${dir.path}/$name');
  }

  Future<bool> has(String name) async => (await file(name)).existsSync();

  Future<void> delete(String name) async {
    if (!namePattern.hasMatch(name)) return;
    final f = await file(name);
    if (f.existsSync()) await f.delete();
  }

  /// Orphan sweep (F4-01 §3): deletes photos no recipe uses that are older than
  /// 10 minutes, so a form that is still open, or a pending Undo, keeps its photo.
  Future<int> sweep(Set<String> inUse) async {
    final dir = await _dir();
    if (!dir.existsSync()) return 0;
    final cutoff = _clock().subtract(const Duration(minutes: 10));
    var n = 0;
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (inUse.contains(name)) continue;
      if (f.lastModifiedSync().isAfter(cutoff)) continue;
      try {
        f.deleteSync();
        n++;
      } on FileSystemException {
        // In use; it goes next time.
      }
    }
    return n;
  }
}
