import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/platform/platform_channel.dart';
import '../../../core/platform/reminders.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';

/// Settings › Finance (not drawn; decision M8-5): month-end reminder on/off and
/// time, "Notifications are off for OZONE" with Open settings (F2-03 §4), the
/// stale gold price threshold, and Karat prices.
class FinanceSettingsScreen extends ConsumerStatefulWidget {
  const FinanceSettingsScreen({super.key});

  @override
  ConsumerState<FinanceSettingsScreen> createState() => _FinanceSettingsScreenState();
}

class _FinanceSettingsScreenState extends ConsumerState<FinanceSettingsScreen> with WidgetsBindingObserver {
  bool? _notificationsOn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the phone's settings: look again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
      ref.read(remindersProvider).reschedule();
    }
  }

  Future<void> _check() async {
    final on = await ref.read(remindersProvider).notificationsEnabled();
    if (mounted) setState(() => _notificationsOn = on);
  }

  Future<void> _toggle(bool on) async {
    final r = ref.read(remindersProvider);
    if (on) {
      await r.turnOn();
    } else {
      await r.turnOff();
    }
    await _check();
  }

  /// Android asks first; once it has been refused, only the phone's settings can allow it.
  Future<void> _allow() async {
    final ok = await ref.read(remindersProvider).turnOn();
    if (!ok) await OzonePlatform.openNotificationSettings();
    await _check();
  }

  Future<void> _pickTime(MonthEndReminder s) async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: s.hour, minute: s.minute));
    if (t != null) await ref.read(remindersProvider).setTime(t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final s = ref.watch(monthEndReminderProvider).value ?? const MonthEndReminder(on: true, hour: 20, minute: 0);
    final stale = ref.watch(_staleDaysProvider).value ?? 30;
    final blocked = s.on && _notificationsOn == false;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            const DetailTopBar(title: 'Finance', overline: 'Settings'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SectionLabel('Month-end reminder'),
                GroupCard(children: [
                  SettingsRow(
                    title: 'Remind me to update balances',
                    subtitle: 'On the last day of each month. It never shows amounts.',
                    trailing: OzoneSwitch(label: 'Month-end reminder', value: s.on, onChanged: _toggle, accent: ToolTint.finance.accentOf(context)),
                  ),
                  if (s.on)
                    SettingsRow(
                      title: 'Time',
                      subtitle: formatTime(s.hour, s.minute),
                      onTap: () => _pickTime(s),
                    ),
                ]),
                if (blocked) ...[
                  const SizedBox(height: Space.m),
                  AttentionBanner(
                    title: 'Notifications are off for OZONE',
                    body: 'The reminder can’t appear until notifications are allowed. Home still shows accounts that need a balance.',
                    action: OzoneButton(label: 'Allow notifications', primary: false, onPressed: _allow),
                  ),
                ],
                const SectionLabel('Gold'),
                GroupCard(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.l),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Flag karat prices older than', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: Space.m),
                      ChoiceChips<int>(
                        label: 'Flag karat prices older than',
                        options: const [(14, '14 days'), (30, '30 days'), (60, '60 days')],
                        selected: const [14, 30, 60].contains(stale) ? stale : 30,
                        onSelected: (d) => ref.read(settingsRepoProvider).set(SettingKeys.goldStaleDays, d),
                      ),
                    ]),
                  ),
                  SettingsRow(title: 'Karat prices', subtitle: 'Prices per gram and their history', onTap: () => context.push('/finance/gold/prices')),
                ]),
                const SizedBox(height: Space.m),
                Text('Vendors, platforms and account types are in Settings › Lists.', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

final _staleDaysProvider = StreamProvider.autoDispose<int>((ref) => ref.watch(settingsRepoProvider).watch(SettingKeys.goldStaleDays));
