import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';

import '../domain/money.dart';
import 'amounts.dart';
import 'motion.dart';

/// A big ₱ figure (board moment 3). When the value changes on screen it rolls
/// from the old figure to the new one in 600 ms; with [rollOnOpen] (Home
/// widgets, decision UR3) it also counts up from zero each time the screen
/// opens. Hide amounts blurs the figure out as the dots fade in (moment 5).
/// Screen readers always hear the final amount.
class RollingAmount extends StatefulWidget {
  const RollingAmount(this.centavos, {super.key, required this.style, this.rollOnOpen = false});

  final int centavos;
  final TextStyle style;
  final bool rollOnOpen;

  static const Duration roll = Duration(milliseconds: 600);
  static const Duration hide = Duration(milliseconds: 200);

  @override
  State<RollingAmount> createState() => _RollingAmountState();
}

class _RollingAmountState extends State<RollingAmount> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: RollingAmount.roll, value: 1);
  late int _from = widget.centavos;
  late int _to = widget.centavos;
  int? _opens;

  void _rollFrom(int from) {
    _from = from;
    if (Motion.of(context).off) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.rollOnOpen) return;
    final opens = EntranceScope.of(context);
    if (opens == _opens) return;
    _opens = opens;
    _rollFrom(0);
  }

  @override
  void didUpdateWidget(RollingAmount old) {
    super.didUpdateWidget(old);
    if (old.centavos == widget.centavos) return;
    final from = _shown;
    _to = widget.centavos;
    _rollFrom(from);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Whole pesos while rolling, the exact figure once it lands.
  int get _shown {
    if (_c.value >= 1) return _to;
    final t = Curves.easeOutCubic.transform(_c.value);
    return ((_from + (_to - _from) * t) / 100).round() * 100;
  }

  @override
  Widget build(BuildContext context) {
    final hidden = AmountsScope.hidden(context);
    final style = widget.style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Semantics(
      label: hidden ? 'amount hidden' : Money.spoken(widget.centavos),
      excludeSemantics: true,
      child: AnimatedSwitcher(
        duration: Motion.of(context).off ? Duration.zero : RollingAmount.hide,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
        transitionBuilder: (child, a) => AnimatedBuilder(
          animation: a,
          builder: (context, child) => a.value >= 1
              ? child!
              : Opacity(
                  opacity: a.value,
                  child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 6 * (1 - a.value), sigmaY: 6 * (1 - a.value)), child: child),
                ),
          child: child,
        ),
        child: hidden
            ? Text(Money.hidden, key: const ValueKey(true), style: style)
            : AnimatedBuilder(
                key: const ValueKey(false),
                animation: _c,
                builder: (context, _) => Text(Money.format(_shown), style: style),
              ),
      ),
    );
  }
}
