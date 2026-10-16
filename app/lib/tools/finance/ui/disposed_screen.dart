import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/dates.dart';
import '../../../core/domain/weight.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../state/finance_providers.dart';
import 'gold_overview.dart';
import '../../../core/ui/motion.dart';

/// Disposed gold items (docs/04 sitemap): kept, but left out of every total.
/// Tap one to edit it or mark it as held again.
class DisposedScreen extends ConsumerWidget {
  const DisposedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final items = [...?ref.watch(goldDataProvider).value?.disposed]
      ..sort((a, b) => (b.disposedDate ?? '').compareTo(a.disposedDate ?? ''));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: staggered([
            const DetailTopBar(title: 'Disposed items', overline: 'Gold'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Sold, gifted or melted items stay here for your records. They aren’t in any total.',
                    style: text.bodyLarge!.copyWith(fontSize: 14, height: 1.55, color: c.inkMuted)),
                const SizedBox(height: Space.m),
                if (items.isEmpty) Text('No disposed items.', style: text.bodyLarge),
                for (final i in items) ...[
                  GoldItemRowTile(
                    item: i,
                    value: null,
                    subtitle: '${Weight.format(i.weightMg)} · disposed '
                        '${i.disposedDate == null ? '' : LocalDate.parseIso(i.disposedDate!).valueOrNull!.format(today)} · cost',
                  ),
                  const SizedBox(height: Space.s),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
