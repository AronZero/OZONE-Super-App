import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/theme/oz_icons.dart';

/// Appearance (W3 · Appearance): System / Light / Dark. The whole app,
/// including this screen, switches as soon as a choice is tapped.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  static const _hints = {
    ThemeChoice.system: 'Matches your phone. OZONE switches when your phone switches between light and dark.',
    ThemeChoice.light: 'Always light, whatever your phone uses.',
    ThemeChoice.dark: 'Always dark, whatever your phone uses.',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final current = ref.watch(themeChoiceProvider).value ?? ThemeChoice.system;
    void pick(ThemeChoice t) => ref.read(settingsRepoProvider).set(SettingKeys.theme, t);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            const DetailTopBar(title: 'Appearance', overline: 'Settings'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.xs, Space.s, Space.xs, Space.m),
                    child: Text('Theme', style: text.titleMedium),
                  ),
                  Row(
                    children: [
                      for (final t in ThemeChoice.values)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _ThemeCard(choice: t, selected: t == current, onTap: () => pick(t)),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.xs, Space.m, Space.xs, Space.l),
                    child: Text(_hints[current]!, style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                  ),
                  const GroupCard(children: [
                    SettingsRow(title: 'Text size', subtitle: 'Follows your phone’s font size, up to 200%'),
                    SettingsRow(title: 'Animations', subtitle: 'Turned off when your phone’s "remove animations" setting is on'),
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

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.choice, required this.selected, required this.onTap});

  final ThemeChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final name = switch (choice) { ThemeChoice.system => 'System', ThemeChoice.light => 'Light', ThemeChoice.dark => 'Dark' };
    Widget half(OzoneColors p, Color tile) => Expanded(
          child: Container(
            color: p.canvas,
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.7,
                  child: Container(height: 8, decoration: BoxDecoration(color: p.outline, borderRadius: BorderRadius.circular(4))),
                ),
                const SizedBox(height: 5),
                Container(height: 30, decoration: BoxDecoration(color: tile, borderRadius: BorderRadius.circular(7))),
                const SizedBox(height: 5),
                Container(height: 14, decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(5))),
              ],
            ),
          ),
        );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: spokenAmounts('$name theme'),
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? c.ink : Colors.transparent, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 96,
                    child: Row(children: [
                      if (choice != ThemeChoice.dark) half(OzoneColors.light, ToolTint.finance.tileLight),
                      if (choice != ThemeChoice.light) half(OzoneColors.dark, ToolTint.finance.tileDark),
                    ]),
                  ),
                ),
                const SizedBox(height: Space.s),
                Row(children: [
                  Icon(selected ? OzIcons.radioButtonChecked : OzIcons.radioButtonUnchecked, fill: selected ? 1 : 0,
                      size: 18, color: selected ? c.ink : c.inkMuted),
                  const SizedBox(width: 6),
                  Flexible(child: Text(name, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
