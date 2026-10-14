import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the Material theme for one brightness from the OZONE tokens.
/// The shell is neutral (ink buttons); tools apply their own tint locally.
ThemeData buildOzoneTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? OzoneColors.dark : OzoneColors.light;
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
    extensions: [OzoneThemeColors(c)],
  );
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
