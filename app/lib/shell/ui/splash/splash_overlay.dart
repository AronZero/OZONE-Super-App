import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ui/motion.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../ozone_mark.dart';

/// True while the splash plays; the App lock gate waits for it before asking
/// the phone's screen lock, so the prompt never covers the animation.
final ValueNotifier<bool> splashActive = ValueNotifier(false);

/// The splash "The Bond" (decision UR4-1, canvas board UR4-Splash). It starts
/// exactly where Android's own splash leaves off (the mark at the system icon's
/// size and place), plays once per fresh start, and fades into whatever is
/// behind it: Home, Welcome or the lock screen, which load meanwhile.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key});

  /// Full run; Reduce motion uses [reducedDuration].
  static const duration = Duration(milliseconds: 1250);
  static const reducedDuration = Duration(milliseconds: 600);

  /// Where Android 12+ draws the splash mark (res/drawable/splash_mark.xml):
  /// its 100-unit box and how far its centre sits above the screen's centre.
  /// Measured on the A03-sized emulator (the spec's 240 dp icon gives 178 dp;
  /// Android draws it about 5% larger).
  static const double systemBox = 185.6;
  static const double systemDy = -7.5;

  /// Where the mark settles: smaller, and raised to make room for the name.
  static const double restBox = 150;
  static const double restRise = 44;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with SingleTickerProviderStateMixin {
  // preserve: Reduce motion would otherwise run it 20× faster; the short version is chosen below.
  late final AnimationController _c = AnimationController(vsync: this, animationBehavior: AnimationBehavior.preserve);
  bool _reduced = false;
  bool _started = false;
  bool _ticked = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    splashActive.value = true;
    _c.addListener(_onTick);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = Motion.of(context).off;
    _c.duration = _reduced ? SplashOverlay.reducedDuration : SplashOverlay.duration;
    unawaited(_c.forward());
  }

  void _onTick() {
    // One light haptic as the core lights up (~750 ms).
    if (!_reduced && !_ticked && _c.value >= 0.6) {
      _ticked = true;
      Haptics.toggle();
    }
  }

  void _finish() {
    if (_done) return;
    setState(() => _done = true);
    splashActive.value = false;
  }

  /// Tap anywhere: straight to the last step.
  void _skip() {
    final exit = _reduced ? 0.55 : 0.86;
    if (_c.value < exit) {
      _ticked = true;
      _c.value = exit;
      unawaited(_c.forward());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    if (!_done) splashActive.value = false;
    super.dispose();
  }

  static double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final c = OzoneThemeColors.of(context);
    final b = Theme.of(context).brightness;
    final dark = b == Brightness.dark;
    // Brand pale in light, as Android's splash; the canvas in dark and in Monochrome.
    final bg = dark || c.mono ? c.canvas : const Color(0xFFE2ECF7);
    return Positioned.fill(
      child: BlockSemantics(
        child: Semantics(
          label: 'OZONE',
          image: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _skip,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => _frame(context, _c.value, bg, b, c.mono),
            ),
          ),
        ),
      ),
    );
  }

  Widget _frame(BuildContext context, double t, Color bg, Brightness b, bool mono) {
    final ease = Curves.easeOutCubic;
    double spread = 0, core = 1, coreScale = 1, rise, word, exit;
    final lenses = [1.0, 1.0, 1.0];
    if (_reduced) {
      rise = 1;
      word = 1;
      exit = Curves.easeIn.transform(_seg(t, 0.55, 1));
    } else {
      // Apart (150–450 ms), back with a small overshoot (450–650), settle (to 750).
      if (t < 0.36) {
        spread = ease.transform(_seg(t, 0.12, 0.36));
      } else if (t < 0.52) {
        spread = 1 - 1.12 * Curves.easeIn.transform(_seg(t, 0.36, 0.52));
      } else {
        spread = -0.12 * (1 - Curves.easeOut.transform(_seg(t, 0.52, 0.60)));
      }
      final out = _seg(t, 0.11, 0.18);
      const back = [0.52, 0.54, 0.56];
      for (var i = 0; i < 3; i++) {
        lenses[i] = t < back[i] ? 1 - out : _seg(t, back[i], back[i] + 0.04);
      }
      if (t < 0.58) {
        core = 1 - out;
        coreScale = 1 - 0.4 * out;
      } else if (t < 0.63) {
        final k = _seg(t, 0.58, 0.63);
        core = k;
        coreScale = 0.6 + 0.54 * Curves.easeOut.transform(k);
      } else {
        coreScale = 1.14 - 0.14 * Curves.easeInOut.transform(_seg(t, 0.63, 0.71));
      }
      rise = ease.transform(_seg(t, 0.60, 0.84));
      word = ease.transform(_seg(t, 0.62, 0.86));
      exit = Curves.easeIn.transform(_seg(t, 0.86, 1));
    }

    final box = SplashOverlay.systemBox + (SplashOverlay.restBox - SplashOverlay.systemBox) * rise;
    final dy = SplashOverlay.systemDy - SplashOverlay.restRise * rise;
    final k = SplashOverlay.restBox / 124; // board px → dp
    final size = MediaQuery.sizeOf(context);
    final markTop = size.height / 2 + dy - box / 2;
    final wordTop = size.height / 2 + SplashOverlay.systemDy - SplashOverlay.restRise + SplashOverlay.restBox / 2 + 18 * k;
    // The wordmark takes the core's colour (brand README: the core is the app).
    final ink = OzoneMarkPainter.coreColor(b, mono: mono);

    return Opacity(
      opacity: 1 - exit,
      child: Transform.scale(
        scale: 1 - 0.04 * exit,
        child: ColoredBox(
          color: bg,
          child: Stack(children: [
            Positioned(
              left: (size.width - box) / 2,
              top: markTop,
              width: box,
              height: box,
              child: CustomPaint(
                painter: OzoneMarkPainter(b, mono: mono, spread: spread, lenses: lenses, core: core, coreScale: coreScale),
              ),
            ),
            if (word > 0)
              Positioned(
                left: 0,
                right: 0,
                top: wordTop + 16 * k * (1 - word),
                child: Opacity(
                  opacity: word,
                  child: Text(
                    'OZONE',
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                      fontSize: 30 * k,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: ink,
                      letterSpacing: 30 * k * (0.14 + 0.28 * (1 - word)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
