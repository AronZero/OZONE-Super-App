import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/domain/dates.dart';
import '../../../core/domain/validation.dart';
import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../../../core/state/undo.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/charts/month_bars.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/savings_repo.dart';
import '../domain/savings_history.dart';
import '../state/savings_providers.dart';
import 'account_sheet.dart';
import 'savings_parts.dart';
import 'update_sheet.dart';
import '../../../core/ui/theme/oz_icons.dart';

/// Account detail (W1 · Account detail): balance card, then By month /
/// All updates / Chart. The menu edits, archives (or restores) and deletes.
class AccountDetailScreen extends ConsumerStatefulWidget {
  const AccountDetailScreen({super.key, required this.accountId});
  final String accountId;

  @override
  ConsumerState<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

enum _Menu { edit, archive, restore, delete }

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  int _tab = 0;

  Future<void> _onMenu(_Menu m, SavingsAccountRow a, int updates) async {
    final repo = ref.read(savingsRepoProvider);
    final undo = ref.read(undoControllerProvider);
    switch (m) {
      case _Menu.edit:
        await showAccountSheet(context, existing: a);
      case _Menu.archive:
        await _archive(repo, undo, a);
      case _Menu.restore:
        final r = await repo.restore(a.id);
        if (!mounted) return;
        if (r is Invalid<void>) {
          await confirmDialog(context, title: 'Can’t restore yet', body: r.reason, confirm: 'OK', cancel: 'Close');
          return;
        }
        final was = LocalDate.parseIso(a.archivedAt!).valueOrNull!;
        await undo.run(
          message: '${a.name} is back in Savings',
          hideNow: () {},
          commit: () async {},
          restore: () => unawaited(repo.archive(a.id, was)),
        );
      case _Menu.delete:
        final choice = await showDialog<_Menu>(
          context: context,
          useRootNavigator: true,
          builder: (context) => _DeleteDialog(name: a.name, updates: updates, archived: a.archivedAt != null),
        );
        if (!mounted || choice == null) return;
        if (choice == _Menu.archive) {
          await _archive(repo, undo, a);
        } else if (choice == _Menu.delete) {
          Navigator.of(context).pop();
          await repo.deleteAccount(a.id);
        }
    }
  }

  Future<void> _archive(SavingsRepo repo, UndoController undo, SavingsAccountRow a) async {
    await repo.archive(a.id, ref.read(todayProvider));
    await undo.run(
      message: '${a.name} archived',
      hideNow: () {},
      commit: () async {},
      restore: () => unawaited(repo.restore(a.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final data = ref.watch(savingsDataProvider).value;
    final a = data?.account(widget.accountId);
    final h = data?.history(widget.accountId);

    if (data == null || a == null || h == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(children: [
            const DetailTopBar(title: 'Account'),
            if (data != null) Padding(padding: const EdgeInsets.all(Space.xl), child: Text('This account no longer exists.', style: text.bodyLarge)),
          ]),
        ),
      );
    }

    final ups = data.updatesOf(a.id);
    final archived = a.archivedAt != null;
    final archivedAt = archived ? LocalDate.parseIso(a.archivedAt!).valueOrNull! : null;
    final lastMonth = monthOf(archivedAt != null && archivedAt.isBefore(today) ? archivedAt : today);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            DetailTopBar(title: a.name, trailing: [
              PopupMenuButton<_Menu>(
                tooltip: 'Account options',
                icon: Icon(OzIcons.moreVert, color: c.ink),
                color: c.surface,
                onSelected: (m) => _onMenu(m, a, ups.length),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: _Menu.edit, child: Text('Edit')),
                  if (archived)
                    const PopupMenuItem(value: _Menu.restore, child: Text('Restore'))
                  else
                    const PopupMenuItem(value: _Menu.archive, child: Text('Archive')),
                  PopupMenuItem(value: _Menu.delete, child: Text('Delete', style: TextStyle(color: c.danger))),
                ],
              ),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(account: a, history: h, archivedAt: archivedAt),
                  const SizedBox(height: Space.m),
                  SegmentTabs(
                    labels: ['By month', 'All updates · ${ups.length}', 'Chart'],
                    selected: _tab,
                    onSelected: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: Space.m),
                  switch (_tab) {
                    0 => _ByMonth(history: h, lastMonth: lastMonth),
                    1 => _AllUpdates(accountId: a.id, updates: ups),
                    _ => _Chart(history: h, lastMonth: lastMonth),
                  },
                  if (_tab == 0) ...[
                    const SizedBox(height: Space.m),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                      child: Text(
                        'A carried month repeats the last known balance so totals stay complete. It’s never counted as a change. '
                        'Add a past update with its real date to replace it.',
                        style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.5, color: c.inkMuted),
                      ),
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

class _Header extends ConsumerWidget {
  const _Header({required this.account, required this.history, required this.archivedAt});
  final SavingsAccountRow account;
  final AccountHistory history;
  final LocalDate? archivedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final last = history.latest;
    final first = history.first;
    final facts = [
      ?account.platform,
      ?account.type,
      if (first != null) 'tracked since ${first.date.monthShort} ${first.date.year}',
    ].join(' · ');
    final change = accountChange(history, today, monthOf(today).addMonths(-1), today);
    final carried = monthBalance(history, today, today).status == MonthStatus.carried;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, Space.l, 18, Space.l),
      decoration: BoxDecoration(color: financeTile(context), borderRadius: BorderRadius.circular(Radii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (facts.isNotEmpty) Text(facts, style: text.bodyMedium!.copyWith(color: c.inkMuted)),
          const SizedBox(height: Space.s),
          Text(money(context, last?.balance ?? 0), semanticsLabel: spokenAmounts(money(context, last?.balance ?? 0)), style: text.displaySmall!.copyWith(fontSize: 32, letterSpacing: -0.6)),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (archivedAt == null && change is CountedChange)
                ChangePill(amount: change.amount, suffix: ' vs ${monthOf(today).addMonths(-1).monthShort}'),
              if (archivedAt != null)
                Text('Archived ${archivedAt!.format(today)}', style: text.bodyMedium!.copyWith(color: c.inkMuted))
              else if (last != null && carried)
                DashedPill('Carried · ${last.date.format(today)}')
              else if (last != null)
                Text('Updated ${last.date.format(today)}', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
            ],
          ),
          if (archivedAt == null) ...[
            const SizedBox(height: Space.m),
            OzoneButton(
              label: 'Update balance',
              height: 48,
              color: financeAccent(context),
              foreground: c.onAccent,
              onPressed: () => showUpdateSheet(context, accountId: account.id),
            ),
          ],
        ],
      ),
    );
  }
}


/// Month rows from the latest month back to the first update (up to 5 years),
/// then one "No data (before tracking)" row.
class _ByMonth extends ConsumerWidget {
  const _ByMonth({required this.history, required this.lastMonth});
  final AccountHistory history;
  final LocalDate lastMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final first = history.first;
    if (first == null) return const SizedBox.shrink();
    final firstMonth = monthOf(first.date);
    final months = <LocalDate>[];
    for (var m = lastMonth; !m.isBefore(firstMonth) && months.length < 60; m = m.addMonths(-1)) {
      months.add(m);
    }
    final head = text.labelSmall!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted);
    return _Table(
      header: [Text('Month', style: head), Text('Month-end balance', style: head), Text('Change', style: head, textAlign: TextAlign.right)],
      rows: [
        for (final m in months) _monthRow(context, m, today, firstMonth),
        if (months.length < 60)
          [
            Text(firstMonth.addMonths(-1).monthShortYear, style: text.bodyMedium!.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: c.inkMuted)),
            Text('— No data (before tracking)', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
            Text('—', textAlign: TextAlign.right, style: text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.inkMuted)),
          ],
      ],
    );
  }

  List<Widget> _monthRow(BuildContext context, LocalDate m, LocalDate today, LocalDate firstMonth) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final mb = monthBalance(history, m, today);
    final carried = mb.status == MonthStatus.carried;
    final u = mb.update!;
    final note = [
      '● Recorded',
      if (m == monthOf(today)) 'so far',
      if (m == firstMonth) 'first update ${u.date.day} ${u.date.monthShort}',
      if (u.isUnchanged && !carried) 'unchanged',
    ].join(' · ');
    final change = accountChange(history, m, m.addMonths(-1), today);
    final muted = text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.inkMuted);
    return [
      Text(m.monthShortYear, style: text.bodyMedium!.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: carried ? c.inkMuted : c.ink)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(money(context, u.balance), semanticsLabel: spokenAmounts(money(context, u.balance)), style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800, color: carried ? c.inkMuted : c.ink)),
        const SizedBox(height: 3),
        if (carried) DashedPill('Carried from ${u.date.monthShort}') else Text(note, style: text.labelSmall!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
      ]),
      switch (change) {
        CountedChange(:final amount, :final base) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(moneyChange(context, amount), semanticsLabel: spokenAmounts(moneyChange(context, amount)), textAlign: TextAlign.right, style: text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800, color: changeColor(c, amount))),
            if (base.status == MonthStatus.carried)
              Text('vs ${base.update!.date.monthShort}', style: text.labelSmall!.copyWith(fontSize: 11, color: c.inkMuted)),
          ]),
        StartChange() => Text('Start', textAlign: TextAlign.right, style: muted),
        NotCounted() => Text('Not counted', textAlign: TextAlign.right, style: muted),
        NoChangeData() => Text('—', textAlign: TextAlign.right, style: muted),
      },
    ];
  }
}

/// A three-column table in a white card, as on the W1/W3 boards.
class _Table extends StatelessWidget {
  const _Table({required this.header, required this.rows});
  final List<Widget> header;
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    Widget row(List<Widget> cells, {Color? bg, double minHeight = 56, bool top = true}) => Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 10),
          decoration: BoxDecoration(color: bg, border: top ? Border(top: BorderSide(color: c.surfaceSunken.withValues(alpha: 0.7))) : null),
          child: Row(children: [
            SizedBox(width: 76, child: cells[0]),
            const SizedBox(width: Space.s),
            Expanded(child: cells[1]),
            const SizedBox(width: Space.s),
            SizedBox(width: 118, child: Align(alignment: Alignment.centerRight, child: cells[2])),
          ]),
        );
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        row(header, bg: Color.alphaBlend(c.surfaceSunken.withValues(alpha: 0.35), c.surface), minHeight: 0, top: false),
        for (final r in rows) row(r),
      ]),
    );
  }
}

class _AllUpdates extends ConsumerWidget {
  const _AllUpdates({required this.accountId, required this.updates});
  final String accountId;
  final List<BalanceUpdateRow> updates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final newest = updates.reversed.toList();
    return GroupCard(children: [
      for (final u in newest)
        Semantics(
          button: true,
          label: '${LocalDate.parseIso(u.date).valueOrNull!.formatLong()}, ${moneySpoken(context, u.balance)}${u.isUnchanged ? ', unchanged' : ''}. Edit',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => showUpdateSheet(context, accountId: accountId, existing: u),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(LocalDate.parseIso(u.date).valueOrNull!.format(today), style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                    if (u.isUnchanged || u.remarks != null)
                      Text([if (u.isUnchanged) 'Unchanged', ?u.remarks].join(' · '),
                          maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                  ]),
                ),
                Text(money(context, u.balance), semanticsLabel: spokenAmounts(money(context, u.balance)), style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: Space.xs),
                Icon(OzIcons.chevronRight, color: c.inkMuted),
              ]),
            ),
          ),
        ),
    ]);
  }
}

class _Chart extends ConsumerWidget {
  const _Chart({required this.history, required this.lastMonth});
  final AccountHistory history;
  final LocalDate lastMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final months = monthsEndingWith(lastMonth, 12);
    final bars = [
      for (final m in months)
        () {
          final mb = monthBalance(history, m, today);
          return BarDatum(m.monthShort, mb.balance, dashed: mb.status == MonthStatus.carried, highlight: m == monthOf(today));
        }(),
    ];
    final withData = [for (var i = 0; i < bars.length; i++) if (bars[i].value != null) i];
    final label = withData.isEmpty
        ? 'Month-end balances chart. No data yet.'
        : 'Month-end balances for ${history.name}, from ${money(context, bars[withData.first].value!)} in ${months[withData.first].monthName} '
            'to ${money(context, bars[withData.last].value!)} in ${months[withData.last].monthName}. The By month tab lists every value.';
    return Container(
      padding: const EdgeInsets.all(Space.l),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Month-end balance · last 12 months', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: Space.m),
        MonthBars(data: bars, accent: financeAccent(context), labelColor: c.inkMuted, height: 140, semanticLabel: label),
        const SizedBox(height: Space.s),
        Text('Dashed bars are carried months. Empty months have no data.', style: text.labelSmall!.copyWith(color: c.inkMuted)),
      ]),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.name, required this.updates, required this.archived});
  final String name;
  final int updates;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final n = '$updates balance ${updates == 1 ? 'update' : 'updates'}';
    return AlertDialog(
      backgroundColor: c.surface,
      title: Text('Delete $name?', style: text.titleLarge),
      content: Text(
        'This deletes the account and its $n. It can’t be undone.'
        '${archived ? '' : '\n\nTo keep its history, archive it instead.'}',
        style: text.bodyLarge,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: TextStyle(color: c.ink, fontWeight: FontWeight.w800))),
        if (!archived)
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Menu.archive),
            child: Text('Archive instead', style: TextStyle(color: c.ink, fontWeight: FontWeight.w800)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_Menu.delete),
          child: Text('Delete', style: TextStyle(color: c.danger, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
