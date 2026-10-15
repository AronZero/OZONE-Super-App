import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ui/amounts.dart';
import '../../core/ui/motion.dart';
import '../../core/ui/shell_bar_scope.dart';
import '../../core/ui/theme/app_theme.dart';
import '../../core/ui/theme/tokens.dart';

/// One entry in the bottom bar.
class BarItem {
  const BarItem({required this.label, required this.icon, required this.branch, this.tint});

  final String label;
  final IconData icon;
  final int branch;

  /// Null for Home and Tools (shell screens: ink pill).
  final ToolTint? tint;
}

/// The floating, rounded bar: outline icons, and one tinted pill on the
/// active item holding its solid icon and label. [onTap] null draws a
/// static preview (Edit bar screen).
class OzoneBar extends StatelessWidget {
  const OzoneBar({super.key, required this.items, required this.current, this.onTap, this.keyPrefix = 'bar'});

  final List<BarItem> items;
  final int current;
  final ValueChanged<int>? onTap;

  /// Item keys are `<keyPrefix>-<label>`; tests find the live bar by `bar-…`.
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final b = Theme.of(context).brightness;
    final m = Motion.of(context);
    final label = Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w800, height: 1);
    return Container(
      height: BarSize.height,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.bar,
        borderRadius: BorderRadius.circular(BarSize.radius),
      ),
      child: LayoutBuilder(builder: (context, box) {
        final n = items.length;
        final textScale = MediaQuery.textScalerOf(context).scale(13) / 13;
        final activeW = math.min(box.maxWidth * 0.5, 60 + 52 * textScale);
        final restW = n > 1 ? (box.maxWidth - activeW) / (n - 1) : 0.0;
        double leftOf(int i) => i <= current ? i * restW : activeW + (i - 1) * restW;
        final pill = items[current].tint?.accent(b) ?? c.ink;
        return Stack(children: [
          AnimatedPositioned(
            left: leftOf(current),
            top: 0,
            bottom: 0,
            width: activeW,
            duration: m.pill,
            curve: Motion.springy,
            child: AnimatedContainer(
              duration: m.fill,
              decoration: BoxDecoration(color: pill, borderRadius: BorderRadius.circular(BarSize.radius - 6)),
            ),
          ),
          for (var i = 0; i < n; i++)
            AnimatedPositioned(
              key: ValueKey('$keyPrefix-${items[i].label}'),
              left: leftOf(i),
              top: 0,
              bottom: 0,
              width: i == current ? activeW : restW,
              duration: m.pill,
              curve: Motion.springy,
              child: _BarButton(
                item: items[i],
                active: i == current,
                activeColor: c.onAccent,
                idleColor: c.inkMuted,
                labelStyle: label,
                maxLabelWidth: math.max(0, activeW - 24 - 6 - 20),
                onTap: onTap == null ? null : () => onTap!(i),
              ),
            ),
        ]);
      }),
    );
  }
}

class _BarButton extends StatefulWidget {
  const _BarButton({
    required this.item,
    required this.active,
    required this.activeColor,
    required this.idleColor,
    required this.labelStyle,
    required this.maxLabelWidth,
    required this.onTap,
  });

  final BarItem item;
  final bool active;
  final Color activeColor;
  final Color idleColor;
  final TextStyle labelStyle;
  final double maxLabelWidth;
  final VoidCallback? onTap;

  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton> with SingleTickerProviderStateMixin {
  late final _pop = AnimationController(vsync: this, value: 1);
  late final _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.12).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
  ]).animate(_pop);

  @override
  void didUpdateWidget(_BarButton old) {
    super.didUpdateWidget(old);
    final m = Motion.of(context);
    if (widget.active && !old.active && !m.off) {
      _pop.duration = m.pop;
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = Motion.of(context);
    final item = widget.item;
    return Semantics(
      selected: widget.active,
      button: true,
      label: spokenAmounts(item.label),
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: PressScale(
          scale: 0.88,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: widget.active ? 1 : 0),
              duration: m.label,
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                final color = Color.lerp(widget.idleColor, widget.activeColor, t)!;
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  ScaleTransition(
                    scale: _scale,
                    child: Icon(item.icon, size: 24, fill: t, weight: 400 + 200 * t, color: color),
                  ),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: t,
                      child: Opacity(
                        opacity: t,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: widget.maxLabelWidth),
                            child: Text(item.label,
                                maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: widget.labelStyle.copyWith(color: color)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }
}
