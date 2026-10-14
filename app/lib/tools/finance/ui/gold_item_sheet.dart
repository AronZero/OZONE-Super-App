import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../data/gold_repo.dart';
import '../data/lists_repo.dart';
import '../domain/gold.dart';
import '../domain/savings_rules.dart';
import '../state/finance_providers.dart';
import 'savings_parts.dart';

/// Add or edit a gold item in one sheet (decision M3-1): name, grams, karat,
/// vendor, purchase date, cost, remarks, Held/Disposed, and Delete with Undo.
Future<void> showGoldItemSheet(BuildContext context, {GoldItemRow? existing}) =>
    showOzoneSheet<void>(context, builder: (_) => _GoldItemSheet(existing: existing));


class _GoldItemSheet extends ConsumerStatefulWidget {
  const _GoldItemSheet({this.existing});
  final GoldItemRow? existing;

  @override
  ConsumerState<_GoldItemSheet> createState() => _GoldItemSheetState();
}

class _GoldItemSheetState extends ConsumerState<_GoldItemSheet> {
  late final GoldItemRow? _e = widget.existing;
  late final _name = TextEditingController(text: _e?.name ?? '');
  late final _weight = TextEditingController(text: _e == null ? '' : Weight.plain(_e.weightMg));
  late final _karat = TextEditingController(text: _e?.karat.toString() ?? '');
  late final _vendor = TextEditingController(text: _e?.vendor ?? '');
  late final _cost = TextEditingController(text: _e == null ? '' : Money.format(_e.cost).substring(1));
  late final _remarks = TextEditingController(text: _e?.remarks ?? '');
  late LocalDate _bought = _e == null ? ref.read(todayProvider) : LocalDate.parseIso(_e.purchaseDate).valueOrNull!;
  late LocalDate? _disposed = _e?.disposedDate == null ? null : LocalDate.parseIso(_e!.disposedDate!).valueOrNull;
  late final String _initial = _snapshot();
  List<String> _vendors = const [];
  final Map<String, String?> _err = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(listsRepoProvider).suggestions(ListField.vendor).then((v) => mounted ? setState(() => _vendors = v) : null);
  }

  @override
  void dispose() {
    for (final c in [_name, _weight, _karat, _vendor, _cost, _remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  String _snapshot() =>
      [_name.text, _weight.text, _karat.text, _vendor.text, _cost.text, _remarks.text, _bought.toIso(), _disposed?.toIso()].join('|');

  Validation<int> _karatValue() {
    final k = int.tryParse(_karat.text.trim());
    if (k == null) return const Invalid('Enter the karat, like 18');
    if (k < 1 || k > 24) return const Invalid('Karat is between 1 and 24');
    return Ok(k);
  }

  Future<void> _save() async {
    final today = ref.read(todayProvider);
    final name = validateAccountName(_name.text);
    final weight = Weight.parse(_weight.text);
    final karat = _karatValue();
    final vendor = validateOptionalShort(_vendor.text);
    final cost = Money.parse(_cost.text);
    final remarks = validateRemarks(_remarks.text);
    final bought = validateNotFuture(_bought, today);
    final d = _disposed;
    final Validation<LocalDate?> disposed = d == null
        ? const Ok(null)
        : d.isAfter(today)
            ? const Invalid('Pick today or an earlier date')
            : d.isBefore(_bought)
                ? const Invalid('It can’t be disposed before it was bought')
                : Ok(d);
    String? r<T>(Validation<T> v) => v is Invalid<T> ? v.reason : null;
    setState(() {
      _err
        ..['name'] = r(name)
        ..['weight'] = r(weight)
        ..['karat'] = r(karat)
        ..['vendor'] = r(vendor)
        ..['cost'] = r(cost)
        ..['remarks'] = r(remarks)
        ..['bought'] = r(bought)
        ..['disposed'] = r(disposed);
    });
    if (_err.values.any((e) => e != null)) return;
    setState(() => _saving = true);
    final input = GoldItemInput(
      name: name.valueOrNull!,
      weightMg: weight.valueOrNull!,
      karat: karat.valueOrNull!,
      vendor: vendor.valueOrNull,
      purchaseDate: _bought,
      cost: cost.valueOrNull!,
      disposedDate: disposed.valueOrNull,
      remarks: remarks.valueOrNull,
    );
    final repo = ref.read(goldRepoProvider);
    if (_e == null) {
      await repo.addItem(input);
    } else {
      await repo.editItem(_e.id, input);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final e = _e!;
    final repo = ref.read(goldRepoProvider);
    final undo = ref.read(undoControllerProvider);
    Navigator.of(context).pop();
    final row = await repo.deleteItem(e.id);
    await undo.run(
      message: '${row.name} deleted',
      hideNow: () {},
      commit: () => repo.recordItemDeleted(row.id),
      restore: () => unawaited(repo.restoreItem(row)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final gold = ref.watch(goldDataProvider).value;
    final prices = gold?.prices ?? const <int, KaratPrice>{};
    final choices = karatChoices([...?gold?.items.map((i) => i.karat), ...?gold?.priceRows.map((p) => p.karat)]);
    final k = _karatValue().valueOrNull;
    final w = Weight.parse(_weight.text).valueOrNull;
    final price = k == null ? null : prices[k];
    void changed([String? _]) => setState(() {});
    final label = text.bodyMedium!.copyWith(fontWeight: FontWeight.w700);

    return SheetFrame(
      title: _e == null ? 'Add gold item' : 'Edit gold item',
      dirty: _snapshot() != _initial && !_saving,
      action: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        OzoneButton(label: _e == null ? 'Add item' : 'Save', onPressed: _saving ? null : _save, color: financeAccent(context), foreground: c.onAccent),
        if (_e != null) ...[
          const SizedBox(height: Space.s),
          TextButton(
            onPressed: _delete,
            child: Text('Delete item', style: text.bodyLarge!.copyWith(color: c.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ]),
      children: [
        OzoneTextField(label: 'Name', controller: _name, error: _err['name'], hint: 'Gold bangle', autofocus: _e == null, onChanged: changed, fieldKey: const ValueKey('gold-name')),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 6,
            child: OzoneTextField(
              label: 'Weight (grams, no stones)',
              controller: _weight,
              error: _err['weight'],
              hint: '0.000',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              onChanged: changed,
              fieldKey: const ValueKey('gold-weight'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: OzoneTextField(
              label: 'Karat',
              controller: _karat,
              error: _err['karat'],
              hint: '18',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
              onChanged: changed,
              fieldKey: const ValueKey('gold-karat'),
            ),
          ),
        ]),
        Wrap(spacing: Space.s, runSpacing: Space.s, children: [
          for (final kk in choices)
            ChoiceChip(
              // No hidden 48 dp tap padding: wrapped rows keep the same gap as the columns.
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              label: Text('${kk}K'),
              selected: k == kk,
              showCheckmark: false,
              selectedColor: financeAccent(context),
              backgroundColor: financeTile(context),
              side: BorderSide.none,
              shape: const StadiumBorder(),
              labelStyle: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: k == kk ? c.onAccent : financeAccent(context)),
              onSelected: (_) => setState(() => _karat.text = '$kk'),
            ),
        ]),
        if (w != null && k != null)
          Text(
            price == null
                ? 'No ${k}K price yet. You can still save it; set the price in Karat prices.'
                : 'Estimated ${Money.format(itemValue(w, price.pricePerGram))} at ${Money.format(price.pricePerGram)}/g (${price.date.format(today)})',
            style: text.bodyMedium!.copyWith(color: price == null ? c.attentionInk : c.inkMuted, fontWeight: FontWeight.w700),
          ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OzoneTextField(label: 'Vendor (optional)', controller: _vendor, error: _err['vendor'], onChanged: changed),
          SuggestionChips(
            suggestions: _vendors,
            typed: _vendor.text,
            onPick: (v) => setState(() => _vendor.text = v),
          ),
        ]),
        Row(children: [
          Expanded(child: Text('Purchase date', style: label)),
          DateButton(date: _bought, today: today, accent: financeAccent(context), tile: financeTile(context), onChanged: (d) => setState(() => _bought = d)),
        ]),
        if (_err['bought'] != null) Text(_err['bought']!, style: text.bodyMedium!.copyWith(color: c.danger, fontWeight: FontWeight.w700)),
        OzoneTextField(
          label: 'Cost',
          controller: _cost,
          error: _err['cost'],
          prefix: '₱ ',
          hint: '0.00',
          large: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: amountFormatters,
          onChanged: changed,
          fieldKey: const ValueKey('gold-cost'),
        ),
        SegmentTabs(
          labels: const ['Held', 'Disposed'],
          selected: _disposed == null ? 0 : 1,
          onSelected: (i) => setState(() => _disposed = i == 0 ? null : (_disposed ?? today)),
        ),
        if (_disposed != null) ...[
          Row(children: [
            Expanded(child: Text('Disposed on', style: label)),
            DateButton(date: _disposed!, today: today, onChanged: (d) => setState(() => _disposed = d)),
          ]),
          Text(
            _err['disposed'] ?? 'Disposed items are kept but left out of every total.',
            style: text.bodyMedium!.copyWith(color: _err['disposed'] == null ? c.inkMuted : c.danger, fontWeight: FontWeight.w700),
          ),
        ],
        OzoneTextField(label: 'Remarks (optional)', controller: _remarks, error: _err['remarks'], maxLines: 3, onChanged: changed),
      ],
    );
  }
}
