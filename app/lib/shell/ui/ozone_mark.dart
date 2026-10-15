import 'package:flutter/material.dart';

import '../../core/ui/theme/app_theme.dart';

/// The OZONE mark, drawn from the brand geometry (design/brand/README.md):
/// three circles, radius 24, in a 100 × 100 box, with flat overlap colours.
class OzoneMark extends StatelessWidget {
  const OzoneMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'OZONE',
        image: true,
        child: CustomPaint(
          size: Size.square(size),
          painter: _MarkPainter(Theme.of(context).brightness, mono: OzoneThemeColors.of(context).mono),
        ),
      );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.brightness, {this.mono = false});

  final Brightness brightness;

  /// Monochrome (owner, 15 Oct 2026): the greyscale mark. Dark uses the iOS tinted
  /// source (design/brand/ios/AppIcon-1024-tinted.svg); light uses greys matched to
  /// the light mark's brightness, so the core stays dark on a light screen.
  final bool mono;

  static const _light = [0xFF3B7DC4, 0xFF7A5CC6, 0xFF2E9C9A, 0xFF5150AE, 0xFF2A6FA0, 0xFF55669E, 0xFF1C3466];
  static const _dark = [0xFF8DBEF2, 0xFFB9A3EE, 0xFF6CCFCB, 0xFFA4A2EC, 0xFF74B4DA, 0xFFA6B6DC, 0xFFEEF4FB];
  static const _greyLight = [0xFF7A7A7A, 0xFF6F6F6F, 0xFF8D8D8D, 0xFF5B5B5B, 0xFF6A6A6A, 0xFF686868, 0xFF363636];
  static const _greyDark = [0xFF8A8A8A, 0xFF6E6E6E, 0xFFA6A6A6, 0xFF5A5A5A, 0xFF7C7C7C, 0xFF646464, 0xFFEDEDED];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final dark = brightness == Brightness.dark;
    final col = mono ? (dark ? _greyDark : _greyLight) : (dark ? _dark : _light);
    Paint p(int i) => Paint()..color = Color(col[i]);
    const r = Radius.circular(24);

    canvas
      ..drawCircle(const Offset(50, 39.52), 24, p(0)) // Library
      ..drawCircle(const Offset(62.1, 60.478), 24, p(1)) // Notes
      ..drawCircle(const Offset(37.9, 60.478), 24, p(2)); // Finance

    Path lens(List<Offset> pts, List<bool> clockwise) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (var i = 1; i < pts.length; i++) {
        path.arcToPoint(pts[i], radius: r, clockwise: clockwise[i - 1]);
      }
      return path..close();
    }

    // Pair overlaps and the ozone core, as in ozone-mark.svg.
    canvas
      ..drawPath(lens(const [Offset(74, 39.636), Offset(50, 39.752), Offset(61.9, 60.362), Offset(74, 39.636)], const [false, true, false]), p(3))
      ..drawPath(lens(const [Offset(26, 39.636), Offset(50, 39.752), Offset(38.1, 60.362), Offset(26, 39.636)], const [true, false, true]), p(4))
      ..drawPath(lens(const [Offset(38.1, 60.362), Offset(50, 81.205), Offset(61.9, 60.362), Offset(38.1, 60.362)], const [false, false, true]), p(5))
      ..drawPath(lens(const [Offset(50, 39.752), Offset(38.1, 60.362), Offset(61.9, 60.362), Offset(50, 39.752)], const [false, false, false]), p(6));
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.brightness != brightness || old.mono != mono;
}

