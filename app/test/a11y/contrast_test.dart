import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/ui/theme/tokens.dart';

/// WCAG 2.2 AA contrast for every text/background pair the app draws (docs/04 ›
/// Accessibility): 4.5:1 for text, in both themes and both Monochrome palettes (UR2).
/// Outline is decorative only.
double ratio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

void main() {
  for (final (name, c, b) in [
    ('light', OzoneColors.light, Brightness.light),
    ('dark', OzoneColors.dark, Brightness.dark),
    ('mono light', OzoneColors.monoLight, Brightness.light),
    ('mono dark', OzoneColors.monoDark, Brightness.dark),
  ]) {
    group(name, () {
      final backgrounds = {'canvas': c.canvas, 'surface': c.surface, 'sunken': c.surfaceSunken, 'bar': c.bar, 'barActive': c.barActive};
      final texts = {'ink': c.ink, 'inkMuted': c.inkMuted};
      for (final t in texts.entries) {
        for (final bg in backgrounds.entries) {
          test('${t.key} on ${bg.key}', () => expect(ratio(t.value, bg.value), greaterThanOrEqualTo(4.5)));
        }
      }
      for (final t in {'gain': c.gain, 'loss': c.loss, 'danger': c.danger}.entries) {
        for (final bg in {'canvas': c.canvas, 'surface': c.surface, 'sunken': c.surfaceSunken}.entries) {
          test('${t.key} on ${bg.key}', () => expect(ratio(t.value, bg.value), greaterThanOrEqualTo(4.5)));
        }
      }
      test('attention ink on attention', () => expect(ratio(c.attentionInk, c.attentionBg), greaterThanOrEqualTo(4.5)));
      test('canvas on ink (primary buttons, Undo bar)', () => expect(ratio(c.canvas, c.ink), greaterThanOrEqualTo(4.5)));
      test('onAccent on ink (Monochrome selected states)', () => expect(ratio(c.onAccent, c.ink), greaterThanOrEqualTo(4.5)));
      // In Monochrome tool colours resolve to ink and greys, covered above.
      if (c.mono) return;
      for (final (tool, tint) in [('finance', ToolTint.finance), ('library', ToolTint.library), ('notes', ToolTint.notes)]) {
        test('$tool accent on its tile, surface and canvas', () {
          for (final bg in [tint.tile(b), c.surface, c.canvas, c.bar]) {
            expect(ratio(tint.accent(b), bg), greaterThanOrEqualTo(4.5));
          }
        });
        test('text on $tool accent and on its tile', () {
          expect(ratio(c.onAccent, tint.accent(b)), greaterThanOrEqualTo(4.5));
          expect(ratio(c.ink, tint.tile(b)), greaterThanOrEqualTo(4.5));
          expect(ratio(c.inkMuted, tint.tile(b)), greaterThanOrEqualTo(4.5));
        });
      }
    });
  }
}
