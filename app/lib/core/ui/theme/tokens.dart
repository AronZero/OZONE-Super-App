import 'package:flutter/foundation.dart' show Brightness;
import 'package:flutter/painting.dart';

/// Colour tokens from docs/05-design-system.md. Widgets read these through
/// `OzoneThemeColors.of(context)`; nothing else in the app hard-codes a colour.
class OzoneColors {
  const OzoneColors({
    required this.canvas,
    required this.surface,
    required this.surfaceSunken,
    required this.bar,
    required this.barActive,
    required this.outline,
    required this.ink,
    required this.inkMuted,
    required this.gain,
    required this.loss,
    required this.attentionBg,
    required this.attentionInk,
    required this.danger,
    required this.onAccent,
    this.mono = false,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceSunken;
  final Color bar;
  final Color barActive;
  final Color outline;
  final Color ink;
  final Color inkMuted;
  final Color gain;
  final Color loss;
  final Color attentionBg;
  final Color attentionInk;
  final Color danger;

  /// Text and icons on a tool-accent fill (white in light, canvas in dark).
  final Color onAccent;

  /// Monochrome (UR2): tool colours resolve to greys; only gain/loss/danger/attention keep colour.
  final bool mono;

  /// Fill for badges, buttons and tiles placed on a tool card: white on a tinted
  /// card, the sunken grey on a Monochrome card (which is already surface).
  Color get onCard => mono ? surfaceSunken : surface;

  static const light = OzoneColors(
    canvas: Color(0xFFF3F5F2),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE6EAE5),
    bar: Color(0xFFE9EDE8),
    barActive: Color(0xFFD3DBD5),
    outline: Color(0xFFC9D0CA),
    ink: Color(0xFF15201B),
    inkMuted: Color(0xFF4C5A53),
    gain: Color(0xFF1B6B3E),
    loss: Color(0xFFA3361F),
    attentionBg: Color(0xFFFBE3C6),
    attentionInk: Color(0xFF7E410B),
    danger: Color(0xFFA3361F),
    onAccent: Color(0xFFFFFFFF),
  );

  static const dark = OzoneColors(
    canvas: Color(0xFF0F1412),
    surface: Color(0xFF1A221E),
    surfaceSunken: Color(0xFF1F2925),
    bar: Color(0xFF161D1A),
    barActive: Color(0xFF2E3A34),
    outline: Color(0xFF34413A),
    ink: Color(0xFFE7EEEA),
    inkMuted: Color(0xFFA9B7B0),
    gain: Color(0xFF7FD6A0),
    loss: Color(0xFFF59B85),
    attentionBg: Color(0xFF3A2A17),
    attentionInk: Color(0xFFF2C38B),
    danger: Color(0xFFF59B85),
    onAccent: Color(0xFF0F1412),
  );

  /// Monochrome over light (UR2-1): greys only; green and red keep their light values.
  static const monoLight = OzoneColors(
    canvas: Color(0xFFF4F4F4),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEBEBEB),
    bar: Color(0xFFE8E8E8),
    barActive: Color(0xFFD4D4D4),
    outline: Color(0xFFD4D4D4),
    ink: Color(0xFF111111),
    inkMuted: Color(0xFF5C5C5C),
    gain: Color(0xFF1B6B3E),
    loss: Color(0xFFA3361F),
    attentionBg: Color(0xFFFBE5E1),
    attentionInk: Color(0xFF8C2B18),
    danger: Color(0xFFA3361F),
    onAccent: Color(0xFFFFFFFF),
    mono: true,
  );

  /// Monochrome over dark (UR2-1): near-black, not pure black (owner's samples).
  static const monoDark = OzoneColors(
    canvas: Color(0xFF0B0B0B),
    surface: Color(0xFF161616),
    surfaceSunken: Color(0xFF1F1F1F),
    bar: Color(0xFF1A1A1A),
    barActive: Color(0xFF2E2E2E),
    outline: Color(0xFF2E2E2E),
    ink: Color(0xFFF2F2F2),
    inkMuted: Color(0xFFA6A6A6),
    gain: Color(0xFF7FD6A0),
    loss: Color(0xFFF59B85),
    attentionBg: Color(0xFF2A1512),
    attentionInk: Color(0xFFF59B85),
    danger: Color(0xFFF59B85),
    onAccent: Color(0xFF0B0B0B),
    mono: true,
  );

  static OzoneColors resolve(Brightness b, {bool mono = false}) => b == Brightness.dark
      ? (mono ? monoDark : dark)
      : (mono ? monoLight : light);
}

/// A tool's colour pair (accent + tile) in both themes (docs/05, "Tool tints").
class ToolTint {
  const ToolTint({
    required this.accentLight,
    required this.tileLight,
    required this.accentDark,
    required this.tileDark,
  });

  final Color accentLight;
  final Color tileLight;
  final Color accentDark;
  final Color tileDark;

  Color accent(Brightness b) => b == Brightness.dark ? accentDark : accentLight;
  Color tile(Brightness b) => b == Brightness.dark ? tileDark : tileLight;

  static const finance = ToolTint(
    accentLight: Color(0xFF16676A),
    tileLight: Color(0xFFDFF1F1),
    accentDark: Color(0xFF86D4D2),
    tileDark: Color(0xFF17302F),
  );
  static const library = ToolTint(
    accentLight: Color(0xFF1F5A8F),
    tileLight: Color(0xFFE2ECF7),
    accentDark: Color(0xFF9CC5F2),
    tileDark: Color(0xFF1C2A3A),
  );
  static const notes = ToolTint(
    accentLight: Color(0xFF5B3E99),
    tileLight: Color(0xFFECE7F5),
    accentDark: Color(0xFFC2AEF0),
    tileDark: Color(0xFF2A2438),
  );
}

/// Spacing on a 4 dp base (docs/05).
abstract final class Space {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double screen = 16;
}

/// Pill chips (filters, folders, scopes): never narrower than a "Gold" pill,
/// so one-word labels like "All" stay pills instead of circles (owner, 15 Oct 2026).
abstract final class PillSize {
  static const double minWidth = 72;
}

/// Corner radii (docs/05).
abstract final class Radii {
  static const double card = 22;
  static const double tile = 14;
  static const double sheet = 28;
  static const double addButton = 20;
}
