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
import '../data/expenses_repo.dart';
import '../data/lists_repo.dart';
import '../domain/expenses.dart';
import '../domain/savings_rules.dart';
import '../state/finance_providers.dart';
import 'savings_parts.dart';
import '../../../core/ui/theme/oz_icons.dart';

/// Add expense (W2 · Add expense, flow F3) or edit one. "Save & add another"
/// keeps the date and vendor. Possible duplicates warn but never block (M3-2).
Future<void> showExpenseSheet(BuildContext context, {ExpenseRow? existing}) =>
    showOzoneSheet<void>(context, builder: (_) => _ExpenseSheet(existing: existing));

class _ExpenseSheet extends ConsumerStatefulWidget {
  const _ExpenseSheet({this.existing});
  final ExpenseRow? existing;

  @override
  ConsumerState<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<_ExpenseSheet> {
  late final ExpenseRow? _e = widget.existing;
  late final _item = TextEditingController(text: _e?.item ?? '');
  late final _amount = TextEditingController(text: _e == null ? '' : Money.format(_e.amount).substring(1));
  late final _vendor = TextEditingController(text: _e?.vendor ?? '');
  late final _remarks = TextEditingController(text: _e?.remarks ?? '');
  late LocalDate _date = _e == null ? ref.read(todayProvider) : LocalDate.parseIso(_e.date).valueOrNull!;
  final _itemFocus = FocusNode();
  late String _initial = _snapshot();
  List<String> _vendors = const [];
  String? _itemErr, _amountErr, _vendorErr, _remarksErr, _saved;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(listsRepoProvider).suggestions(ListField.vendor).then((v) => mounted ? setState(() => _vendors = v) : null);
  }

  @override
  void dispose() {
    for (final c in [_item, _amount, _vendor, _remarks]) {
      c.dispose();
    }
    _itemFocus.dispose();
    super.dispose();
  }

  String _snapshot() => [_item.text, _amount.text, _vendor.text, _remarks.text].join('|');

  Future<void> _save({required bool another}) async {
    final today = ref.read(todayProvider);
    final item = validateAccountName(_item.text);
    final amount = Money.parse(_amount.text);
    final vendor = _vendor.text.trim().isEmpty ? const Invalid<String?>('Enter the vendor') : validateOptionalShort(_vendor.text);
    final remarks = validateRemarks(_remarks.text);
    final date = validateNotFuture(_date, today);
    String? r<T>(Validation<T> v) => v is Invalid<T> ? v.reason : null;
    setState(() {
      _itemErr = r(item) == 'Enter a name' ? 'Enter what you bought' : r(item);
      _amountErr = r(amount);
      _vendorErr = r(vendor);
      _remarksErr = r(remarks);
    });
    if (!(item.isOk && amount.isOk && vendor.isOk && remarks.isOk && date.isOk)) return;

    final input = ExpenseInput(
      item: item.valueOrNull!,
      vendor: vendor.valueOrNull!,
      amount: amount.valueOrNull!,
      date: _date,
      remarks: remarks.valueOrNull,
    );
    final all = ref.read(expensesDataProvider).value?.spends ?? const <Spend>[];
    final dups = possibleDuplicates(all, vendor: input.vendor, amount: input.amount, date: input.date, exceptId: _e?.id);
    if (dups.isNotEmpty && mounted) {
      final d = dups.first;
      final go = await confirmDialog(
        context,
        title: 'Possible duplicate',
        body: 'You saved ${Money.format(d.amount)} at ${d.vendor} on ${d.date.format(today).replaceAll(' ', ' ')} (${d.item}). Save this one anyway?',
        confirm: 'Save anyway',
      );
      if (go != true) return;
    }

    if (!mounted) return;
    setState(() => _saving = true);
    final repo = ref.read(expensesRepoProvider);
    final ok = await guardSave(context, ref.read(errorLogProvider), what: 'save expense', () async {
      if (_e == null) {
        await repo.add(input);
      } else {
        await repo.edit(_e.id, input);
      }
    });
    if (!mounted) return;
    if (!ok) return setState(() => _saving = false);
    if (another) {
      // Keep the date and vendor (flow F3).
      setState(() {
        _saving = false;
        _saved = 'Saved ${input.item} · ${Money.format(input.amount)}';
        _item.clear();
        _amount.clear();
        _remarks.clear();
        _initial = _snapshot();
      });
      _itemFocus.requestFocus();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    void changed(String _) => setState(() {});
    return SheetFrame(
      title: _e == null ? 'Add expense' : 'Edit expense',
      dirty: _snapshot() != _initial && !_saving,
      action: Row(children: [
        if (_e == null) ...[
          Expanded(child: OzoneButton(label: 'Save & add another', primary: false, onPressed: _saving ? null : () => _save(another: true))),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: OzoneButton(label: 'Save', onPressed: _saving ? null : () => _save(another: false), color: financeAccent(context), foreground: c.onAccent),
        ),
      ]),
      children: [
        if (_saved != null)
          Semantics(
            liveRegion: true,
            child: Row(children: [
              Icon(OzIcons.checkCircle, fill: 1, size: 18, color: c.gain),
              const SizedBox(width: 6),
              Expanded(child: Text(_saved!, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: c.gain))),
            ]),
          ),
        OzoneTextField(
          label: 'Item',
          controller: _item,
          focusNode: _itemFocus,
          error: _itemErr,
          autofocus: _e == null,
          onChanged: changed,
          textInputAction: TextInputAction.next,
          fieldKey: const ValueKey('expense-item'),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 6,
            child: OzoneTextField(
              label: 'Amount',
              controller: _amount,
              error: _amountErr,
              prefix: '₱ ',
              hint: '0.00',
              large: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: amountFormatters,
              onChanged: changed,
              fieldKey: const ValueKey('expense-amount'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Date', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SizedBox(
                height: 52,
                child: DateButton(date: _date, today: today, onChanged: (d) => setState(() => _date = d)),
              ),
            ]),
          ),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OzoneTextField(
            label: 'Vendor',
            controller: _vendor,
            error: _vendorErr,
            hint: 'Type or pick a recent vendor',
            onChanged: changed,
            fieldKey: const ValueKey('expense-vendor'),
          ),
          SuggestionChips(suggestions: _vendors, typed: _vendor.text, tinted: true, onPick: (v) => setState(() => _vendor.text = v)),
        ]),
        OzoneTextField(label: 'Remarks (optional)', controller: _remarks, error: _remarksErr, maxLines: 2, onChanged: changed),
      ],
    );
  }
}
