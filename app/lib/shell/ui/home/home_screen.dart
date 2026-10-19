import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../dashboard/widget_catalog.dart';
import '../../tool_registry.dart';
import '../backup/data_backup_screen.dart';
import '../ozone_mark.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/shell_bar_scope.dart';
import '../../../core/ui/motion.dart';

/// Home (W1 · Home): the dashboard, following the "Home dashboard" arrangement,
/// with search, Hide amounts, Settings and the quick-add menu.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgets = ref.watch(dashboardWidgetsProvider).value ?? const [];
    final shown = [
      for (final w in widgets)
        if (w.on && widgetCatalog.containsKey(w.id)) w.id,
    ];
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final b = Theme.of(context).brightness;
    final hidden = AmountsScope.hidden(context);

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.only(bottom: shellListBottom(context)),
            children: [
              MainTopBar(
                title: 'Home',
                // Brand minimum for the full-colour mark is 32 px (design/brand/README.md).
                leading: const ExcludeSemantics(child: OzoneMark(size: 36)),
                actions: [
                  RoundIconButton(icon: OzIcons.search, label: 'Search', onPressed: () => context.push('/search')),
                  // Hide amounts: every ₱ figure shows as ₱ •••• until tapped again (docs/04).
                  RoundIconButton(
                    icon: hidden ? OzIcons.visibilityOff : OzIcons.visibility,
                    label: hidden ? 'Show amounts' : 'Hide amounts',
                    onPressed: () => ref.read(amountsVisibilityProvider).toggle(),
                  ),
                  RoundIconButton(icon: OzIcons.settings, label: 'Settings', onPressed: () => context.push('/settings')),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: staggered([
                    if (shown.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(Space.xl),
                        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                        child: Text('All widgets are hidden. Show them in Settings › Home dashboard.', style: text.bodyLarge),
                      ),
                    for (final id in shown)
                      if (id == 'needs_attention')
                        const _NeedsAttention()
                      else ...[
                        _toolWidget(id)?.call(context) ?? _WidgetFrame(info: widgetCatalog[id]!, brightness: b),
                        const SizedBox(height: Space.m),
                      ],
                  ]),
                ),
              ),
            ],
          ),
        ),
        ShellAddButtonSlot(child: _QuickAddButton()),
      ],
    );
  }
}

/// Home's add button (Components "Quick-add menu"): one entry per tool action,
/// in bar order (decision M7-4).
class _QuickAddButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    return Tooltip(
      message: 'Quick add',
      child: PressScale(scale: PressScale.button, child: Material(
        color: c.ink,
        borderRadius: BorderRadius.circular(Radii.addButton),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.addButton),
          onTap: () => _open(context, ref),
          child: SizedBox(width: 60, height: 60, child: Icon(OzIcons.add, size: 28, color: c.canvas)),
        ),
      )),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final bar = ref.read(barToolsProvider).value ?? defaultBarTools;
    final actions = [
      for (final t in toolsInBarOrder(bar))
        for (final a in t.quickAdd) (t, a),
    ];
    // The menu grows out of the add button, so it is placed from the button's spot on screen.
    final box = context.findRenderObject()! as RenderBox;
    final button = box.localToGlobal(Offset.zero) & box.size;
    final screen = MediaQuery.sizeOf(context);
    final m = Motion.of(context);
    // + turns into × and the menu grows in (260 ms); the actions arrive 30 ms apart.
    final total = m.off ? Duration.zero : m.quickAdd + const Duration(milliseconds: 30) * (actions.length - 1).clamp(0, 99);
    double at(int ms) => total == Duration.zero ? 0 : (ms / total.inMilliseconds).clamp(0.0, 1.0);
    final picked = await showGeneralDialog<QuickAddAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close quick add',
      barrierColor: Colors.black.withValues(alpha: 0.32),
      transitionDuration: total,
      transitionBuilder: (ctx, anim, _, child) => child,
      pageBuilder: (ctx, anim, _) {
        final c = OzoneThemeColors.of(ctx);
        final text = Theme.of(ctx).textTheme;
        final grow = CurvedAnimation(parent: anim, curve: Interval(0, at(m.quickAdd.inMilliseconds), curve: Motion.settle));
        return Stack(children: [
          Positioned(
            right: screen.width - button.right,
            bottom: screen.height - button.top + Space.s,
            child: FadeTransition(
              opacity: grow,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1).animate(grow),
                alignment: Alignment.bottomRight,
                child: Material(
                  color: c.canvas,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(Radii.card),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 280, maxHeight: button.top - MediaQuery.paddingOf(ctx).top - Space.l),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Space.s),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, (t, a)) in actions.indexed)
                            _Arrive(
                              animation: CurvedAnimation(parent: anim, curve: Interval(at(60 + i * 30), at(260 + i * 30), curve: Motion.settle)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(Radii.tile),
                                onTap: () => Navigator.of(ctx).pop(a),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minHeight: 52),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(color: t.tint.tileOf(context), borderRadius: BorderRadius.circular(12)),
                                          child: Icon(a.icon, size: 20, color: t.tint.accentOf(context)),
                                        ),
                                        const SizedBox(width: Space.m),
                                        Flexible(
                                          child: Text(a.label, style: text.bodyLarge!.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // The add button above the dim, its + turning into × (tap to close).
          Positioned.fromRect(
            rect: button,
            child: Semantics(
              button: true,
              label: 'Close quick add',
              onTap: () => Navigator.of(ctx).pop(),
              excludeSemantics: true,
              child: Material(
                color: c.ink,
                borderRadius: BorderRadius.circular(Radii.addButton),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.addButton),
                  onTap: () => Navigator.of(ctx).pop(),
                  child: RotationTransition(
                    turns: Tween<double>(begin: 0, end: 0.125).animate(grow),
                    child: Icon(OzIcons.add, size: 28, color: c.canvas),
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
    if (picked != null && context.mounted) picked.run(context);
  }
}

/// A quick-add action arriving: fades in and rises 8 dp.
class _Arrive extends StatelessWidget {
  const _Arrive({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(animation),
          child: child,
        ),
      );
}

WidgetBuilder? _toolWidget(String id) {
  for (final t in toolRegistry) {
    final w = t.widgets[id];
    if (w != null) return w;
  }
  return null;
}

/// "Needs attention" (W1 · Home): one line per item from every tool, each
/// opening its fix. Hidden when there's nothing to do.
class _NeedsAttention extends ConsumerWidget {
  const _NeedsAttention();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [for (final t in toolRegistry) ...t.attention(ref), ?_backupLine(ref)];
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    // Nothing to do: the widget collapses to one line (UX3 board).
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Space.m),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: Space.l + 2, vertical: Space.m),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
          child: Row(
            children: [
              Icon(OzIcons.checkCircle, size: 20, color: c.gain),
              const SizedBox(width: Space.s),
              Text('All up to date', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.l + 2, Space.m, Space.s, Space.s),
        decoration: BoxDecoration(color: c.attentionBg, borderRadius: BorderRadius.circular(Radii.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Needs attention',
              style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.attentionInk),
            ),
            for (final i in items)
              PressScale(scale: PressScale.card, child: InkWell(
                borderRadius: BorderRadius.circular(Radii.tile),
                onTap: () => context.push(i.route),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          i.message,
                          style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: c.attentionInk),
                        ),
                      ),
                      Icon(OzIcons.chevronRight, color: c.attentionInk),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

/// "Last export was 41 days ago" when the backup reminder is due (W1 · Home, F2-03 §4:
/// in the app only). Never exported: counted from the first run (decision M8-4).
AttentionItem? _backupLine(WidgetRef ref) {
  final last = ref.watch(lastExportProvider);
  final firstRun = ref.watch(firstRunAtProvider).value;
  if (!last.hasValue) return null;
  final days = ref.watch(backupReminderDaysProvider).value ?? 30;
  final today = ref.watch(todayProvider);
  final since = last.value?.createdAt ?? firstRun;
  if (since == null) return null;
  final n = daysSince(since, today);
  if (n <= days) return null;
  return AttentionItem(last.value == null ? 'No backup exported yet' : 'Last export was $n days ago', '/settings/data');
}

/// A dashboard widget's frame. Until its tool is built it says when it arrives.
class _WidgetFrame extends StatelessWidget {
  const _WidgetFrame({required this.info, required this.brightness});

  final WidgetInfo info;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final bg = info.tint?.cardOf(context) ?? c.attentionBg;
    final fg = info.tint?.accentOf(context) ?? c.attentionInk;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.l + 2, Space.l, Space.l, Space.l),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.name,
              style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: fg),
            ),
            const SizedBox(height: Space.xs),
            Text('Arrives with milestone ${info.milestone}', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
          ],
        ),
      ),
    );
  }
}
