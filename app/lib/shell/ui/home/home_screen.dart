import 'package:flutter/material.dart';

import '../../../core/data/setup_check.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../placeholder_screen.dart';

/// Home for M0: an empty dashboard plus the setup check, so the owner can
/// confirm on the phone that the database and search engine work.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Home',
      message: 'Your dashboard arrives as each tool is built. This is milestone M0: the empty shell.',
      footer: _SetupCheckCard(),
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
          final lines = <String>[];
          if (snap.hasError) {
            lines.add('Database: couldn’t open (${snap.error.runtimeType})');
          } else if (snap.hasData) {
            lines
              ..add('Database: working (SQLite ${snap.data!.sqliteVersion})')
              ..add(snap.data!.fts5 ? 'Search engine: working' : 'Search engine: not available');
          } else {
            lines.add('Checking…');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Setup check', style: text.titleMedium),
              const SizedBox(height: Space.s),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Text(l, style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                ),
            ],
          );
        },
      ),
    );
  }
}
