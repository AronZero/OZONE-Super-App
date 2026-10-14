import 'package:flutter/services.dart';

/// OZONE's own small Android bridge (MainActivity.kt). On platforms without it,
/// calls do nothing.
abstract final class OzonePlatform {
  static const _channel = MethodChannel('ozone/platform');

  /// Blocks screenshots and blanks the recent-apps preview while on (F2-01 §6).
  static Future<void> setSecureScreen(bool on) async {
    try {
      await _channel.invokeMethod<void>('setSecure', {'on': on});
    } on MissingPluginException {
      // Tests and unsupported platforms.
    } on PlatformException {
      // Never block the app because of this.
    }
  }

  /// Opens the phone's security settings (to set a screen lock).
  static Future<bool> openSecuritySettings() async {
    try {
      return await _channel.invokeMethod<bool>('openSecuritySettings') ?? false;
    } on Object {
      return false;
    }
  }
}
