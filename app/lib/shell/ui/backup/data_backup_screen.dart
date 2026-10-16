import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/domain/dates.dart';
import '../../../core/platform/external_activity.dart';
import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/motion.dart';

/// Days since the last export, from today's local date.
int daysSince(int ms, LocalDate today) => max(0, LocalDate.fromDateTime(DateTime.fromMillisecondsSinceEpoch(ms)).daysUntil(today));

/// W1 · Settings › Data & backup: last export, Export, Import, template,
/// backup reminder and safety exports (F1-03).
class DataBackupScreen extends ConsumerWidget {
  const DataBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final last = ref.watch(lastExportProvider).value;
    final days = ref.watch(backupReminderDaysProvider).value ?? 30;
    final overdue = last == null || daysSince(last.createdAt, today) > days;

    Widget card({required String title, required String body, required List<Widget> actions}) => Container(
          padding: const EdgeInsets.all(Space.l),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: text.bodyLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: Space.s),
            Text(body, style: text.bodyMedium!.copyWith(fontSize: 13.5, height: 1.5, color: c.inkMuted)),
            const SizedBox(height: Space.m),
            ...actions,
          ]),
        );

    final lastText = last == null
        ? 'No export yet'
        : 'Last export: ${LocalDate.fromDateTime(DateTime.fromMillisecondsSinceEpoch(last.createdAt)).formatLong()} · '
            '${switch (daysSince(last.createdAt, today)) { 0 => 'today', 1 => 'yesterday', final n => '$n days ago' }}';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: staggered([
            const DetailTopBar(title: 'Data & backup', overline: 'Settings'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, Space.l, 18, Space.l),
                  decoration: BoxDecoration(color: overdue ? c.attentionBg : c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(overdue ? OzIcons.error : OzIcons.checkCircle, size: 18, color: overdue ? c.attentionInk : c.gain),
                      const SizedBox(width: Space.s),
                      Expanded(child: Text(lastText, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: overdue ? c.attentionInk : c.ink))),
                    ]),
                    const SizedBox(height: 6),
                    Text('Your data lives only on this phone. An exported workbook is your backup.',
                        style: text.bodyMedium!.copyWith(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600, color: overdue ? c.attentionInk : c.inkMuted)),
                  ]),
                ),
                const SizedBox(height: Space.m),
                card(
                  title: 'Export workbook',
                  body: 'One .xlsx file with every tool, notes (locked ones stay encrypted), gold price history and settings. The file itself isn’t encrypted.',
                  actions: [OzoneButton(label: 'Export now', height: 48, onPressed: () => context.push('/settings/data/export'))],
                ),
                const SizedBox(height: Space.m),
                card(
                  title: 'Import workbook',
                  body: 'Add or update records from an OZONE workbook. You’ll see a preview first, and nothing is deleted. Also used to restore onto a new phone.',
                  actions: [
                    OzoneButton(label: 'Choose a file…', primary: false, height: 48, onPressed: () => context.push('/settings/data/import')),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () async {
                          final t = await ref.read(backupServiceProvider).template();
                          await ExternalActivity.run(() => SharePlus.instance.share(ShareParams(files: [XFile(t.file.path)], title: t.name)));
                        },
                        style: TextButton.styleFrom(foregroundColor: c.ink, padding: EdgeInsets.zero, minimumSize: const Size(48, 48)),
                        child: const Text('Get a blank template', style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.m),
                GroupCard(children: [
                  SettingsRow(
                    title: 'Backup reminder',
                    subtitle: 'Remind me when the last export is older than',
                    trailing: PopupMenuButton<int>(
                      tooltip: 'Backup reminder',
                      initialValue: days,
                      color: c.surface,
                      onSelected: (d) => ref.read(settingsRepoProvider).set(SettingKeys.backupReminderDays, d),
                      itemBuilder: (_) => [for (final d in const [7, 14, 30, 60, 90]) PopupMenuItem(value: d, child: Text('$d days'))],
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: Space.m),
                        decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(20)),
                        alignment: Alignment.center,
                        child: Text('$days days ▾', style: text.bodyMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  SettingsRow(
                    title: 'Safety exports',
                    subtitle: 'Saved automatically before each import · 3 kept',
                    onTap: () => context.push('/settings/data/safety'),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
