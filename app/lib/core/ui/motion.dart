import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/components.dart';

/// Motion tokens (UI refresh, canvas board "Bottom bar & icons spec").
/// Every animation reads its duration through [Motion.of], which returns
/// zero when the phone's Reduce motion / Remove animations setting is on.
class Motion {
  const Motion._(this._off);

  final bool _off;

  static Motion of(BuildContext context) => Motion._(MediaQuery.disableAnimationsOf(context));

  bool get off => _off;

  Duration _d(int ms) => _off ? Duration.zero : Duration(milliseconds: ms);

  /// Press feedback (scale down while held).
  Duration get press => _d(120);

  /// Icon outline → solid.
  Duration get fill => _d(240);

  /// Screen change: fade in and rise.
  Duration get screen => _d(260);

  /// Bar and add button hiding or returning on scroll.
  Duration get hide => _d(280);

  /// Bar label growing in or out.
  Duration get label => _d(300);

  /// Bar pill sliding to the tapped item.
  Duration get pill => _d(340);

  /// Icon pop on becoming active.
  Duration get pop => _d(380);

  /// Tab pill sliding, chips cross-fading their colour (step 3).
  Duration get tabs => _d(300);

  /// Quick add opening: + turns into ×, the menu grows out of the button.
  Duration get quickAdd => _d(260);

  /// Sheets gliding up.
  Duration get sheet => _d(320);

  /// Sheets glide up with a soft landing while the background dims (moment 10).
  AnimationStyle get sheetStyle => _off
      ? AnimationStyle.noAnimation
      : AnimationStyle(duration: sheet, curve: settle, reverseDuration: const Duration(milliseconds: 220), reverseCurve: Curves.easeIn);

  /// Bars growing in: each bar 420 ms, the next one 20 ms later.
  Duration get chart => _d(420);

  /// Slight overshoot: the bar pill and its label.
  static const Curve springy = Cubic(0.3, 1.32, 0.5, 1);

  /// Fast start, soft landing: screens, hide on scroll.
  static const Curve settle = Cubic(0.2, 0.8, 0.2, 1);

  /// How far a new screen rises while it fades in.
  static const double rise = 10;
}

/// Shrinks its child while pressed, then springs back on release: cards and
/// rows to 97 %, buttons to 94 %, bar items to 92 %. Never takes the tap
/// itself, and lets go as soon as the finger starts scrolling.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.92});

  static const double card = 0.97;
  static const double button = 0.94;

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  var _down = false;
  Offset? _start;

  void _set(bool v) {
    if (v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final m = Motion.of(context);
    return Listener(
      onPointerDown: (e) {
        _start = e.position;
        _set(true);
      },
      onPointerMove: (e) {
        if (_start != null && (e.position - _start!).distance > kTouchSlop) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !m.off ? widget.scale : 1,
        duration: m.press,
        curve: _down ? Curves.easeOut : Motion.springy,
        child: widget.child,
      ),
    );
  }
}

/// Pushed screens fade in and rise (the same move as switching tabs).
class FadeRisePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeRisePageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 260);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.of(context).off) return child;
    return FadeRise(animation: animation, child: child);
  }
}

/// Fades [child] in and lifts it [Motion.rise] dp as [animation] runs 0 → 1.
class FadeRise extends StatelessWidget {
  const FadeRise({super.key, required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Always the same widget shape, so the child keeps its state when the animation ends.
        final v = animation.value.clamp(0.0, 1.0);
        final t = (animation.status == AnimationStatus.reverse ? Curves.easeIn : Motion.settle).transform(v);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, Motion.rise * (1 - t)), child: child),
        );
      },
      child: child,
    );
  }
}

/// Step 3 micro-interactions (canvas board "UI refresh · Step 3 · Motion").
class Stagger {
  Stagger._();

  /// One card's rise and fade.
  static const Duration item = Duration(milliseconds: 360);

  /// Gap between neighbouring cards.
  static const Duration step = Duration(milliseconds: 40);

  /// Only the first cards rise in; the rest are simply there.
  static const int max = 6;

  /// How far a card rises.
  static const double rise = 12;
}

/// Tells the cards of the screens below it that a screen opened again
/// (the shell bumps it on every tab change), so they rise in once more.
class EntranceScope extends InheritedNotifier<ValueNotifier<int>> {
  const EntranceScope({super.key, required ValueNotifier<int> opens, required super.child}) : super(notifier: opens);

  static int of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<EntranceScope>()?.notifier?.value ?? 0;
}

/// Wraps the first [Stagger.max] cards of [children] (spacers and top bars
/// skipped) so they rise [Stagger.rise] dp and fade in, [Stagger.step] apart,
/// each time the screen opens.
List<Widget> staggered(List<Widget> children) {
  var i = 0;
  return [
    for (final w in children)
      if (w is SizedBox || w is MainTopBar || w is DetailTopBar || i >= Stagger.max) w else EnterItem(index: i++, child: w),
  ];
}

/// One card of [staggered].
class EnterItem extends StatefulWidget {
  const EnterItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<EnterItem> createState() => _EnterItemState();
}

class _EnterItemState extends State<EnterItem> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this);
  int? _opens;

  Duration get _delay => Stagger.step * widget.index;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final opens = EntranceScope.of(context);
    if (opens == _opens) return;
    _opens = opens;
    if (Motion.of(context).off) {
      _c.value = 1;
      return;
    }
    _c.duration = Stagger.item + _delay;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = (Stagger.item + _delay).inMicroseconds;
    final curve = Interval(_delay.inMicroseconds / total, 1, curve: Motion.settle);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = curve.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, Stagger.rise * (1 - t)), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// How [PopOnChange] moves.
enum Pop {
  /// Icons (eye, pin, star): dips to 80 %, overshoots to 118 %, settles. 380 ms.
  icon,

  /// Change badges: fades in from 60 %, overshoots to 108 %, settles. 320 ms.
  badge,
}

/// Pops [child] each time [value] changes (not when it first appears).
class PopOnChange extends StatefulWidget {
  const PopOnChange({super.key, required this.value, required this.child, this.pop = Pop.icon, this.delay = Duration.zero});

  final Object? value;
  final Widget child;
  final Pop pop;

  /// Stars pop one after another, 40 ms apart.
  final Duration delay;

  @override
  State<PopOnChange> createState() => _PopOnChangeState();
}

class _PopOnChangeState extends State<PopOnChange> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, value: 1);

  static final _iconScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0.8).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.18).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    TweenSequenceItem(tween: Tween<double>(begin: 1.18, end: 1).chain(CurveTween(curve: Curves.easeInOut)), weight: 25),
  ]);

  static final _badgeScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 0.6, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 70),
    TweenSequenceItem(tween: Tween<double>(begin: 1.08, end: 1).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
  ]);

  @override
  void didUpdateWidget(PopOnChange old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value || Motion.of(context).off) return;
    final run = widget.pop == Pop.icon ? 380 : 320;
    final lead = widget.delay.inMilliseconds;
    _c.duration = Duration(milliseconds: run + lead);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Always the same widget shape, so a stateful child keeps its state.
        if (_c.value >= 1) return Opacity(opacity: 1, child: Transform.scale(scale: 1, child: child));
        final total = _c.duration!.inMicroseconds;
        final lead = widget.delay.inMicroseconds / total;
        final t = ((_c.value - lead) / (1 - lead)).clamp(0.0, 1.0);
        if (widget.pop == Pop.icon) return Opacity(opacity: 1, child: Transform.scale(scale: _iconScale.transform(t), child: child));
        return Opacity(
          opacity: (t / 0.7).clamp(0.0, 1.0),
          child: Transform.scale(scale: _badgeScale.transform(t), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Delete and Undo in lists (board moment 8). Give each row a key and build
/// the list in [builder]: a row that goes slides away and the gap closes; a
/// row that comes back (Undo) or is added grows in the same way. Rows without
/// a key (headers, spacers) are left alone. A new [scope] (another filter,
/// sort or year) just swaps the rows, and so does any change of more than
/// [maxMoves] rows.
class AnimatedRows extends StatefulWidget {
  const AnimatedRows({super.key, required this.children, required this.builder, this.scope});

  final List<Widget> children;
  final Widget Function(List<Widget> children) builder;

  /// What the list is showing (filter, sort…). Rows only move while it stays the same.
  final Object? scope;

  static const int maxMoves = 3;

  /// Slide away, then the gap closes.
  static const Duration leave = Duration(milliseconds: 220 + 120);

  /// The gap opens, then the row slides in.
  static const Duration arrive = Duration(milliseconds: 260);

  @override
  State<AnimatedRows> createState() => _AnimatedRowsState();
}

class _AnimatedRowsState extends State<AnimatedRows> {
  /// Keyed rows of the last build, in order.
  List<Widget> _last = const [];
  bool _first = true;
  Object? _scope;

  /// Rows on their way out, with the key of the row they followed.
  final _leaving = <Key, (Widget, Key?)>{};

  @override
  void didUpdateWidget(AnimatedRows old) {
    super.didUpdateWidget(old);
    _first = false;
  }

  @override
  Widget build(BuildContext context) {
    final off = Motion.of(context).off;
    final now = [for (final w in widget.children) if (w.key != null) w];
    final nowKeys = {for (final w in now) w.key!};
    final lastKeys = {for (final w in _last) w.key!};
    final added = _first ? const <Key>{} : nowKeys.difference(lastKeys);
    final gone = [for (final w in _last) if (!nowKeys.contains(w.key)) w];
    final sameScope = widget.scope == _scope;
    _scope = widget.scope;
    final calm = !off && sameScope && added.length + gone.length <= AnimatedRows.maxMoves;
    if (!calm) {
      _leaving.clear();
    } else {
      for (final w in gone) {
        final i = _last.indexOf(w);
        Key? after;
        for (var j = i - 1; j >= 0; j--) {
          if (nowKeys.contains(_last[j].key)) {
            after = _last[j].key;
            break;
          }
        }
        _leaving[w.key!] = (w, after);
      }
    }
    _leaving.removeWhere((k, _) => nowKeys.contains(k));
    _last = now;

    Widget leaving(Key k, Widget w) => _RowMotion(
          key: k,
          leaving: true,
          onGone: () {
            if (mounted) setState(() => _leaving.remove(k));
          },
          child: w,
        );
    final out = <Widget>[];
    // Rows that followed nothing still on screen go before the first row.
    var leadDone = false;
    void lead() {
      if (leadDone) return;
      leadDone = true;
      for (final e in _leaving.entries) {
        if (e.value.$2 == null) out.add(leaving(e.key, e.value.$1));
      }
    }

    for (final w in widget.children) {
      final k = w.key;
      if (k == null) {
        out.add(w);
        continue;
      }
      lead();
      out.add(_RowMotion(key: k, arriving: calm && added.contains(k), child: w));
      for (final e in _leaving.entries) {
        if (e.value.$2 == k) out.add(leaving(e.key, e.value.$1));
      }
    }
    lead();
    return widget.builder(out);
  }
}

class _RowMotion extends StatefulWidget {
  const _RowMotion({super.key, required this.child, this.arriving = false, this.leaving = false, this.onGone});

  final Widget child;
  final bool arriving;
  final bool leaving;
  final VoidCallback? onGone;

  @override
  State<_RowMotion> createState() => _RowMotionState();
}

class _RowMotionState extends State<_RowMotion> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, value: 1);

  @override
  void initState() {
    super.initState();
    _start(leave: widget.leaving, arrive: widget.arriving);
  }

  // A list may keep a row's element for its leaving (or returning) copy.
  @override
  void didUpdateWidget(_RowMotion old) {
    super.didUpdateWidget(old);
    _start(leave: widget.leaving && !old.leaving, arrive: widget.arriving && !old.arriving || old.leaving && !widget.leaving);
  }

  void _start({required bool leave, required bool arrive}) {
    if (leave) {
      _c.duration = AnimatedRows.leave;
      _c.reverse(from: _c.value).whenComplete(() {
        if (mounted && widget.leaving) widget.onGone?.call();
      });
    } else if (arrive) {
      _c.duration = AnimatedRows.arrive;
      _c.forward(from: _c.value < 1 ? _c.value : 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Leaving runs 1 → 0: the row slides away first, then the gap closes.
    // Arriving runs 0 → 1: the gap opens first, then the row slides in.
    final slide = CurvedAnimation(parent: _c, curve: const Interval(0.35, 1, curve: Motion.settle));
    final size = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6, curve: Motion.settle));
    return IgnorePointer(
      ignoring: widget.leaving,
      child: SizeTransition(
        sizeFactor: size,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: slide,
          child: AnimatedBuilder(
            animation: slide,
            builder: (context, child) => Transform.translate(offset: Offset(-40 * (1 - slide.value), 0), child: child),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// The light haptics of step 3 (decision UR3, answer A3).
abstract final class Haptics {
  /// Tab change (the bar, segmented tabs).
  static void tab() => unawaited(HapticFeedback.selectionClick());

  /// Toggles: pin, switches, stars.
  static void toggle() => unawaited(HapticFeedback.lightImpact());

  /// A finished job: export, import, vault set up.
  static void done() => unawaited(HapticFeedback.lightImpact());
}

/// An icon whose fill animates outline ↔ solid and pops when it changes
/// (pin, stars; board moment 9). [delay] staggers neighbours (stars 40 ms).
class FillIcon extends StatelessWidget {
  const FillIcon(this.icon, {super.key, required this.filled, this.size, this.color, this.semanticLabel, this.popWhen, this.delay = Duration.zero});

  final IconData icon;
  final bool filled;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  /// Pops when this changes (by default when [filled] does).
  final Object? popWhen;
  final Duration delay;

  @override
  Widget build(BuildContext context) => PopOnChange(
        value: popWhen ?? filled,
        delay: delay,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: filled ? 1 : 0),
          duration: Motion.of(context).fill,
          curve: Curves.easeOut,
          builder: (context, fill, _) => Icon(icon, fill: fill, size: size, color: color, semanticLabel: semanticLabel),
        ),
      );
}

/// "Done" for finished jobs (board moment 11): the circle pops in, then the
/// tick draws itself, with one light haptic.
class DoneTick extends StatefulWidget {
  const DoneTick({super.key, required this.background, required this.foreground, this.size = 60});

  final Color background;
  final Color foreground;
  final double size;

  @override
  State<DoneTick> createState() => _DoneTickState();
}

class _DoneTickState extends State<DoneTick> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 560), value: 1);
  var _started = false;

  static final _ring = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1.1).chain(CurveTween(curve: Curves.easeOut)), weight: 70),
    TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
  ]);

  @override
  void initState() {
    super.initState();
    Haptics.done();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!Motion.of(context).off) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // Circle: first 300 ms. Tick: draws over the last 260 ms.
          final ring = _ring.transform((_c.value / (300 / 560)).clamp(0.0, 1.0));
          final tick = Motion.settle.transform(((_c.value - 300 / 560) / (260 / 560)).clamp(0.0, 1.0));
          return SizedBox.square(
            dimension: widget.size,
            child: Transform.scale(
              scale: ring,
              child: DecoratedBox(
                decoration: BoxDecoration(color: widget.background, shape: BoxShape.circle),
                child: CustomPaint(painter: _TickPainter(progress: tick, color: widget.foreground)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.29, w * 0.52)
      ..lineTo(w * 0.44, w * 0.66)
      ..lineTo(w * 0.72, w * 0.37);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.075
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress || old.color != color;
}
