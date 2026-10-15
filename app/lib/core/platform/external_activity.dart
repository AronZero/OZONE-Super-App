/// A system screen OZONE opened itself (Save to, the file picker, the share
/// sheet). While one is open, OZONE isn't "leaving": app lock and the vault
/// don't relock when it pauses the app.
abstract final class ExternalActivity {
  static int _open = 0;

  static bool get active => _open > 0;

  static Future<T> run<T>(Future<T> Function() f) async {
    _open++;
    try {
      return await f();
    } finally {
      _open--;
    }
  }
}
