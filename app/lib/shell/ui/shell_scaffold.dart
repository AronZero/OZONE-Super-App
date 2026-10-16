import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../core/state/providers.dart';
import '../../core/ui/motion.dart';
import '../../core/ui/shell_bar_scope.dart';
import '../../core/ui/theme/oz_icons.dart';
import '../tool_registry.dart';
import 'shell_bar.dart';

export 'shell_bar.dart' show BarItem;

/// The app shell: the current tab's screen plus the floating bottom bar
/// (Home · up to 3 tools from settings · Tools; docs/04 navigation rules).
/// The screen scrolls behind the bar; scrolling down hides the bar and
/// scrolling up brings it back.
class ShellScaffold extends ConsumerStatefulWidget {
  const ShellScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> with SingleTickerProviderStateMixin {
  final _visible = ValueNotifier(true);
  late final _enter = AnimationController(vsync: this, value: 1);

  /// Bumped on every tab change, and when the App lock lifts, so the screen's
  /// cards rise in (and Home's figures roll) again.
  final _opens = ValueNotifier(0);
  late final _locked = ref.read(appLockServiceProvider).locked;

  void _onLock() {
    if (!_locked.value) _opens.value++;
  }

  @override
  void initState() {
    super.initState();
    _locked.addListener(_onLock);
  }

  @override
  void didUpdateWidget(ShellScaffold old) {
    super.didUpdateWidget(old);
    if (old.shell.currentIndex != widget.shell.currentIndex) {
      _visible.value = true;
      _opens.value++;
      final m = Motion.of(context);
      if (!m.off) {
        _enter.duration = m.screen;
        _enter.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _visible.dispose();
    _enter.dispose();
    _locked.removeListener(_onLock);
    _opens.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    // TalkBack users always keep the bar.
    if (MediaQuery.accessibleNavigationOf(context)) return false;
    if (n is! ScrollUpdateNotification) return false;
    final d = n.scrollDelta ?? 0;
    if (n.metrics.extentBefore <= 0 || d < -2) {
      _visible.value = true;
    } else if (d > 2 && n.metrics.extentBefore > 24) {
      _visible.value = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final barIds = ref.watch(barToolsProvider).value ?? const ['finance', 'library', 'notes'];
    final items = [
      const BarItem(label: 'Home', icon: OzIcons.home, branch: 0),
      for (final id in barIds)
        for (final t in toolRegistry.where((t) => t.id == id))
          BarItem(label: t.name, icon: t.icon, tint: t.tint, branch: branchOfTool(t.id)),
      BarItem(label: 'Tools', icon: OzIcons.gridView, branch: toolsBranch),
    ];
    // A tool opened from the launcher but not in the bar keeps "Tools" active.
    var current = items.indexWhere((i) => i.branch == shell.currentIndex);
    if (current < 0) current = items.length - 1;
    final m = Motion.of(context);

    return ShellBarScope(
      visible: _visible,
      child: Scaffold(
        extendBody: true,
        body: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: EntranceScope(opens: _opens, child: FadeRise(animation: _enter, child: shell)),
        ),
        bottomNavigationBar: ValueListenableBuilder<bool>(
          valueListenable: _visible,
          builder: (context, visible, bar) => AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, 1.2),
            duration: m.hide,
            curve: Motion.settle,
            child: bar,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(BarSize.gap, 0, BarSize.gap, BarSize.bottom(context)),
            // Phone width; centred and capped on tablets and in landscape.
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: BarSize.maxWidth),
                child: OzoneBar(
                  items: items,
                  current: current,
                  onTap: (i) {
                    if (i != current) HapticFeedback.selectionClick();
                    shell.goBranch(items[i].branch, initialLocation: items[i].branch == shell.currentIndex);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
