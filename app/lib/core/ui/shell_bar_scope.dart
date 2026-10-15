import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'theme/tokens.dart';

/// Bar geometry (canvas board "Bottom bar & icons spec").
abstract final class BarSize {
  static const height = 64.0;
  static const radius = 32.0;

  /// Widest the bar gets (tablets, landscape); it stays centred.
  static const maxWidth = 440.0;

  /// Gap between the bar and the screen's sides and bottom edge.
  static const gap = Space.screen;

  /// Gap between the bar and a screen's add button above it.
  static const aboveBar = 12.0;

  /// Distance of the bar from the bottom of the screen.
  static double bottom(BuildContext context) => math.max(gap, MediaQuery.viewPaddingOf(context).bottom + Space.xs);
}

/// Whether the floating bar is showing. The shell hides it while the user
/// scrolls down and brings it back on scroll up; tab screens' add buttons
/// follow it through [ShellAddButtonSlot].
class ShellBarScope extends InheritedNotifier<ValueNotifier<bool>> {
  const ShellBarScope({super.key, required ValueNotifier<bool> visible, required super.child}) : super(notifier: visible);

  /// True outside the shell (a screen shown on its own, in tests).
  static bool visibleOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellBarScope>()?.notifier?.value ?? true;
}

/// Places a tab screen's add button above the floating bar (or near the
/// bottom edge while the bar is hidden). Use inside the screen's Stack.
class ShellAddButtonSlot extends StatelessWidget {
  const ShellAddButtonSlot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visible = ShellBarScope.visibleOf(context);
    // Inside the shell the body extends behind the bar, so its bottom padding is the bar's whole block.
    final barBlock = MediaQuery.paddingOf(context).bottom;
    final bottom = visible ? math.max(Space.screen, barBlock + BarSize.aboveBar) : BarSize.bottom(context);
    return AnimatedPositioned(
      right: Space.screen,
      bottom: bottom,
      duration: Motion.of(context).hide,
      curve: Motion.settle,
      child: PressScale(child: child),
    );
  }
}

/// Bottom padding for a tab screen's list: room for the add button and the bar.
double shellListBottom(BuildContext context) => 104 + MediaQuery.paddingOf(context).bottom;

