import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database.dart';
import '../../../core/domain/dates.dart';
import '../../../core/domain/validation.dart';
import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../state/savings_providers.dart';
import 'savings_parts.dart';
import '../../../core/ui/motion.dart';

/// Archived accounts (W3 · Archived): view history or restore, with Undo.
class ArchivedScreen extends ConsumerWidget {
  const ArchivedScreen({super.key});

  Future<void> _restore(BuildContext context, WidgetRef ref, SavingsAccountRow a) async {
    final repo = ref.read(savingsRepoProvider);
    final r = await repo.restore(a.id);
    if (!context.mounted) return;
    if (r is Invalid<void>) {
      await confirmDialog(context, title: 'Can’t restore yet', body: r.reason, confirm: 'OK', cancel: 'Close');
      return;
    }
    final was = LocalDate.parseIso(a.archivedAt!).valueOrNull!;
    await ref.read(undoControllerProvider).run(
          message: '${a.name} is back in Savings',
          hideNow: () {},
          commit: () async {},
          restore: () => unawaited(repo.archive(a.id, was)),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final data = ref.watch(savingsDataProvider).value;
    final archived = [...?data?.archived]..sort((a, b) => b.archivedAt!.compareTo(a.archivedAt!));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: staggered([
            const DetailTopBar(title: 'Archived accounts'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: AnimatedRows(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                    child: Text('Archived accounts aren’t in today’s total, but their history still counts in the months they were open.',
                        style: text.bodyLarge!.copyWith(fontSize: 14, height: 1.55, color: c.inkMuted)),
                  ),
                  const SizedBox(height: Space.m),
                  if (data != null && archived.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: Space.xxl),
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                      child: Column(children: [
                        Text('No archived accounts', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text('Archive an account from its menu when you close it.',
                            textAlign: TextAlign.center, style: text.bodyMedium!.copyWith(fontSize: 13.5, color: c.inkMuted)),
                      ]),
                    ),
                  for (final a in archived)
                    Padding(
                      key: ValueKey(a.id),
                      padding: const EdgeInsets.only(bottom: Space.m),
                      child: _ArchivedCard(
                      account: a,
                      lastBalance: data!.updatesOf(a.id).lastOrNull?.balance ?? 0,
                      today: today,
                      onView: () => context.push('/finance/savings/accounts/${a.id}'),
                      onRestore: () => _restore(context, ref, a),
                      ),
                    ),
                ],
                builder: (rows) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ArchivedCard extends StatelessWidget {
  const _ArchivedCard({required this.account, required this.lastBalance, required this.today, required this.onView, required this.onRestore});
  final SavingsAccountRow account;
  final int lastBalance;
  final LocalDate today;
  final VoidCallback onView;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final when = LocalDate.parseIso(account.archivedAt!).valueOrNull!.formatLong();
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.l, 14, Space.l, 14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
      child: Column(children: [
        Row(children: [
          AccountTile(account.name, archived: true),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(account.name, style: text.bodyLarge!.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700)),
              Text([?account.platform, 'archived $when'].join(' · '), style: text.bodyMedium!.copyWith(fontSize: 12.5, color: c.inkMuted)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(money(context, lastBalance), semanticsLabel: spokenAmounts(money(context, lastBalance)), style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
            Text('last balance', style: text.labelSmall!.copyWith(color: c.inkMuted)),
          ]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OzoneButton(label: 'View history', primary: false, height: 44, onPressed: onView)),
          const SizedBox(width: Space.s),
          Expanded(
            child: OzoneButton(label: 'Restore', height: 44, color: financeAccent(context), foreground: c.onAccent, onPressed: onRestore),
          ),
        ]),
      ]),
    );
  }
}
