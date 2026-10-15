import 'dart:async';

import '../platform/platform_channel.dart';

/// Why the screen must be secure right now (F2-01 §6).
enum SecureReason {
  /// App lock is on: the whole app, always.
  appLock,

  /// The notes vault is open or a locked note is on screen.
  vault,

  /// A recovery code is on screen.
  recoveryCode,
}

/// `FLAG_SECURE` is on while any reason holds, so one feature turning it off
/// never exposes another's screen.
abstract final class SecureScreen {
  static final Set<SecureReason> _reasons = {};

  static bool get isOn => _reasons.isNotEmpty;

  static void set(SecureReason r, bool on) {
    final before = _reasons.isNotEmpty;
    on ? _reasons.add(r) : _reasons.remove(r);
    if (_reasons.isNotEmpty != before) unawaited(OzonePlatform.setSecureScreen(_reasons.isNotEmpty));
  }
}
