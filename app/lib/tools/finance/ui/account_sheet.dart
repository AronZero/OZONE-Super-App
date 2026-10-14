import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/domain/dates.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/validation.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../data/lists_repo.dart';
import '../state/finance_providers.dart';
import '../domain/savings_rules.dart';
import '../state/savings_providers.dart';
import 'savings_parts.dart';

/// Add account (or edit one when [existing] is given). Decision M2-1:
/// Name, Platform, Type, Starting balance, Balance as of, Remarks.
/// Editing has no balance or date: balances change through updates.
Future<void> showAccountSheet(BuildContext context, {SavingsAccountRow? existing}) =>
    showOzoneSheet<void>(context, builder: (_) => _AccountSheet(existing: existing));

class _AccountSheet extends ConsumerStatefulWidget {
  const _AccountSheet({this.existing});
  final SavingsAccountRow? existing;

  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _platform = TextEditingController(text: widget.existing?.platform ?? '');
  late final _type = TextEditingController(text: widget.existing?.type ?? '');
  late final _remarks = TextEditingController(text: widget.existing?.remarks ?? '');
  final _balance = TextEditingController();
  late LocalDate _asOf = ref.read(todayProvider);
  late final LocalDate _initialAsOf = _asOf;

  List<String> _platforms = const [], _types = const [];
  String? _nameErr, _platformErr, _typeErr, _balanceErr, _remarksErr;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final lists = ref.read(listsRepoProvider);
    lists.suggestions(ListField.platform).then((v) => mounted ? setState(() => _platforms = v) : null);
    lists.suggestions(ListField.type).then((v) => mounted ? setState(() => _types = v) : null);
  }

  @override
  void dispose() {
    for (final c in [_name, _platform, _type, _remarks, _balance]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _dirty {
    final e = widget.existing;
    return _name.text.trim() != (e?.name ?? '') ||
        _platform.text.trim() != (e?.platform ?? '') ||
        _type.text.trim() != (e?.type ?? '') ||
        _remarks.text.trim() != (e?.remarks ?? '') ||
        _balance.text.trim().isNotEmpty ||
        _asOf != _initialAsOf;
  }

  String? _err<T>(Validation<T> v) => v is Invalid<T> ? v.reason : null;

  Future<void> _save() async {
    final name = validateAccountName(_name.text);
    final platform = validateOptionalShort(_platform.text);
    final type = validateOptionalShort(_type.text);
    final remarks = validateRemarks(_remarks.text);
    final balance = _editing ? const Ok(0) : Money.parse(_balance.text, allowZero: true);
    setState(() {
      _nameErr = _err(name);
      _platformErr = _err(platform);
      _typeErr = _err(type);
      _remarksErr = _err(remarks);
      _balanceErr = _err(balance);
    });
    if (!(name.isOk && platform.isOk && type.isOk && remarks.isOk && balance.isOk)) return;
    setState(() => _saving = true);
    final repo = ref.read(savingsRepoProvider);
    final Validation<Object?> r = _editing
        ? await repo.editAccount(widget.existing!.id,
            name: name.valueOrNull!, platform: platform.valueOrNull, type: type.valueOrNull, remarks: remarks.valueOrNull)
        : await repo.addAccount(
            name: name.valueOrNull!,
            platform: platform.valueOrNull,
            type: type.valueOrNull,
            remarks: remarks.valueOrNull,
            startBalance: balance.valueOrNull!,
            asOf: _asOf,
          );
    if (!mounted) return;
    if (r is Invalid<Object?>) {
      setState(() {
        _saving = false;
        _nameErr = r.reason;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final today = ref.watch(todayProvider);
    void changed(String _) => setState(() {});
    return SheetFrame(
      title: _editing ? 'Edit account' : 'Add account',
      dirty: _dirty && !_saving,
      action: OzoneButton(
        label: _editing ? 'Save' : 'Add account',
        onPressed: _saving ? null : _save,
        color: financeAccent(context),
        foreground: c.onAccent,
      ),
      children: [
        OzoneTextField(
          label: 'Name',
          controller: _name,
          error: _nameErr,
          hint: 'Emergency Fund',
          autofocus: !_editing,
          onChanged: changed,
          textInputAction: TextInputAction.next,
          fieldKey: const ValueKey('account-name'),
        ),
        _SuggestField(label: 'Platform', hint: 'Bank, digital bank, Pag-IBIG…', controller: _platform, error: _platformErr, suggestions: _platforms, onChanged: changed),
        _SuggestField(label: 'Type', hint: 'Savings, time deposit…', controller: _type, error: _typeErr, suggestions: _types, onChanged: changed),
        if (!_editing) ...[
          OzoneTextField(
            label: 'Starting balance',
            controller: _balance,
            error: _balanceErr,
            prefix: '₱ ',
            hint: '0.00',
            large: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: amountFormatters,
            onChanged: changed,
            fieldKey: const ValueKey('account-balance'),
          ),
          Row(
            children: [
              Expanded(child: Text('Balance as of', style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w700))),
              DateButton(
                date: _asOf,
                today: today,
                accent: financeAccent(context),
                tile: financeTile(context),
                onChanged: (d) => setState(() => _asOf = d),
              ),
            ],
          ),
        ],
        OzoneTextField(label: 'Remarks (optional)', controller: _remarks, error: _remarksErr, maxLines: 3, onChanged: changed),
      ],
    );
  }
}

/// A text field with tappable suggestions from values already used (F1-01 §3).
class _SuggestField extends StatelessWidget {
  const _SuggestField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.error,
    required this.suggestions,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? error;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;

  @override
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OzoneTextField(
            label: '$label (optional)',
            controller: controller,
            error: error,
            hint: hint,
            onChanged: onChanged,
            textInputAction: TextInputAction.next,
          ),
          SuggestionChips(
            suggestions: suggestions,
            typed: controller.text,
            onPick: (s) {
              controller.text = s;
              onChanged(s);
            },
          ),
        ],
      );
}
