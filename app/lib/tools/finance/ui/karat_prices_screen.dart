import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components/states.dart';
import '../../../core/data/database.dart';
import '../../../core/domain/dates.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/validation.dart';
import '../../../core/domain/weight.dart';
import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/gold.dart';
import '../state/finance_providers.dart';
import 'gold_overview.dart';
import 'savings_parts.dart';
import '../../../core/ui/amounts.dart';

/// Karat prices (W2 · Karat prices): one price per gram per karat, saved
/// with a date. Saving an unchanged price confirms it (it's no longer stale).
/// "New estimated value" previews the totals before saving (F1-04 §4).
class KaratPricesScreen extends ConsumerStatefulWidget {
  const KaratPricesScreen({super.key});

  @override
  ConsumerState<KaratPricesScreen> createState() => _KaratPricesScreenState();
}

class _KaratPricesScreenState extends ConsumerState<KaratPricesScreen> {
  final Map<int, TextEditingController> _fields = {};
  final Map<int, String?> _errors = {};
  final Set<int> _added = {};
  late LocalDate _date = ref.read(todayProvider);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _field(int k, KaratPrice? current) =>
      _fields.putIfAbsent(k, () => TextEditingController(text: current == null ? '' : Money.format(current.pricePerGram).substring(1)));

  bool _dirty(Map<int, KaratPrice> prices) => _fields.entries.any((e) {
    final cur = prices[e.key];
    final t = e.value.text.trim();
    if (cur == null) return t.isNotEmpty;
    return Money.parse(t).valueOrNull != cur.pricePerGram;
  });

  Future<void> _addKarat() async {
    final ctl = TextEditingController();
    final k = await showDialog<int>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        final c = OzoneThemeColors.of(context);
        return AlertDialog(
          backgroundColor: c.surface,
          title: Text('Add a karat', style: Theme.of(context).textTheme.titleLarge),
          content: OzoneTextField(
            label: 'Karat (1–24)',
            controller: ctl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: c.ink, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () {
                final v = int.tryParse(ctl.text);
                if (v != null && v >= 1 && v <= 24) Navigator.of(context).pop(v);
              },
              child: Text(
                'Add',
                style: TextStyle(color: c.ink, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
    ctl.dispose();
    if (k != null) setState(() => _added.add(k));
  }

  Future<void> _save() async {
    final out = <int, int>{};
    var ok = true;
    for (final e in _fields.entries) {
      final t = e.value.text.trim();
      _errors[e.key] = null;
      if (t.isEmpty) continue;
      switch (Money.parse(t)) {
        case Ok(:final value):
          out[e.key] = value;
        case Invalid(:final reason):
          _errors[e.key] = reason;
          ok = false;
      }
    }
    setState(() {});
    if (!ok || out.isEmpty) return;
    setState(() => _saving = true);
    final saved = await guardSave(context, ref.read(errorLogProvider), what: 'save karat prices', () => ref.read(goldRepoProvider).savePrices(_date, out));
    if (!mounted) return;
    if (!saved) return setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final d = ref.watch(goldDataProvider).value;
    final prices = d?.prices ?? const <int, KaratPrice>{};
    final held = d?.held ?? const [];
    final karats = {for (final i in held) i.karat, ...prices.keys, ..._added}.toList()..sort((a, b) => b.compareTo(a));

    // Preview: typed prices where valid, else the current ones.
    final typed = <int, KaratPrice>{...prices};
    for (final k in karats) {
      final v = Money.parse(_field(k, prices[k]).text).valueOrNull;
      if (v != null) typed[k] = KaratPrice(k, v, _date);
    }
    final pieces = d?.pieces ?? const <GoldPiece>[];
    final now = goldTotals(pieces, prices);
    final next = goldTotals(pieces, typed);
    final delta = next.value - now.value;

    return DiscardGuard(
      dirty: _dirty(prices) && !_saving,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              DetailTopBar(
                title: 'Karat prices',
                trailing: [
                  TextButton(
                    onPressed: () => context.push('/finance/gold/prices/history'),
                    child: Text(
                      'History',
                      style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, Space.xl),
                  children: [
                    Text(
                      'Price per gram from the buyer or shop you trust. Each save is kept with its date.',
                      style: text.bodyLarge!.copyWith(fontSize: 14, height: 1.55, color: c.inkMuted),
                    ),
                    const SizedBox(height: Space.m),
                    if (karats.isEmpty)
                      Text('Add a gold item first, or add a karat below.', style: text.bodyLarge)
                    else
                      GroupCard(children: [for (final k in karats) _row(k, prices[k], today)]),
                    const SizedBox(height: Space.m),
                    OzoneButton(label: '+ Add another karat', primary: false, height: 44, onPressed: _addKarat),
                    const SizedBox(height: Space.m),
                    if (held.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.fromLTRB(Space.l, 14, Space.l, 14),
                        decoration: BoxDecoration(color: financeTile(context), borderRadius: BorderRadius.circular(Radii.card)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('New estimated value', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: Space.xs),
                            Text(next.hasValue ? Money.format(next.value) : '—', semanticsLabel: spokenAmounts(next.hasValue ? Money.format(next.value) : '—'), style: text.headlineSmall!.copyWith(fontSize: 26)),
                            const SizedBox(height: Space.xs),
                            Text(
                              delta == 0 ? 'Same as current estimate' : '${Money.change(delta)} vs current estimate', semanticsLabel: spokenAmounts(delta == 0 ? 'Same as current estimate' : '${Money.change(delta)} vs current estimate'),
                              style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: changeColor(c, delta)),
                            ),
                            if (next.unpricedNote != null)
                              Text(next.unpricedNote!, style: text.bodyMedium!.copyWith(fontSize: 12.5, color: c.attentionInk)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.screen, Space.m, Space.screen, Space.xl),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: Space.s,
                      children: [
                        Text('Saved as prices for', style: text.bodyMedium!.copyWith(fontSize: 12.5, color: c.inkMuted)),
                        DateButton(date: _date, today: today, onChanged: (v) => setState(() => _date = v)),
                      ],
                    ),
                    const SizedBox(height: Space.s),
                    OzoneButton(
                      label: 'Save prices',
                      onPressed: _saving || karats.isEmpty ? null : _save,
                      color: financeAccent(context),
                      foreground: c.onAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(int k, KaratPrice? current, LocalDate today) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final items = [
      for (final i in ref.read(goldDataProvider).value?.held ?? const <GoldItemRow>[])
        if (i.karat == k) i,
    ];
    final grams = items.fold<int>(0, (a, i) => a + i.weightMg);
    final age = current?.date.daysUntil(today);
    final used = items.isEmpty ? 'No held items' : '${items.length} ${items.length == 1 ? 'item' : 'items'} · ${Weight.format(grams)}';
    final updated = current == null
        ? 'No price yet'
        : 'Updated ${current.date.format(today)} · ${age == 0
              ? 'today'
              : age == 1
              ? '1 day ago'
              : '$age days ago'}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              KaratTile(k),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(used, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      updated,
                      style: text.labelLarge!.copyWith(fontWeight: FontWeight.w600, color: current == null ? c.attentionInk : c.inkMuted),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                child: Semantics(
                  label: spokenAmounts('${k}K price per gram in pesos'),
                  child: TextField(
                    key: ValueKey('price-$k'),
                    controller: _field(k, current),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: amountFormatters,
                    textAlign: TextAlign.right,
                    onChanged: (_) => setState(() => _errors[k] = null),
                    style: text.titleMedium!.copyWith(fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: c.surfaceSunken,
                      isDense: true,
                      hintText: 'Add price',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: Space.m, right: 4),
                        child: Text(
                          '₱', semanticsLabel: spokenAmounts('₱'),
                          style: text.bodyLarge!.copyWith(color: c.inkMuted, fontWeight: FontWeight.w700),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      suffixText: '/g',
                      suffixStyle: text.labelLarge!.copyWith(color: c.inkMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.tile), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_errors[k] != null) ...[
            const SizedBox(height: 6),
            Text(
              _errors[k]!,
              textAlign: TextAlign.right,
              style: text.bodyMedium!.copyWith(color: c.danger, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

/// Karat prices › History: every saved price, newest first, with delete + Undo.
class KaratHistoryScreen extends ConsumerWidget {
  const KaratHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final rows = ref.watch(goldDataProvider).value?.priceRows ?? const [];
    final byKarat = <int, List<KaratPriceRow>>{};
    for (final r in rows) {
      byKarat.putIfAbsent(r.karat, () => []).add(r);
    }
    final karats = byKarat.keys.toList()..sort((a, b) => b.compareTo(a));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            const DetailTopBar(title: 'Price history', overline: 'Karat prices'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (rows.isEmpty) Text('No prices saved yet.', style: text.bodyLarge),
                  for (final k in karats) ...[
                    SectionLabel('${k}K'),
                    GroupCard(
                      children: [
                        for (final (i, r) in byKarat[k]!.indexed)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.xs, Space.s),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LocalDate.parseIso(r.date).valueOrNull!.formatLong(),
                                        style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      if (i == 0) Text('Current price', style: text.bodyMedium!.copyWith(color: financeAccent(context))),
                                    ],
                                  ),
                                ),
                                Text('${Money.format(r.pricePerGram)}/g', semanticsLabel: spokenAmounts('${Money.format(r.pricePerGram)}/g'), style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                                IconButton(
                                  tooltip: 'Delete this price',
                                  icon: Icon(Icons.delete_outline_rounded, color: c.inkMuted),
                                  onPressed: () => deleteKaratPrice(
                                    ref,
                                    r.id,
                                    '${k}K price of ${LocalDate.parseIso(r.date).valueOrNull!.format(today)}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> deleteKaratPrice(WidgetRef ref, String id, String what) async {
  final repo = ref.read(goldRepoProvider);
  final row = await repo.deletePrice(id);
  await ref
      .read(undoControllerProvider)
      .run(
        message: '$what deleted',
        hideNow: () {},
        commit: () => repo.recordPriceDeleted(row.id),
        restore: () => unawaited(repo.restorePrice(row)),
      );
}
