import 'package:flutter/services.dart';

import 'external_activity.dart';

/// "Save to" for exports (FilesChannel.kt, docs/spec/F2-03 §2).
abstract final class FilesChannel {
  static const _channel = MethodChannel('ozone/files');

  /// Opens the system save dialog for the file at [path], suggesting [name].
  /// Returns the saved file's name, or null when cancelled. Throws
  /// [PlatformException] when the file couldn't be written.
  static Future<String?> saveAs(String path, String name) =>
      ExternalActivity.run(() => _channel.invokeMethod<String>('saveAs', {'path': path, 'name': name}));
}
