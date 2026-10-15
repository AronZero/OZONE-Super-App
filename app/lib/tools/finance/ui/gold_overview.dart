import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/weight.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/components/states.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/gold_repo.dart';
import '../state/finance_providers.dart';
import 'gold_item_sheet.dart';
import 'savings_parts.dart';
import '../../../core/ui/shell_bar_scope.dart';

/// Gold tab (W2 · Gold): estimated value card, held items by value, and the
/// Add gold item button. Values are always estimates with their price date.
class GoldOverview extends ConsumerWidget {
  const GoldOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(goldDataProvider);
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Stack(
      children: [
        AsyncBody(
          value: data,
          what: 'Gold',
          onRetry: () => ref.invalidate(goldDataProvider),
          builder: (d) {
            final held = [...d.held]..sort((a, b) => (d.valueOf(b) ?? -1).compareTo(d.valueOf(a) ?? -1));
            return ListView(
              padding: EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, shellListBottom(context)),
              children: [
                if (held.isEmpty)
                  _EmptyCard(hasPrices: d.prices.isNotEmpty)
                else
                  _ValueCard(data: d),
                if (held.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                    child: Row(children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text('Items · ${held.length}', style: text.titleMedium!.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      Text('By value', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                    ]),
                  ),
                  const SizedBox(height: Space.s),
                  for (final i in held) ...[GoldItemRowTile(item: i, value: d.valueOf(i)), const SizedBox(height: Space.s)],
                ],
                if (d.disposed.isNotEmpty || d.prices.isNotEmpty) ...[
                  const SizedBox(height: Space.xs),
                  Row(children: [
                    if (d.disposed.isNotEmpty)
                      TextButton(
                        onPressed: () => context.push('/finance/gold/disposed'),
                        child: Text('Disposed items · ${d.disposed.length}', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800, color: c.ink)),
                      ),
                    if (held.isEmpty && d.prices.isNotEmpty)
                      TextButton(
                        onPressed: () => context.push('/finance/gold/prices'),
                        child: Text('Karat prices', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800, color: c.ink)),
                      ),
                  ]),
                ],
              ],
            );
          },
        ),
        ShellAddButtonSlot(child: FinanceAddButton(label: 'Add gold item', onPressed: () => showGoldItemSheet(context)),
        ),
      ],
    );
  }
}

class _ValueCard extends ConsumerWidget {
  const _ValueCard({required this.data});
  final GoldData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final t = data.totals;
    final asOf = t.pricesAsOf;
    final age = asOf?.daysUntil(today);
    Widget tile(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: 10),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.tile)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: text.labelLarge!.copyWith(color: c.inkMuted)),
              const SizedBox(height: 2),
              Text(value, semanticsLabel: spokenAmounts(value), style: text.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
            ]),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(18, Space.l, 18, Space.l),
      decoration: BoxDecoration(color: financeTile(context), borderRadius: BorderRadius.circular(Radii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Estimated value', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800))),
            if (t.hasValue && t.valuedCost > 0) GainPill(gain: t.gain, cost: t.valuedCost),
          ]),
          const SizedBox(height: Space.s),
          Semantics(
            label: t.hasValue ? moneySpoken(context, t.value) : 'No estimated value yet', // the heading names it
            excludeSemantics: true,
            child: Text(t.hasValue ? money(context, t.value) : '—', semanticsLabel: spokenAmounts(t.hasValue ? money(context, t.value) : '—'), style: text.displaySmall!.copyWith(fontSize: 32, letterSpacing: -0.6)),
          ),
          if (t.unpricedNote != null) ...[
            const SizedBox(height: Space.xs),
            Text(t.unpricedNote!, style: text.bodyMedium!.copyWith(color: c.attentionInk, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: Space.s),
          Row(children: [tile('Total weight', Weight.format(t.weightMg)), const SizedBox(width: Space.s), tile('Total cost', money(context, t.cost))]),
          const SizedBox(height: Space.m),
          Row(children: [
            Expanded(
              child: Text(
                asOf == null
                    ? 'No karat prices yet. Add them to see the value.'
                    : 'Prices as of ${asOf.formatLong()} · ${age == 0 ? 'today' : age == 1 ? '1 day ago' : '$age days ago'}\nEstimate only, not a sale price',
                style: text.bodyMedium!.copyWith(fontSize: 12.5, height: 1.4, color: c.inkMuted),
              ),
            ),
            const SizedBox(width: Space.s),
            Material(
              color: financeAccent(context),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => context.push('/finance/gold/prices'),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: Space.l),
                  alignment: Alignment.center,
                  child: Text('Karat prices', style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: c.onAccent)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// "▲ +₱70,514.00 · 17.5%" in a white pill.
class GainPill extends StatelessWidget {
  const GainPill({super.key, required this.gain, required this.cost});
  final int gain;
  final int cost;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(999)),
      child: Text('${moneyChange(context, gain)} · ${Money.percent(gain.abs(), cost)}', semanticsLabel: spokenAmounts('${moneyChange(context, gain)} · ${Money.percent(gain.abs(), cost)}'),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w800, color: changeColor(c, gain))),
    );
  }
}

/// One gold item: karat tile, name, weight and cost, value and gain %.
class GoldItemRowTile extends ConsumerWidget {
  const GoldItemRowTile({super.key, required this.item, required this.value, this.subtitle});
  final GoldItemRow item;

  /// Null when the karat has no price (or the item is disposed).
  final int? value;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final held = item.status == 'held';
    final v = value;
    final gain = v == null ? null : v - item.cost;
    final sub = subtitle ?? '${Weight.format(item.weightMg)} · cost ${money(context, item.cost)}';
    return Semantics(
      button: true,
      label: spokenAmounts('${item.name}, ${item.karat} karat, $sub${v == null ? '' : ', estimated ${moneySpoken(context, v)}'}'),
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showGoldItemSheet(context, existing: item),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                KaratTile(item.karat, muted: !held),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.name, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(sub, style: text.bodyMedium!.copyWith(fontSize: 12.5, color: c.inkMuted)),
                  ]),
                ),
                const SizedBox(width: Space.s),
                if (held)
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(v == null ? 'No ${item.karat}K price' : money(context, v), semanticsLabel: spokenAmounts(v == null ? 'No ${item.karat}K price' : money(context, v)),
                        style: v == null
                            ? text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: c.attentionInk)
                            : text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                    if (gain != null && item.cost > 0)
                      Text('${gain >= 0 ? '▲' : '▼'} ${Money.percent(gain.abs(), item.cost)}',
                          style: text.labelLarge!.copyWith(fontWeight: FontWeight.w800, color: changeColor(c, gain))),
                  ])
                else
                  Text(money(context, item.cost), semanticsLabel: spokenAmounts(money(context, item.cost)), style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// "18K" tile.
class KaratTile extends StatelessWidget {
  const KaratTile(this.karat, {super.key, this.muted = false});
  final int karat;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return Semantics(
      label: spokenAmounts('$karat karat'),
      excludeSemantics: true,
      child: Container(
        width: 46,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: muted ? c.surfaceSunken : financeTile(context), borderRadius: BorderRadius.circular(Radii.tile)),
        child: Text('${karat}K',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: muted ? c.inkMuted : financeAccent(context))),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.hasPrices});
  final bool hasPrices;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(color: financeTile(context), borderRadius: BorderRadius.circular(Radii.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('No gold items yet', style: text.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: Space.xs),
        Text('Add each piece with its grams, karat and cost. Then set a price per gram for each karat to see an estimated value.',
            style: text.bodyLarge!.copyWith(color: c.inkMuted)),
      ]),
    );
  }
}
