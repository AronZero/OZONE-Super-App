import 'dart:convert';

import 'database.dart';

/// A typed setting with its default (docs/spec/F1-01 §4). Values are stored as
/// JSON text in the `settings` table; a missing or unreadable value falls back
/// to the default, so a damaged row never breaks the app.
class SettingKey<T> {
  const SettingKey(this.key, this.defaultValue, this.decode, {this.inWorkbook = true});

  final String key;
  final T defaultValue;
  final T Function(Object? json) decode;

  /// Whether the workbook carries it (phone-only settings don't).
  final bool inWorkbook;

  T read(String? stored) {
    if (stored == null) return defaultValue;
    try {
      return decode(jsonDecode(stored));
    } on Object {
      return defaultValue;
    }
  }
}

enum ThemeChoice { system, light, dark }

/// One dashboard widget's place and visibility.
class WidgetSetting {
  const WidgetSetting(this.id, this.on);
  final String id;
  final bool on;

  Map<String, Object> toJson() => {'id': id, 'on': on};
}

class AppLockSetting {
  const AppLockSetting({required this.on, required this.relockAfterS});
  final bool on;

  /// 0, 60 or 300 (owner decision: default 60).
  final int relockAfterS;

  AppLockSetting copyWith({bool? on, int? relockAfterS}) =>
      AppLockSetting(on: on ?? this.on, relockAfterS: relockAfterS ?? this.relockAfterS);

  Map<String, Object> toJson() => {'on': on, 'relock_after_s': relockAfterS};
}

/// Default dashboard order and visibility (docs/04, widgets W1–W10).
const List<WidgetSetting> defaultDashboard = [
  WidgetSetting('needs_attention', true),
  WidgetSetting('total_savings', true),
  WidgetSetting('savings_trend', true),
  WidgetSetting('gold_holdings', true),
  WidgetSetting('spending_this_year', true),
  WidgetSetting('recent_expenses', false),
  WidgetSetting('currently_reading', true),
  WidgetSetting('library_snapshot', false),
  WidgetSetting('pinned_notes', true),
  WidgetSetting('recent_notes', false),
];

abstract final class SettingKeys {
  static final theme = SettingKey<ThemeChoice>(
    'theme',
    ThemeChoice.system,
    (j) => ThemeChoice.values.byName(j! as String),
  );

  static final hideAmountsOnOpen = SettingKey<bool>('amounts.hide_on_open', false, (j) => j! as bool);

  static final dashboardWidgets = SettingKey<List<WidgetSetting>>(
    'dashboard.widgets',
    defaultDashboard,
    (j) => _mergeDashboard([
      for (final e in (j! as List<Object?>).cast<Map<String, Object?>>())
        WidgetSetting(e['id']! as String, e['on']! as bool),
    ]),
  );

  static final barTools = SettingKey<List<String>>(
    'bar.tools',
    const ['finance', 'library', 'notes'],
    (j) => [for (final e in j! as List<Object?>) e! as String].take(3).toList(),
  );

  /// Gold prices older than this are flagged in Needs attention (F1-04 §3).
  static final goldStaleDays = SettingKey<int>('gold.stale_days', 30, (j) => (j! as int).clamp(1, 365));

  /// Values hidden from suggestions in Settings › Lists, per list.
  static final listsHidden = SettingKey<Map<String, List<String>>>(
    'lists.hidden',
    const {'vendor': [], 'platform': [], 'type': []},
    (j) => {
      for (final e in (j! as Map<String, Object?>).entries)
        e.key: [for (final v in e.value! as List<Object?>) v! as String],
    },
  );

  static final appLock = SettingKey<AppLockSetting>(
    'app_lock',
    const AppLockSetting(on: false, relockAfterS: 60),
    (j) {
      final m = j! as Map<String, Object?>;
      final s = m['relock_after_s']! as int;
      return AppLockSetting(on: m['on']! as bool, relockAfterS: const [0, 60, 300].contains(s) ? s : 60);
    },
    inWorkbook: false,
  );
}

/// Keeps known widgets in the saved order, drops unknown ones, and appends
/// any widget the saved list doesn't know yet (new tools start hidden).
List<WidgetSetting> _mergeDashboard(List<WidgetSetting> saved) {
  final known = {for (final w in defaultDashboard) w.id};
  final out = [for (final w in saved) if (known.contains(w.id)) w];
  final seen = {for (final w in out) w.id};
  out.addAll([for (final w in defaultDashboard) if (!seen.contains(w.id)) WidgetSetting(w.id, false)]);
  return out;
}

/// Reads and writes settings. Streams update the UI whenever a value changes.
class SettingsRepo {
  SettingsRepo(this._db);

  final AppDatabase _db;

  Future<T> get<T>(SettingKey<T> k) async {
    final row = await (_db.select(_db.settings)..where((s) => s.key.equals(k.key))).getSingleOrNull();
    return k.read(row?.value);
  }

  Stream<T> watch<T>(SettingKey<T> k) => (_db.select(_db.settings)..where((s) => s.key.equals(k.key)))
      .watchSingleOrNull()
      .map((row) => k.read(row?.value));

  Future<void> set<T>(SettingKey<T> k, T value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(SettingsCompanion.insert(
          key: k.key,
          value: jsonEncode(_encode(value)),
          updatedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        ));
  }

  /// Removes a stored value so the default applies again.
  Future<void> reset<T>(SettingKey<T> k) =>
      (_db.delete(_db.settings)..where((s) => s.key.equals(k.key))).go();

  static Object? _encode(Object? v) => switch (v) {
        final ThemeChoice t => t.name,
        final AppLockSetting a => a.toJson(),
        final List<WidgetSetting> l => [for (final w in l) w.toJson()],
        _ => v,
      };
}
