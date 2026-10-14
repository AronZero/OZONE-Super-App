import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/platform/platform_channel.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';

/// Security (W3 · Security & app lock). App lock and "Hide amounts" work in M1;
/// the notes vault section arrives with M6.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _needsScreenLock = false;
  bool _busy = false;

  Future<void> _toggleLock(bool on) async {
    final svc = ref.read(appLockServiceProvider);
    if (!on) {
      await svc.disable();
      return;
    }
    setState(() => _busy = true);
    final r = await svc.enable();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _needsScreenLock = r == EnableResult.noScreenLock;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final lock = ref.watch(appLockSettingProvider).value ?? const AppLockSetting(on: false, relockAfterS: 60);
    final hide = ref.watch(hideAmountsOnOpenProvider).value ?? false;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            const DetailTopBar(title: 'Security', overline: 'Settings'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel('App lock'),
                  GroupCard(children: [
                    SettingsRow(
                      title: 'Lock OZONE',
                      subtitle: 'Uses your phone’s screen lock: fingerprint, face or your phone password',
                      trailing: OzoneSwitch(
                        label: 'Lock OZONE',
                        value: lock.on,
                        onChanged: _busy ? null : _toggleLock,
                      ),
                    ),
                    if (lock.on)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lock again after leaving OZONE', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: Space.m),
                            ChoiceChips<int>(
                              label: 'Lock again after leaving OZONE',
                              options: const [(0, 'Immediately'), (60, '1 minute'), (300, '5 minutes')],
                              selected: lock.relockAfterS,
                              onSelected: (s) => ref.read(appLockServiceProvider).setRelockAfter(s),
                            ),
                            const SizedBox(height: Space.m),
                            Text('While app lock is on, OZONE is blank in your recent apps and screenshots are blocked.',
                                style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                          ],
                        ),
                      ),
                  ]),
                  if (_needsScreenLock) ...[
                    const SizedBox(height: Space.m),
                    AttentionBanner(
                      title: 'Set a screen lock first',
                      body: 'App lock uses your phone’s screen lock, and this phone doesn’t have one.',
                      action: OzoneButton(
                        label: 'Open phone settings',
                        primary: false,
                        onPressed: () async {
                          await OzonePlatform.openSecuritySettings();
                          if (mounted) setState(() => _needsScreenLock = false);
                        },
                      ),
                    ),
                  ],
                  const SectionLabel('Amounts'),
                  GroupCard(children: [
                    SettingsRow(
                      title: 'Hide amounts when OZONE opens',
                      subtitle: 'Shows ₱ •••• until you tap the eye on Home (from M7)',
                      trailing: OzoneSwitch(
                        label: 'Hide amounts when OZONE opens',
                        value: hide,
                        onChanged: (v) => ref.read(settingsRepoProvider).set(SettingKeys.hideAmountsOnOpen, v),
                      ),
                    ),
                  ]),
                  const SectionLabel('Notes vault'),
                  const GroupCard(children: [
                    SettingsRow(
                      title: 'Not set up yet',
                      subtitle: 'The vault is set up the first time you lock a note (arrives in M6)',
                      enabled: false,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
