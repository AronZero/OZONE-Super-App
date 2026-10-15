import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/first_run.dart';
import '../../../core/platform/reminders.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../ozone_mark.dart';
import '../../../core/ui/theme/oz_icons.dart';

/// W2 · Welcome: Start fresh, or Restore from a workbook (F1-03 §3).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget point(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, size: 20, color: c.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: text.bodyLarge!.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(body, style: text.bodyMedium!.copyWith(fontSize: 13.5, height: 1.45, color: c.inkMuted)),
              ]),
            ),
          ]),
        );
    return Scaffold(
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          decoration: BoxDecoration(
            color: ToolTint.library.tile(Theme.of(context).brightness),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(children: [
                const OzoneMark(size: 120),
                const SizedBox(height: 14),
                Semantics(header: true, child: Text('OZONE', style: text.headlineMedium!.copyWith(fontSize: 34, letterSpacing: 4.8))),
                const SizedBox(height: Space.s),
                Text('Money, books and notes, bonded in one app',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge!.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: dark ? c.inkMuted : const Color(0xFF2A3B52))),
              ]),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(22, Space.xxl, 22, Space.l), children: [
            point(OzIcons.lock, 'Stays on this phone', 'No account, no cloud. Works fully offline.'),
            point(OzIcons.download, 'You keep the backups', 'Export a workbook now and then. OZONE will remind you.'),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, Space.xl),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              OzoneButton(
                label: 'Start fresh',
                height: 54,
                onPressed: () async {
                  await FirstRun.done(ref.read(databaseProvider));
                  if (context.mounted) context.go('/welcome/reminder');
                },
              ),
              const SizedBox(height: 10),
              Material(
                color: c.surface,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => context.push('/welcome/restore'),
                  child: SizedBox(height: 54, child: Center(child: Text('Restore from a workbook', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)))),
                ),
              ),
              const SizedBox(height: 10),
              Text('Restoring shows a preview first. Locked notes will ask for the vault password they were saved with.',
                  textAlign: TextAlign.center, style: text.bodyMedium!.copyWith(fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w600, color: c.inkMuted)),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// W3 · Reminder ask (first run, decision F2-2): Turn on (asks for notification
/// permission now, never on launch) or Not now. Then Home, with the restore
/// summary when the person restored.
class ReminderAskScreen extends ConsumerWidget {
  const ReminderAskScreen({super.key, this.restored, this.rows});
  final String? restored;
  final String? rows;

  void _home(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    context.go('/home');
    if (restored != null) {
      final n = int.tryParse(rows ?? '') ?? 0;
      messenger?.showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text('Restored from $restored · $n ${n == 1 ? 'row' : 'rows'}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final b = Theme.of(context).brightness;
    final s = ref.watch(monthEndReminderProvider).value;
    final time = s == null ? '8:00 pm' : formatTime(s.hour, s.minute);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.xxl, 0, Space.xxl, 36),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: ToolTint.finance.tile(b), borderRadius: BorderRadius.circular(22)),
                      child: Icon(OzIcons.notifications, size: 32, color: ToolTint.finance.accent(b)),
                    ),
                    const SizedBox(height: 18),
                    Semantics(header: true, child: Text('Get a month-end reminder?', style: text.headlineMedium!.copyWith(fontSize: 28, height: 1.2))),
                    const SizedBox(height: 18),
                    Text(
                      'On the last day of each month at $time, OZONE reminds you to update your savings balances. That keeps your history Recorded instead of Carried.',
                      style: text.bodyLarge!.copyWith(fontSize: 16, height: 1.55, color: c.inkMuted),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(Space.l),
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('One notification a month', style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: Space.xs),
                        Text('It never shows amounts. Change the time or turn it off in Settings › Finance.',
                            style: text.bodyMedium!.copyWith(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
            OzoneButton(
              label: 'Turn on',
              onPressed: () async {
                await ref.read(remindersProvider).turnOn();
                if (context.mounted) _home(context);
              },
            ),
            const SizedBox(height: 10),
            OzoneButton(
              label: 'Not now',
              primary: false,
              height: 48,
              onPressed: () async {
                await ref.read(remindersProvider).turnOff();
                if (context.mounted) _home(context);
              },
            ),
            const SizedBox(height: 10),
            Text('Your phone will ask to allow notifications.',
                textAlign: TextAlign.center, style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
          ]),
        ),
      ),
    );
  }
}
