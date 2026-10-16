import 'package:flutter/material.dart';

import '../components/forms.dart';
import '../amounts.dart';
import '../motion.dart';

/// One bar: a month's value, or null for No data (drawn as a faint stub).
class BarDatum {
  const BarDatum(this.label, this.value, {this.dashed = false, this.highlight = false});
  final String label;
  final int? value;

  /// Carried months are drawn dashed (F1-04 §2).
  final bool dashed;

  /// The current month is drawn in the full accent.
  final bool highlight;
}

/// Simple month bar chart (docs/spec/F3-01 §4: CustomPaint, no chart package).
/// Bars start at zero so heights compare honestly. The caller gives the
/// spoken summary in [semanticLabel]; screens also offer the numbers as a table.
/// Bars grow from the baseline, left to right, each time the screen opens
/// (step 3, moment 4).
class MonthBars extends StatefulWidget {
  const MonthBars({
    super.key,
    required this.data,
    required this.accent,
    required this.semanticLabel,
    this.height = 56,
    this.labelColor,
    this.showLabels = true,
    this.labelEvery = 3,
    this.valueLabels,
  });

  final List<BarDatum> data;
  final Color accent;
  final String semanticLabel;
  final double height;
  final Color? labelColor;
  final bool showLabels;

  /// Label every Nth bar (and always the last). 1 labels every bar.
  final int labelEvery;

  /// Optional short labels drawn above each bar ("₱71k").
  final List<String?>? valueLabels;

  @override
  State<MonthBars> createState() => _MonthBarsState();
}

class _MonthBarsState extends State<MonthBars> with SingleTickerProviderStateMixin {
  late final _grow = AnimationController(vsync: this, value: 1);
  int? _opens;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final opens = EntranceScope.of(context);
    if (opens == _opens) return;
    _opens = opens;
    final m = Motion.of(context);
    if (m.off) return;
    _grow.duration = m.chart + _BarsPainter.step * (widget.data.length - 1).clamp(0, 99);
    _grow.forward(from: 0);
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final accent = widget.accent;
    final height = widget.height;
    final showLabels = widget.showLabels;
    final labelEvery = widget.labelEvery;
    final valueLabels = widget.valueLabels;
    final style = Theme.of(context).textTheme.labelSmall!.copyWith(color: widget.labelColor);
    return Semantics(
      label: spokenAmounts(widget.semanticLabel),
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        height: height + (showLabels ? 20 : 0) + (valueLabels == null ? 0 : _BarsPainter.top),
        width: double.infinity,
        child: CustomPaint(
          painter: _BarsPainter(
            data: data,
            accent: accent,
            barsHeight: height,
            labelStyle: showLabels ? style : null,
            labelEvery: labelEvery,
            valueLabels: valueLabels,
            textScaler: MediaQuery.textScalerOf(context),
            grow: _grow,
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.data,
    required this.accent,
    required this.barsHeight,
    required this.labelStyle,
    required this.textScaler,
    this.labelEvery = 3,
    this.valueLabels,
    required this.grow,
  }) : super(repaint: grow);

  final List<BarDatum> data;
  final Color accent;
  final double barsHeight;
  final TextStyle? labelStyle;
  final TextScaler textScaler;
  final int labelEvery;
  final List<String?>? valueLabels;

  /// Runs 0 → 1 while the bars grow in.
  final AnimationController grow;

  /// Each bar starts this long after the one before it.
  static const Duration step = Duration(milliseconds: 20);

  /// How far bar [i] has grown, 0 → 1.
  double _grown(int i) {
    final total = grow.duration?.inMicroseconds ?? 0;
    if (grow.value >= 1 || total == 0) return 1;
    final start = step.inMicroseconds * i / total;
    final run = 420000 / total;
    return Motion.settle.transform(((grow.value - start) / run).clamp(0.0, 1.0));
  }

  static const double _gap = 5;

  /// Room above the bars for value labels.
  static const double top = 18;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final n = data.length;
    final w = (size.width - _gap * (n - 1)) / n;
    final maxV = data.map((d) => d.value ?? 0).fold<int>(0, (a, b) => b > a ? b : a);
    final t0 = valueLabels == null ? 0.0 : top;
    canvas
      ..save()
      ..translate(0, t0);
    for (var i = 0; i < n; i++) {
      final d = data[i];
      final x = i * (w + _gap);
      final v = d.value;
      if (v == null || maxV <= 0 || v <= 0) {
        // No data (or zero): a faint stub keeps the month's place.
        final stub = RRect.fromRectAndRadius(Rect.fromLTWH(x, barsHeight - 4, w, 4), const Radius.circular(2));
        canvas.drawRRect(stub, Paint()..color = accent.withValues(alpha: v == null ? 0.18 : 0.45));
      } else {
        final h = (barsHeight * v / maxV).clamp(6.0, barsHeight) * _grown(i);
        final rect = Rect.fromLTWH(x, barsHeight - h, w, h);
        final rr = RRect.fromRectAndCorners(rect,
            topLeft: const Radius.circular(6), topRight: const Radius.circular(6),
            bottomLeft: const Radius.circular(2), bottomRight: const Radius.circular(2));
        if (d.dashed) {
          canvas
            ..save()
            ..translate(rect.left, rect.top);
          DashedRRectPainter(color: accent, radius: 6, strokeWidth: 2, topOnlyRadius: true).paint(canvas, rect.size);
          canvas.restore();
        } else {
          canvas.drawRRect(rr, Paint()..color = d.highlight ? accent : accent.withValues(alpha: 0.45));
        }
      }
      final style = labelStyle;
      final vl = valueLabels == null || i >= valueLabels!.length ? null : valueLabels![i];
      if (style != null && vl != null && _grown(i) >= 1) {
        final h = v == null || maxV <= 0 || v <= 0 ? 4.0 : (barsHeight * v / maxV).clamp(6.0, barsHeight);
        final tp = TextPainter(text: TextSpan(text: vl, style: style.copyWith(fontWeight: FontWeight.w800)), textDirection: TextDirection.ltr, textScaler: textScaler)..layout();
        tp.paint(canvas, Offset((x + w / 2 - tp.width / 2).clamp(0, size.width - tp.width), barsHeight - h - tp.height - 2));
      }
      final labelled = labelEvery <= 1 || (i % labelEvery == 0 && i < n - 2) || i == n - 1;
      if (style != null && labelled) {
        final tp = TextPainter(text: TextSpan(text: d.label, style: style), textDirection: TextDirection.ltr, textScaler: textScaler)..layout();
        var lx = x + w / 2 - tp.width / 2;
        lx = lx.clamp(0, size.width - tp.width);
        tp.paint(canvas, Offset(lx, barsHeight + 5));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.data != data || old.accent != accent;
}
