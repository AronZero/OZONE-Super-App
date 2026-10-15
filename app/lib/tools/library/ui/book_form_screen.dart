import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../data/books_repo.dart';
import '../domain/library.dart';
import '../state/library_providers.dart';
import 'library_parts.dart';
import '../../../core/ui/theme/oz_icons.dart';

/// Add or edit a book (W2 · Add book, flow F5): full screen, since it has
/// more than 6 fields. The amount appears and is required only for Purchased.
class BookFormScreen extends ConsumerStatefulWidget {
  const BookFormScreen({super.key, this.bookId});
  final String? bookId;

  @override
  ConsumerState<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends ConsumerState<BookFormScreen> {
  BookRow? _e;
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _amount = TextEditingController();
  final _size = TextEditingController();
  final _remarks = TextEditingController();
  Acquisition _acq = Acquisition.purchased;
  BookStatus _status = BookStatus.notStarted;
  bool _kindle = true;
  int? _rating;
  LocalDate? _acquired;
  String _initial = '';
  final Map<String, String?> _err = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = widget.bookId;
    final e = id == null ? null : ref.read(booksDataProvider).value?.byId(id);
    _e = e;
    if (e != null) {
      _title.text = e.title;
      _author.text = e.author ?? '';
      _amount.text = e.amount == null ? '' : Money.format(e.amount!).substring(1);
      _size.text = e.sizeKb?.toString() ?? '';
      _remarks.text = e.remarks ?? '';
      _acq = Acquisition.of(e.acquisition);
      _status = BookStatus.of(e.status);
      _kindle = e.onKindle;
      _rating = e.ratingHalf;
      _acquired = e.acquiredDate == null ? null : LocalDate.parseIso(e.acquiredDate!).valueOrNull;
    } else {
      // The form fills the acquired date with today (F1-01).
      _acquired = ref.read(todayProvider);
    }
    _initial = _snapshot();
  }

  @override
  void dispose() {
    for (final c in [_title, _author, _amount, _size, _remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  String _snapshot() => [
        _title.text, _author.text, _amount.text, _size.text, _remarks.text, //
        _acq.key, _status.key, _kindle, _rating, _acquired?.toIso(),
      ].join('|');

  Future<void> _save() async {
    final today = ref.read(todayProvider);
    final title = _title.text.trim();
    final Validation<String> t = title.isEmpty
        ? const Invalid('Enter the title')
        : title.length > 200
            ? const Invalid('Use 200 characters or fewer')
            : Ok(title);
    final author = _author.text.trim();
    final Validation<String?> a = author.length > 200 ? const Invalid('Use 200 characters or fewer') : Ok(author.isEmpty ? null : author);
    final Validation<int?> amount = _acq != Acquisition.purchased
        ? const Ok(null)
        : _amount.text.trim().isEmpty
            ? const Invalid('Enter what you paid')
            : switch (Money.parse(_amount.text)) {
                Ok(:final value) => Ok(value),
                Invalid(:final reason) => Invalid(reason),
              };
    final size = parseSizeKb(_size.text);
    final remarks = _remarks.text.trim();
    final Validation<String?> r = remarks.length > 1000 ? const Invalid('Use 1,000 characters or fewer') : Ok(remarks.isEmpty ? null : remarks);
    final d = _acquired;
    final Validation<LocalDate?> date = d != null && d.isAfter(today) ? const Invalid('Pick today or an earlier date') : Ok(d);
    String? m<T>(Validation<T> v) => v is Invalid<T> ? v.reason : null;
    setState(() {
      _err
        ..['title'] = m(t)
        ..['author'] = m(a)
        ..['amount'] = m(amount)
        ..['size'] = m(size)
        ..['remarks'] = m(r)
        ..['date'] = m(date);
    });
    if (_err.values.any((x) => x != null)) return;
    setState(() => _saving = true);
    final input = BookInput(
      title: t.valueOrNull!,
      author: a.valueOrNull,
      sizeKb: size.valueOrNull,
      onKindle: _kindle,
      status: _status,
      acquisition: _acq,
      acquired: date.valueOrNull,
      amount: amount.valueOrNull,
      ratingHalf: _rating,
      remarks: r.valueOrNull,
    );
    final repo = ref.read(booksRepoProvider);
    final ok = await guardSave(context, ref.read(errorLogProvider), what: 'save book', () async {
      if (_e == null) {
        await repo.add(input);
      } else {
        await repo.edit(_e!.id, input);
      }
    });
    if (!mounted) return;
    if (!ok) return setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final label = text.bodyMedium!.copyWith(fontWeight: FontWeight.w700);
    void changed([Object? _]) => setState(() {});
    Widget gap() => const SizedBox(height: 14);

    return DiscardGuard(
      dirty: _snapshot() != _initial && !_saving,
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.s, Space.s),
              child: Row(children: [
                IconButton(
                  tooltip: 'Close without saving',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(OzIcons.close, color: c.ink),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                const SizedBox(width: Space.xs),
                Expanded(child: Semantics(header: true, child: Text(_e == null ? 'Add book' : 'Edit book', style: text.titleLarge))),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, Space.xl),
                children: [
                  OzoneTextField(label: 'Title *', controller: _title, error: _err['title'], autofocus: _e == null, onChanged: changed, fieldKey: const ValueKey('book-title')),
                  gap(),
                  OzoneTextField(label: 'Author', controller: _author, error: _err['author'], onChanged: changed, fieldKey: const ValueKey('book-author')),
                  gap(),
                  Text('Acquisition', style: label),
                  const SizedBox(height: Space.s),
                  LibraryChoice<Acquisition>(
                    label: 'Acquisition',
                    options: [for (final a in Acquisition.values) (a, a.label)],
                    selected: _acq,
                    onSelected: (a) => setState(() {
                      _acq = a;
                      _err['amount'] = null;
                    }),
                  ),
                  if (_acq == Acquisition.purchased) ...[
                    gap(),
                    OzoneTextField(
                      label: 'Amount paid *',
                      controller: _amount,
                      error: _err['amount'],
                      prefix: '₱ ',
                      hint: '0.00',
                      large: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: amountFormatters,
                      onChanged: changed,
                      fieldKey: const ValueKey('book-amount'),
                    ),
                    const SizedBox(height: 6),
                    Text('Counts toward book spending in Library stats only', style: text.bodyMedium!.copyWith(fontSize: 12.5, color: c.inkMuted)),
                  ],
                  gap(),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Acquired on', style: label),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 52,
                          child: _acquired == null
                              ? OzoneButton(label: 'Add date', primary: false, onPressed: () => setState(() => _acquired = today))
                              : DateButton(date: _acquired!, today: today, onChanged: (d) => setState(() => _acquired = d)),
                        ),
                        if (_err['date'] != null) Text(_err['date']!, style: text.bodyMedium!.copyWith(color: c.danger, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OzoneTextField(
                        label: 'File size (KB)',
                        controller: _size,
                        error: _err['size'],
                        hint: '2,348',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
                        onChanged: changed,
                        fieldKey: const ValueKey('book-size'),
                      ),
                    ),
                  ]),
                  gap(),
                  GroupCard(children: [
                    SettingsRow(
                      title: 'On my Kindle',
                      subtitle: 'Counts toward Kindle storage',
                      trailing: OzoneSwitch(value: _kindle, label: 'On my Kindle', accent: libraryAccent(context), onChanged: (v) => setState(() => _kindle = v)),
                    ),
                  ]),
                  gap(),
                  Text('Status', style: label),
                  const SizedBox(height: Space.s),
                  LibraryChoice<BookStatus>(
                    label: 'Reading status',
                    options: [for (final s in BookStatus.values) (s, s.label)],
                    selected: _status,
                    onSelected: (s) => setState(() => _status = s),
                  ),
                  gap(),
                  Text('Rating', style: label),
                  const SizedBox(height: 6),
                  RatingStepper(half: _rating, onChanged: (v) => setState(() => _rating = v)),
                  gap(),
                  OzoneTextField(label: 'Remarks (optional)', controller: _remarks, error: _err['remarks'], maxLines: 3, onChanged: changed),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(Space.screen, Space.m, Space.screen, Space.xl),
              decoration: BoxDecoration(color: c.canvas, border: Border(top: BorderSide(color: c.outline.withValues(alpha: 0.6)))),
              child: OzoneButton(label: 'Save book', onPressed: _saving ? null : _save, color: libraryAccent(context), foreground: c.onAccent),
            ),
          ]),
        ),
      ),
    );
  }
}
