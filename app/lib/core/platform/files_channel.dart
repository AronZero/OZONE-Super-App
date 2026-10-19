import 'package:flutter/services.dart';

import 'external_activity.dart';

/// "Save to" for exports (FilesChannel.kt, docs/spec/F2-03 §2).
abstract final class FilesChannel {
  static const _channel = MethodChannel('ozone/files');

  /// Opens the system save dialog for the file at [path], suggesting [name].
  /// Returns the saved file's name, or null when cancelled. Throws
  /// [PlatformException] when the file couldn't be written.
  static Future<String?> saveAs(String path, String name, {String? mime}) =>
      ExternalActivity.run(() => _channel.invokeMethod<String>('saveAs', {'path': path, 'name': name, 'mime': ?mime}));

  /// Recipe photos (F4-01 §3): the picture at [from] as a JPEG at [to], longest
  /// side at most [maxSide] px, turned upright. Throws [PlatformException] when
  /// it isn't a picture the phone can read.
  static Future<void> toJpeg(String from, String to, {required int maxSide, required int quality}) =>
      _channel.invokeMethod<void>('toJpeg', {'from': from, 'to': to, 'maxSide': maxSide, 'quality': quality});
}
