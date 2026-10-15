import 'package:flutter/material.dart';

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

  /// Slight overshoot: the bar pill and its label.
  static const Curve springy = Cubic(0.3, 1.32, 0.5, 1);

  /// Fast start, soft landing: screens, hide on scroll.
  static const Curve settle = Cubic(0.2, 0.8, 0.2, 1);

  /// How far a new screen rises while it fades in.
  static const double rise = 10;
}

/// Shrinks its child slightly while pressed (buttons, bar items).
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.92});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  var _down = false;

  void _set(bool v) {
    if (v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Motion.of(context).press,
        curve: Curves.easeOut,
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
