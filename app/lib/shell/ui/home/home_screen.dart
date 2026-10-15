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
                  children: [
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
                  ],
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
      child: Material(
        color: c.ink,
        borderRadius: BorderRadius.circular(Radii.addButton),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.addButton),
          onTap: () => _open(context, ref),
          child: SizedBox(width: 60, height: 60, child: Icon(OzIcons.add, size: 28, color: c.canvas)),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final bar = ref.read(barToolsProvider).value ?? defaultBarTools;
    final tools = toolsInBarOrder(bar);
    // The menu opens just above the add button, which sits higher while the bar shows.
    final addBottom = ShellBarScope.visibleOf(context)
        ? MediaQuery.paddingOf(context).bottom + BarSize.aboveBar
        : BarSize.bottom(context);
    final menuBottom = addBottom + 60 + Space.s - MediaQuery.viewPaddingOf(context).bottom;
    final picked = await showGeneralDialog<QuickAddAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close quick add',
      barrierColor: Colors.black.withValues(alpha: 0.32),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, _, _) {
        final c = OzoneThemeColors.of(ctx);
        final text = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(right: Space.screen, bottom: menuBottom),
              child: Material(
                color: c.canvas,
                elevation: 6,
                borderRadius: BorderRadius.circular(Radii.card),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.s),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final t in tools)
                          for (final a in t.quickAdd)
                            InkWell(
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    if (picked != null && context.mounted) picked.run(context);
  }
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
              InkWell(
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
              ),
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
