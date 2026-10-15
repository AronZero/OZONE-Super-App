import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components/states.dart';
import '../../../core/data/database.dart';
import '../../../core/domain/dates.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/validation.dart';
import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/savings_rules.dart';
import '../state/savings_providers.dart';
import 'savings_parts.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/theme/oz_icons.dart';

/// Update one account's balance, or edit/delete one past update (decision M2-2).
/// An existing update keeps its date; saving a new one on a date that already
/// has an update replaces it (F1-01: one per account per date).
Future<void> showUpdateSheet(BuildContext context, {required String accountId, BalanceUpdateRow? existing}) =>
    showOzoneSheet<void>(context, builder: (_) => _UpdateSheet(accountId: accountId, existing: existing));

class _UpdateSheet extends ConsumerStatefulWidget {
  const _UpdateSheet({required this.accountId, this.existing});
  final String accountId;
  final BalanceUpdateRow? existing;

  @override
  ConsumerState<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends ConsumerState<_UpdateSheet> {
  late final BalanceUpdateRow? _e = widget.existing;
  late final _balance = TextEditingController(text: _e == null || _e.isUnchanged ? '' : _plain(_e.balance));
  late final _remarks = TextEditingController(text: _e?.remarks ?? '');
  late LocalDate _date = _e == null ? ref.read(todayProvider) : LocalDate.parseIso(_e.date).valueOrNull!;
  late bool _unchanged = _e?.isUnchanged ?? false;
  String? _balanceErr, _remarksErr;
  bool _saving = false;

  static String _plain(int c) => Money.format(c).replaceFirst('₱', '');

  @override
  void dispose() {
    _balance.dispose();
    _remarks.dispose();
    super.dispose();
  }

  bool get _dirty {
    final e = _e;
    if (e == null) return _balance.text.trim().isNotEmpty || _remarks.text.trim().isNotEmpty || _unchanged;
    return _remarks.text.trim() != (e.remarks ?? '') ||
        _unchanged != e.isUnchanged ||
        (!_unchanged && Money.parse(_balance.text, allowZero: true).valueOrNull != e.balance);
  }

  Future<void> _save(BalanceUpdateRow? base) async {
    final remarks = validateRemarks(_remarks.text);
    final Validation<int> bal = _unchanged ? Ok(base?.balance ?? 0) : Money.parse(_balance.text, allowZero: true);
    setState(() {
      _balanceErr = bal is Invalid<int> ? bal.reason : null;
      _remarksErr = remarks is Invalid<String?> ? remarks.reason : null;
    });
    if (!bal.isOk || !remarks.isOk) return;
    setState(() => _saving = true);
    final saved = await guardSave(context, ref.read(errorLogProvider), what: 'save balance update', () =>
        ref.read(savingsRepoProvider).saveUpdate(widget.accountId, _date, bal.valueOrNull!, isUnchanged: _unchanged, remarks: remarks.valueOrNull));
    if (!mounted) return;
    if (!saved) return setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final e = _e!;
    final repo = ref.read(savingsRepoProvider);
    final undo = ref.read(undoControllerProvider);
    final today = ref.read(todayProvider);
    Navigator.of(context).pop();
    final row = await repo.deleteUpdate(e.id);
    await undo.run(
      message: 'Update of ${LocalDate.parseIso(row.date).valueOrNull!.format(today)} deleted',
      hideNow: () {},
      commit: () => repo.recordUpdateDeleted(row.id),
      restore: () => unawaited(repo.restoreUpdate(row)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final data = ref.watch(savingsDataProvider).value;
    final account = data?.account(widget.accountId);
    final ups = data?.updatesOf(widget.accountId) ?? const <BalanceUpdateRow>[];
    final iso = _date.toIso();
    BalanceUpdateRow? base, sameDay;
    for (final u in ups) {
      if (u.date.compareTo(iso) < 0) base = u;
      if (u.date == iso && u.id != _e?.id) sameDay = u;
    }
    final typed = Money.parse(_balance.text, allowZero: true).valueOrNull;
    final value = _unchanged ? base?.balance : typed;
    final baseDate = base == null ? null : LocalDate.parseIso(base.date).valueOrNull!;

    return SheetFrame(
      title: _e == null ? 'Update balance' : 'Edit update',
      dirty: _dirty && !_saving,
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OzoneButton(
            label: 'Save',
            onPressed: _saving ? null : () => _save(base),
            color: financeAccent(context),
            foreground: c.onAccent,
          ),
          if (_e != null) ...[
            const SizedBox(height: Space.s),
            TextButton(
              onPressed: _delete,
              child: Text('Delete this update', style: text.bodyLarge!.copyWith(color: c.danger, fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
      children: [
        if (account != null)
          Row(children: [
            AccountTile(account.name),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(account.name, style: text.titleMedium),
                Text(
                  base == null ? 'No earlier balance' : 'Before: ${Money.format(base.balance)} · ${baseDate!.format(today)}', semanticsLabel: spokenAmounts(base == null ? 'No earlier balance' : 'Before: ${Money.format(base.balance)} · ${baseDate!.format(today)}'),
                  style: text.bodyMedium!.copyWith(color: c.inkMuted),
                ),
              ]),
            ),
          ]),
        Row(children: [
          Expanded(child: Text('Balance as of', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700))),
          if (_e == null)
            DateButton(date: _date, today: today, accent: financeAccent(context), tile: financeTile(context), onChanged: (d) => setState(() => _date = d))
          else
            Text(_date.formatLong(), style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
        ]),
        if (sameDay != null)
          Text('Replaces the ${Money.format(sameDay.balance)} saved on ${_date.format(today)}.', semanticsLabel: spokenAmounts('Replaces the ${Money.format(sameDay.balance)} saved on ${_date.format(today)}.'),
              style: text.bodyMedium!.copyWith(color: c.attentionInk, fontWeight: FontWeight.w700)),
        if (_unchanged)
          UnchangedBox(balance: base?.balance ?? 0, month: _date)
        else
          OzoneTextField(
            label: 'New balance',
            controller: _balance,
            error: _balanceErr,
            prefix: '₱ ',
            hint: '0.00',
            large: true,
            autofocus: _e == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: amountFormatters,
            onChanged: (_) => setState(() {}),
            fieldKey: const ValueKey('update-balance'),
          ),
        if (value != null && base != null && !_unchanged)
          Text('${Money.change(value - base.balance)} since ${baseDate!.format(today)}', semanticsLabel: spokenAmounts('${Money.change(value - base.balance)} since ${baseDate.format(today)}'),
              style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: changeColor(c, value - base.balance))),
        if (base != null)
          OzoneButton(
            label: _unchanged ? 'Enter a new balance instead' : 'Balance is unchanged',
            primary: false,
            height: 44,
            onPressed: () => setState(() => _unchanged = !_unchanged),
          ),
        OzoneTextField(label: 'Remarks (optional)', controller: _remarks, error: _remarksErr, maxLines: 2, onChanged: (_) => setState(() {})),
      ],
    );
  }
}

/// "Confirmed unchanged · ₱312,400.00" (W1 · Update balances).
class UnchangedBox extends StatelessWidget {
  const UnchangedBox({super.key, required this.balance, required this.month});
  final int balance;
  final LocalDate month;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 14),
          decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(Radii.tile)),
          child: Row(children: [
            Icon(OzIcons.check, color: c.ink, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Confirmed unchanged · ${Money.format(balance)}', semanticsLabel: spokenAmounts('Confirmed unchanged · ${Money.format(balance)}'), style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700))),
          ]),
        ),
        const SizedBox(height: 6),
        Text('${month.monthName} will show as Recorded, not Carried.', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
      ],
    );
  }
}
