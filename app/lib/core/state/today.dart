import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dates.dart';

/// "Today" for every screen (docs/spec/F1-04 §7): the phone's local date,
/// refreshed at midnight while open and when the app returns to the foreground.
class TodayNotifier extends Notifier<LocalDate> {
  Timer? _midnight;

  @override
  LocalDate build() {
    ref.onDispose(() => _midnight?.cancel());
    _schedule();
    return LocalDate.today();
  }

  /// Called when OZONE comes back to the foreground.
  void refresh() {
    final now = LocalDate.today();
    if (now != state) state = now;
    _schedule();
  }

  void _schedule() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), refresh);
  }
}

final todayProvider = NotifierProvider<TodayNotifier, LocalDate>(TodayNotifier.new);

/// A fixed "today" for tests and screenshots.
class FixedToday extends TodayNotifier {
  FixedToday(this.date);
  final LocalDate date;

  @override
  LocalDate build() => date;

  @override
  void refresh() {}
}
