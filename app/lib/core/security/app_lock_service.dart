import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';

import '../data/settings_repo.dart';
import 'secure_screen.dart';

/// Talks to the phone's screen lock. A seam so tests can fake it.
abstract class DeviceAuth {
  Future<bool> hasScreenLock();

  /// Shows the phone's own prompt (fingerprint, face or phone PIN/password).
  Future<AuthOutcome> authenticate(String reason);
}

enum AuthOutcome { success, cancelled, noScreenLock, failed }

class LocalAuthDeviceAuth implements DeviceAuth {
  final _auth = LocalAuthentication();

  @override
  Future<bool> hasScreenLock() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<AuthOutcome> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // owner decision: the phone password works too
        persistAcrossBackgrounding: true,
      );
      return ok ? AuthOutcome.success : AuthOutcome.cancelled;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.noCredentialsSet => AuthOutcome.noScreenLock,
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout =>
          AuthOutcome.cancelled,
        _ => AuthOutcome.failed,
      };
    } on Object {
      return AuthOutcome.failed;
    }
  }
}

enum EnableResult { enabled, noScreenLock, cancelled }

/// App lock (docs/spec/F2-01 §5): locks on cold start and after the chosen
/// time in the background; unlocks with the phone's own screen lock.
class AppLockService with WidgetsBindingObserver {
  AppLockService(this._settings, this._device, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final SettingsRepo _settings;
  final DeviceAuth _device;
  final DateTime Function() _now;

  /// True while the App lock gate must cover the app.
  final ValueNotifier<bool> locked = ValueNotifier(false);

  AppLockSetting _setting = const AppLockSetting(on: false, relockAfterS: 60);
  AppLockSetting get setting => _setting;

  DateTime? _leftAt;
  bool _authenticating = false;
  StreamSubscription<AppLockSetting>? _sub;

  /// Reads the setting and locks at once if app lock is on (cold start).
  Future<void> start() async {
    _setting = await _settings.get(SettingKeys.appLock);
    locked.value = _setting.on;
    SecureScreen.set(SecureReason.appLock, _setting.on);
    WidgetsBinding.instance.addObserver(this);
    _sub = _settings.watch(SettingKeys.appLock).listen((s) {
      _setting = s;
      if (!s.on) locked.value = false;
      SecureScreen.set(SecureReason.appLock, s.on);
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sub?.cancel());
    locked.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The phone's own unlock screen pauses OZONE; that isn't "leaving".
    if (_authenticating) return;
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _leftAt ??= _now();
      case AppLifecycleState.resumed:
        final left = _leftAt;
        _leftAt = null;
        if (_setting.on && left != null && _now().difference(left).inSeconds >= _setting.relockAfterS) {
          locked.value = true;
        }
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  /// Shows the phone's prompt; unlocks on success.
  Future<AuthOutcome> unlock() async {
    if (_authenticating) return AuthOutcome.cancelled;
    _authenticating = true;
    try {
      final r = await _device.authenticate('Unlock OZONE');
      if (r == AuthOutcome.success) locked.value = false;
      return r;
    } finally {
      _authenticating = false;
      _leftAt = null;
    }
  }

  /// Turns app lock on after confirming with the phone's screen lock.
  Future<EnableResult> enable() async {
    if (!await _device.hasScreenLock()) return EnableResult.noScreenLock;
    _authenticating = true;
    try {
      final r = await _device.authenticate('Confirm to turn on app lock');
      if (r == AuthOutcome.noScreenLock) return EnableResult.noScreenLock;
      if (r != AuthOutcome.success) return EnableResult.cancelled;
      await _settings.set(SettingKeys.appLock, _setting.copyWith(on: true));
      return EnableResult.enabled;
    } finally {
      _authenticating = false;
      _leftAt = null;
    }
  }

  Future<void> disable() => _settings.set(SettingKeys.appLock, _setting.copyWith(on: false));

  Future<void> setRelockAfter(int seconds) =>
      _settings.set(SettingKeys.appLock, _setting.copyWith(relockAfterS: seconds));
}
