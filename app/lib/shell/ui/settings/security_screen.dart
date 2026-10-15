import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/platform/platform_channel.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../tools/notes/ui/vault/vault_unlock.dart';

/// Security (W3 · Security & app lock): app lock, "Hide amounts" and the
/// notes vault (password, fingerprint, recovery code, forgot, reset).
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _needsScreenLock = false;
  bool _busy = false;
  bool? _bioAvailable;
  bool _bioOn = false;

  @override
  void initState() {
    super.initState();
    _readBio();
  }

  Future<void> _readBio() async {
    final v = ref.read(vaultServiceProvider);
    final a = await v.biometricAvailable(), on = await v.biometricOn();
    if (mounted) {
      setState(() {
        _bioAvailable = a;
        _bioOn = on;
      });
    }
  }

  Future<void> _toggleBio(bool on) async {
    final v = ref.read(vaultServiceProvider);
    if (on && !await ensureVaultOpen(context, ref)) return;
    final ok = await v.setBiometric(on);
    if (!mounted) return;
    if (!ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fingerprint unlock wasn’t turned on.')));
    await _readBio();
  }

  /// "Make a new recovery code" needs the vault open (F2-01 §4).
  Future<void> _newCode() async {
    if (await ensureVaultOpen(context, ref) && mounted) await context.push('/notes/vault/code');
  }

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
                  if (ref.watch(vaultExistsProvider).value ?? false)
                    GroupCard(children: [
                      SettingsRow(title: 'Change vault password', onTap: () => context.push('/notes/vault/password')),
                      if (_bioAvailable ?? false)
                        SettingsRow(
                          title: 'Unlock with fingerprint',
                          subtitle: 'Only shown when the phone has one set up',
                          trailing: OzoneSwitch(label: 'Unlock with fingerprint', value: _bioOn, onChanged: _toggleBio, accent: ToolTint.notes.accent(Theme.of(context).brightness)),
                        ),
                      SettingsRow(title: 'Make a new recovery code', subtitle: 'The old code stops working', onTap: _newCode),
                      SettingsRow(title: 'Forgot vault password', onTap: () => context.push('/notes/vault/forgot')),
                      SettingsRow(
                        title: 'Reset vault',
                        subtitle: 'Deletes every locked note',
                        titleColor: c.danger,
                        onTap: () => context.push('/notes/vault/reset'),
                      ),
                    ])
                  else
                    const GroupCard(children: [
                      SettingsRow(
                        title: 'Not set up yet',
                        subtitle: 'The vault is set up the first time you lock a note, from the note’s menu',
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
