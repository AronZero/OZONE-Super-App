import 'package:flutter/material.dart';

import '../../../core/data/setup_check.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';

/// About OZONE: version, licences, privacy, and the setup check from M0.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const version = '0.8.0 (M7)';

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            const DetailTopBar(title: 'About OZONE', overline: 'Settings'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GroupCard(children: [
                    const SettingsRow(title: 'Version', subtitle: version),
                    SettingsRow(
                      title: 'Licences',
                      subtitle: 'Open-source packages and the Manrope font',
                      onTap: () => showLicensePage(context: context, applicationName: 'OZONE', applicationVersion: version),
                    ),
                  ]),
                  const SizedBox(height: Space.m),
                  Container(
                    padding: const EdgeInsets.all(Space.l),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Privacy', style: text.titleMedium),
                      const SizedBox(height: Space.s),
                      Text(
                        'OZONE works offline and has no internet permission. Your data stays in this app on this phone, '
                        'and phone backups are turned off for it. Export a workbook to keep a backup.',
                        style: text.bodyMedium!.copyWith(color: c.inkMuted),
                      ),
                    ]),
                  ),
                  const SizedBox(height: Space.m),
                  const _SetupCheckCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCheckCard extends StatefulWidget {
  const _SetupCheckCard();

  @override
  State<_SetupCheckCard> createState() => _SetupCheckCardState();
}

class _SetupCheckCardState extends State<_SetupCheckCard> {
  late final Future<SetupCheckResult> _check = runSetupCheck();

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Space.l),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
      child: FutureBuilder<SetupCheckResult>(
        future: _check,
        builder: (context, snap) {
          final lines = snap.hasError
              ? ['Database: couldn’t open']
              : snap.hasData
                  ? [
                      'Database: working (SQLite ${snap.data!.sqliteVersion})',
                      snap.data!.fts5 ? 'Search engine: working' : 'Search engine: not available',
                    ]
                  : ['Checking…'];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Setup check', style: text.titleMedium),
            const SizedBox(height: Space.s),
            for (final l in lines) Text(l, style: text.bodyMedium!.copyWith(color: c.inkMuted)),
          ]);
        },
      ),
    );
  }
}
