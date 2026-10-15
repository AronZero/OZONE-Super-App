import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/error_log.dart';
import '../../state/providers.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'components.dart';
import 'forms.dart';

/// Loading, error and failed-save patterns of the W3 States board (docs/04 › States).

/// A screen's data: a skeleton only after 300 ms, the error pattern with
/// Try again, or the content.
class AsyncBody<T> extends ConsumerWidget {
  const AsyncBody({super.key, required this.value, required this.what, required this.onRetry, required this.builder, this.padding});

  final AsyncValue<T> value;

  /// "Savings", "Gold"… for "Savings couldn't be loaded".
  final String what;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A reload after an error keeps showing the error until it succeeds.
    if (value.hasValue) return builder(value.requireValue);
    if (value.hasError) {
      return Padding(
        padding: padding ?? const EdgeInsets.all(Space.screen),
        child: LoadError(what: what, error: value.error!, stack: value.stackTrace, onRetry: onRetry),
      );
    }
    return Padding(padding: padding ?? const EdgeInsets.all(Space.screen), child: const DelayedSkeleton());
  }
}

/// Grey placeholder rows, shown only once loading passes [delay] (docs/04).
class DelayedSkeleton extends StatefulWidget {
  const DelayedSkeleton({super.key, this.rows = 4, this.delay = const Duration(milliseconds: 300)});

  final int rows;
  final Duration delay;

  @override
  State<DelayedSkeleton> createState() => _DelayedSkeletonState();
}

class _DelayedSkeletonState extends State<DelayedSkeleton> {
  Timer? _timer;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final c = OzoneThemeColors.of(context);
    Widget bar(double w, double h) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: w,
      child: Container(
        height: h,
        decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(8)),
      ),
    );
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(Space.l),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  bar(0.35, 12),
                  const SizedBox(height: Space.m),
                  bar(0.6, 28),
                  const SizedBox(height: Space.l),
                  bar(1, 64),
                ],
              ),
            ),
            for (var i = 0; i < widget.rows; i++) ...[
              const SizedBox(height: Space.s),
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.tile)),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [bar(0.55, 12), bar(0.3, 10)]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Savings couldn't be loaded" with Try again. The error goes to the local log once.
class LoadError extends ConsumerStatefulWidget {
  const LoadError({super.key, required this.what, required this.error, this.stack, required this.onRetry});

  final String what;
  final Object error;
  final StackTrace? stack;
  final VoidCallback onRetry;

  @override
  ConsumerState<LoadError> createState() => _LoadErrorState();
}

class _LoadErrorState extends ConsumerState<LoadError> {
  @override
  void initState() {
    super.initState();
    ref.read(errorLogProvider).record(widget.error, widget.stack, where: 'load ${widget.what}');
  }

  @override
  Widget build(BuildContext context) => AttentionBanner(
    title: '${widget.what} couldn’t be loaded',
    body: 'Nothing in OZONE was changed. Try again, or close and reopen OZONE.',
    action: OzoneButton(label: 'Try again', height: 48, onPressed: widget.onRetry),
  );
}

/// Runs a save. If it throws, the form stays open with everything typed, the
/// error goes to the local log, and "Couldn't save" offers Try again (W3 States
/// › Errors). A dialog, so it shows above sheets too. Returns whether the save
/// went through.
Future<bool> guardSave(BuildContext context, ErrorLog log, Future<void> Function() save, {String what = 'save'}) async {
  while (true) {
    try {
      await save();
      return true;
    } on Object catch (e, st) {
      await log.record(e, st, where: what);
      if (!context.mounted) return false;
      final again = await confirmDialog(
        context,
        title: 'Couldn’t save',
        body: 'What you typed is kept. The phone may be out of space; free some up and try again.',
        confirm: 'Try again',
        cancel: 'Not now',
      );
      if (again != true || !context.mounted) return false;
    }
  }
}
