import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../motion.dart';
import 'tokens.dart';

/// Builds the Material theme for one brightness from the OZONE tokens.
/// The shell is neutral (ink buttons); tools apply their own tint locally.
ThemeData buildOzoneTheme(Brightness brightness, {bool mono = false}) {
  final c = OzoneColors.resolve(brightness, mono: mono);
  final text = _textTheme(c.ink);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: c.canvas,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.ink,
      onPrimary: c.canvas,
      secondary: c.inkMuted,
      onSecondary: c.canvas,
      error: c.danger,
      onError: c.canvas,
      surface: c.surface,
      onSurface: c.ink,
      outline: c.outline,
    ),
    textTheme: text,
    // Icons are outline by default; active and selected states pass fill: 1 (OzIcons).
    iconTheme: IconThemeData(color: c.ink, fill: 0, weight: 400, grade: 0, opticalSize: 24),
    // Pushed screens fade in and rise, like switching tabs (Reduce motion: instant).
    // iOS keeps its own transition so swipe-back still works.
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeRisePageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    extensions: [OzoneThemeColors(c)],
  );
}

/// A tool's colours for the current theme. In Monochrome every accent is ink,
/// a [cardOf] is a plain surface card, a [tileOf] (chips, avatars, small
/// buttons) is the sunken grey, and a selected state is solid ink.
extension ToolTintOf on ToolTint {
  Color accentOf(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return c.mono ? c.ink : accent(Theme.of(context).brightness);
  }

  Color tileOf(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return c.mono ? c.surfaceSunken : tile(Theme.of(context).brightness);
  }

  /// A card on the screen background (Radii.card containers, dashboard widgets).
  Color cardOf(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return c.mono ? c.surface : tile(Theme.of(context).brightness);
  }

  /// Fill and text of a selected tab or segment that is tinted in colour.
  (Color, Color) selectedOf(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final b = Theme.of(context).brightness;
    return c.mono ? (c.ink, c.onAccent) : (tile(b), accent(b));
  }
}

/// Gives widgets access to the full token set: `OzoneThemeColors.of(context)`.
class OzoneThemeColors extends ThemeExtension<OzoneThemeColors> {
  const OzoneThemeColors(this.colors);

  final OzoneColors colors;

  static OzoneColors of(BuildContext context) =>
      Theme.of(context).extension<OzoneThemeColors>()!.colors;

  @override
  OzoneThemeColors copyWith({OzoneColors? colors}) =>
      OzoneThemeColors(colors ?? this.colors);

  @override
  OzoneThemeColors lerp(OzoneThemeColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

// Manrope ships as one variable font, so each weight also sets the 'wght' axis.
TextStyle _style(double size, double height, int weight, Color color) => TextStyle(
      fontFamily: 'Manrope',
      fontSize: size,
      height: height / size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation('wght', weight.toDouble())],
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// Type scale from docs/05 mapped onto Material roles.
TextTheme _textTheme(Color ink) => TextTheme(
      displaySmall: _style(34, 40, 800, ink), // amount-xl
      headlineMedium: _style(28, 34, 800, ink), // title-xl
      headlineSmall: _style(24, 30, 800, ink), // amount-l
      titleLarge: _style(20, 26, 800, ink), // section
      titleMedium: _style(16, 22, 700, ink), // title
      bodyLarge: _style(15, 22, 500, ink), // body
      bodyMedium: _style(13, 18, 600, ink), // body-s
      labelLarge: _style(12, 16, 700, ink), // label
      labelSmall: _style(11.5, 14, 600, ink), // caption
    );
