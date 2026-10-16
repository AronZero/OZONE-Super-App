import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../tool_registry.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/motion.dart';

/// Settings menu (W3 · Settings). Rows for parts not built yet are shown
/// disabled with the milestone they arrive in.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final theme = ref.watch(themeChoiceProvider).value ?? ThemeChoice.system;
    final widgets = ref.watch(dashboardWidgetsProvider).value ?? defaultDashboard;
    final bar = ref.watch(barToolsProvider).value ?? const <String>[];
    final lock = ref.watch(appLockSettingProvider).value;
    final barNames = [for (final id in bar) toolRegistry.where((t) => t.id == id).firstOrNull?.name ?? id];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: staggered([
            const DetailTopBar(title: 'Settings', overline: 'Home'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel('App'),
                  GroupCard(children: [
                    SettingsRow(
                      icon: OzIcons.contrast,
                      title: 'Appearance',
                      subtitle: 'Theme: ${_themeName(theme)}',
                      onTap: () => context.push('/settings/appearance'),
                    ),
                    SettingsRow(
                      icon: OzIcons.dashboardCustomize,
                      title: 'Home dashboard',
                      subtitle: '${widgets.where((w) => w.on).length} of ${widgets.length} widgets shown',
                      onTap: () => context.push('/settings/dashboard'),
                    ),
                    SettingsRow(
                      icon: OzIcons.spaceBar,
                      title: 'Bottom bar',
                      subtitle: barNames.isEmpty ? 'Home and Tools only' : barNames.join(' · '),
                      onTap: () => context.push('/edit-bar'),
                    ),
                  ]),
                  const SectionLabel('Privacy'),
                  GroupCard(children: [
                    SettingsRow(
                      icon: OzIcons.shield,
                      title: 'Security',
                      subtitle: lock?.on ?? false ? 'App lock on' : 'App lock off',
                      onTap: () => context.push('/settings/security'),
                    ),
                  ]),
                  const SectionLabel('Tools'),
                  GroupCard(children: [
                    SettingsRow(
                      icon: OzIcons.accountBalanceWallet,
                      iconBg: ToolTint.finance.tileOf(context),
                      iconFg: ToolTint.finance.accentOf(context),
                      title: 'Finance',
                      subtitle: 'Month-end reminder · karat prices',
                      onTap: () => context.push('/settings/finance'),
                    ),
                    SettingsRow(
                      icon: OzIcons.list,
                      title: 'Lists',
                      subtitle: 'Vendors, savings platforms, account types',
                      onTap: () => context.push('/finance/lists'),
                    ),
                  ]),
                  const SectionLabel('Data'),
                  GroupCard(children: [
                    SettingsRow(
                      icon: OzIcons.download,
                      iconBg: c.attentionBg,
                      iconFg: c.attentionInk,
                      title: 'Data & backup',
                      subtitle: 'Export and import workbooks',
                      onTap: () => context.push('/settings/data'),
                    ),
                    SettingsRow(
                      icon: OzIcons.info,
                      title: 'About OZONE',
                      subtitle: 'Version · Licences · Privacy',
                      onTap: () => context.push('/settings/about'),
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(top: Space.l),
                    child: Text(
                      'Everything stays on this phone. OZONE has no account and no cloud.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  static String _themeName(ThemeChoice t) => switch (t) {
        ThemeChoice.system => 'System',
        ThemeChoice.light => 'Light',
        ThemeChoice.dark => 'Dark',
      };
}
