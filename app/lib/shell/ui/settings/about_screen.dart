import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/app_info.dart';
import '../../../core/data/setup_check.dart';
import '../../../core/platform/error_log.dart';
import '../../../core/platform/external_activity.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';

/// About OZONE: version, licences, privacy, and the setup check from M0.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const version = '$appVersion ($appMilestone)';

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
                  const SizedBox(height: Space.m),
                  const GroupCard(children: [_ErrorLogRow()]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Error log": share or clear the local log of unexpected errors (F3-01 §5).
class _ErrorLogRow extends ConsumerWidget {
  const _ErrorLogRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(errorLogProvider);
    return ValueListenableBuilder<int>(
      valueListenable: log.changes,
      builder: (context, _, _) => FutureBuilder<int>(
        future: log.count(),
        builder: (context, snap) {
          final n = snap.data ?? 0;
          return SettingsRow(
            title: 'Error log',
            subtitle: n == 0
                ? 'No errors recorded. If something goes wrong, OZONE notes where, never your data.'
                : '$n ${n == 1 ? 'error' : 'errors'} recorded on this phone. Share it if you’re asked to, or clear it.',
            onTap: n == 0 ? null : () => _actions(context, log),
          );
        },
      ),
    );
  }

  Future<void> _actions(BuildContext context, ErrorLog log) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.ios_share_rounded), title: const Text('Share error log'), onTap: () => Navigator.of(context).pop('share')),
          ListTile(leading: const Icon(Icons.delete_outline_rounded), title: const Text('Clear error log'), onTap: () => Navigator.of(context).pop('clear')),
        ]),
      ),
    );
    if (choice == 'clear') await log.clear();
    if (choice == 'share') {
      final f = await log.file();
      if (f != null && await f.exists()) {
        await ExternalActivity.run(() => SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'text/plain')], title: 'OZONE error log')));
      }
    }
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
