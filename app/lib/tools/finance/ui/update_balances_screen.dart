import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/providers.dart';
import '../../../core/ui/components/states.dart';
import '../../../core/data/database.dart';
import '../../../core/domain/dates.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/validation.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/savings_repo.dart';
import '../state/savings_providers.dart';
import 'savings_parts.dart';
import 'update_sheet.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/theme/oz_icons.dart';

/// Update balances (W1 · Update balances, flow F2): every open account on one
/// screen for one date. "Balance is unchanged" saves the last balance and makes
/// the month Recorded. Blank cards are skipped. Everything saves in one transaction.
class UpdateBalancesScreen extends ConsumerStatefulWidget {
  const UpdateBalancesScreen({super.key});

  @override
  ConsumerState<UpdateBalancesScreen> createState() => _UpdateBalancesScreenState();
}

class _Entry {
  final controller = TextEditingController();
  bool unchanged = false;
  String? error;
}

class _UpdateBalancesScreenState extends ConsumerState<UpdateBalancesScreen> {
  late LocalDate _date = ref.read(todayProvider);
  final Map<String, _Entry> _entries = {};
  final Set<String> _editing = {};
  bool _saving = false;

  _Entry _entry(String id) => _entries.putIfAbsent(id, _Entry.new);

  @override
  void dispose() {
    for (final e in _entries.values) {
      e.controller.dispose();
    }
    super.dispose();
  }

  bool get _dirty => _entries.values.any((e) => e.unchanged || e.controller.text.trim().isNotEmpty);

  /// The value a card will save, or null when it's blank or invalid.
  int? _value(_Entry e, BalanceUpdateRow? base) {
    if (e.unchanged) return base?.balance;
    final t = e.controller.text.trim();
    return t.isEmpty ? null : Money.parse(t, allowZero: true).valueOrNull;
  }

  Future<void> _save(List<_Card> cards) async {
    var ok = true;
    final out = <UpdateEntry>[];
    for (final card in cards) {
      final e = _entries[card.account.id];
      if (e == null) continue;
      e.error = null;
      if (e.unchanged) {
        out.add(UpdateEntry(card.account.id, card.base!.balance, isUnchanged: true));
      } else if (e.controller.text.trim().isNotEmpty) {
        switch (Money.parse(e.controller.text, allowZero: true)) {
          case Ok(:final value):
            out.add(UpdateEntry(card.account.id, value));
          case Invalid(:final reason):
            e.error = reason;
            ok = false;
        }
      }
    }
    setState(() {});
    if (!ok || out.isEmpty) return;
    setState(() => _saving = true);
    final saved = await guardSave(context, ref.read(errorLogProvider), what: 'save balances', () => ref.read(savingsRepoProvider).saveUpdates(_date, out));
    if (!mounted) return;
    if (!saved) return setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final data = ref.watch(savingsDataProvider).value;
    final iso = _date.toIso();
    final monthPrefix = iso.substring(0, 7);

    final cards = <_Card>[];
    for (final a in data?.accounts ?? const <SavingsAccountRow>[]) {
      if (a.archivedAt != null) continue;
      BalanceUpdateRow? base, sameDay, inMonth;
      for (final u in data!.updatesOf(a.id)) {
        if (u.date.compareTo(iso) < 0) base = u;
        if (u.date == iso) sameDay = u;
        if (u.date.startsWith(monthPrefix)) inMonth = u;
      }
      cards.add(_Card(a, base, sameDay, inMonth));
    }
    cards.sort((x, y) => x.account.name.toLowerCase().compareTo(y.account.name.toLowerCase()));
    final due = [for (final k in cards) if (k.inMonth == null) k];
    final done = [for (final k in cards) if (k.inMonth != null) k];

    var newTotal = 0, count = 0;
    for (final k in cards) {
      final e = _entries[k.account.id];
      final v = e == null ? null : _value(e, k.base);
      if (v != null) count++;
      final current = v ?? k.sameDay?.balance ?? k.base?.balance;
      if (current != null) newTotal += current;
    }
    final monthName = _date.monthName;
    final article = RegExp(r'^[AEIOU]').hasMatch(monthName) ? 'an' : 'a';

    return DiscardGuard(
      dirty: _dirty && !_saving,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const DetailTopBar(title: 'Update balances'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, Space.xl),
                  children: [
                    Row(children: [
                      Expanded(child: Text('Balances as of', style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.inkMuted))),
                      DateButton(
                        date: _date,
                        today: today,
                        accent: financeAccent(context),
                        tile: financeTile(context),
                        onChanged: (d) => setState(() {
                          _date = d;
                          _editing.clear();
                        }),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    if (cards.isEmpty)
                      Text('Add an account first. Its starting balance is its first update.', style: text.bodyLarge),
                    if (due.isNotEmpty) ...[
                      Row(children: [
                        Icon(OzIcons.error, size: 16, color: c.attentionInk),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('Needs $article $monthName balance · ${due.length}',
                              style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.attentionInk)),
                        ),
                      ]),
                      const SizedBox(height: Space.m),
                      for (final k in due) ...[_editor(k), const SizedBox(height: Space.m)],
                    ],
                    if (done.isNotEmpty) ...[
                      const SizedBox(height: Space.xs),
                      Text('Already updated in $monthName · ${done.length}',
                          style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted)),
                      const SizedBox(height: Space.m),
                      for (final k in done.where((k) => _editing.contains(k.account.id))) ...[_editor(k), const SizedBox(height: Space.m)],
                      if (done.any((k) => !_editing.contains(k.account.id)))
                        GroupCard(children: [
                          for (final k in done.where((k) => !_editing.contains(k.account.id))) _doneRow(k, today),
                        ]),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(Space.screen, Space.m, Space.screen, Space.xl),
                decoration: BoxDecoration(color: c.canvas, border: Border(top: BorderSide(color: c.outline.withValues(alpha: 0.6)))),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: Text('New total', style: text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.inkMuted))),
                    Text(Money.format(newTotal), semanticsLabel: spokenAmounts(Money.format(newTotal)), style: text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: Space.s),
                  OzoneButton(
                    label: count == 0 ? 'Save' : 'Save $count ${count == 1 ? 'update' : 'updates'}',
                    onPressed: count == 0 || _saving ? null : () => _save(cards),
                    color: financeAccent(context),
                    foreground: c.onAccent,
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _doneRow(_Card k, LocalDate today) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final u = k.inMonth!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k.account.name, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
            Text(LocalDate.parseIso(u.date).valueOrNull!.format(today), style: text.bodyMedium!.copyWith(color: c.inkMuted)),
          ]),
        ),
        Text(Money.format(u.balance), semanticsLabel: spokenAmounts(Money.format(u.balance)), style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(width: Space.m),
        Semantics(
          button: true,
          label: spokenAmounts('Edit ${k.account.name}'),
          onTap: () => setState(() => _editing.add(k.account.id)),
          excludeSemantics: true,
          child: FilledButton(
            onPressed: () => setState(() => _editing.add(k.account.id)),
            style: FilledButton.styleFrom(
              backgroundColor: c.surfaceSunken,
              foregroundColor: c.ink,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: Space.m),
              shape: const StadiumBorder(),
            ),
            child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _editor(_Card k) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.read(todayProvider);
    final e = _entry(k.account.id);
    final base = k.base;
    final baseDate = base == null ? null : LocalDate.parseIso(base.date).valueOrNull!;
    final v = _value(e, base);
    return Container(
      padding: const EdgeInsets.all(Space.l),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            AccountTile(k.account.name),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k.account.name, style: text.titleMedium),
                Text(base == null ? 'No earlier balance' : 'Last: ${Money.format(base.balance)} · ${baseDate!.format(today)}', semanticsLabel: spokenAmounts(base == null ? 'No earlier balance' : 'Last: ${Money.format(base.balance)} · ${baseDate!.format(today)}'),
                    style: text.bodyMedium!.copyWith(color: c.inkMuted)),
              ]),
            ),
          ]),
          const SizedBox(height: Space.m),
          if (e.unchanged)
            UnchangedBox(balance: base!.balance, month: _date)
          else ...[
            OzoneTextField(
              label: 'New balance',
              controller: e.controller,
              error: e.error,
              prefix: '₱ ',
              hint: k.sameDay == null ? '0.00' : Money.format(k.sameDay!.balance).substring(1),
              large: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: amountFormatters,
              onChanged: (_) => setState(() => e.error = null),
              fieldKey: ValueKey('new-balance-${k.account.id}'),
            ),
            if (v != null && base != null) ...[
              const SizedBox(height: 6),
              Text('${Money.change(v - base.balance)} since ${baseDate!.format(today)}', semanticsLabel: spokenAmounts('${Money.change(v - base.balance)} since ${baseDate.format(today)}'),
                  style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: changeColor(c, v - base.balance))),
            ],
          ],
          if (base != null) ...[
            const SizedBox(height: Space.m),
            OzoneButton(
              label: e.unchanged ? 'Enter a new balance instead' : 'Balance is unchanged',
              primary: false,
              height: 44,
              onPressed: () => setState(() => e.unchanged = !e.unchanged),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card {
  _Card(this.account, this.base, this.sameDay, this.inMonth);
  final SavingsAccountRow account;

  /// The latest update before the chosen date: what "unchanged" repeats.
  final BalanceUpdateRow? base;

  /// An update already saved on the chosen date (saving replaces it).
  final BalanceUpdateRow? sameDay;

  /// The latest update in the chosen date's month.
  final BalanceUpdateRow? inMonth;
}
