import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/first_run.dart';
import '../../../core/platform/external_activity.dart';
import '../../../core/state/providers.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/workbook/foreign_vault.dart';
import '../../../core/workbook/ozone_import.dart';
import '../../../tools/notes/ui/vault/vault_parts.dart';
import '../../../tools/notes/ui/vault/vault_unlock.dart';
import '../../../core/ui/amounts.dart';

/// Picks a `.xlsx` (F2-03 §2: the system picker; the file is read once into memory).
Future<(String, List<int>)?> pickWorkbook() async {
  const group = XTypeGroup(
    label: 'OZONE workbook',
    extensions: ['xlsx'],
    mimeTypes: ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
  );
  final f = await ExternalActivity.run(() => openFile(acceptedTypeGroups: const [group]));
  if (f == null) return null;
  return (f.name, await f.readAsBytes());
}

/// The file picker; tests replace it.
final pickWorkbookProvider = Provider<Future<(String, List<int>)?> Function()>((ref) => pickWorkbook);

/// W1 · Import preview and the whole import pipeline (F1-03 §2), also used by
/// Welcome › Restore (§3) and Safety exports › Import.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, this.restore = false, this.file});

  /// First-run restore: every row is new, settings use the file's values.
  final bool restore;

  /// A file to import without asking (a safety export).
  final File? file;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

enum _Phase { picking, reading, refused, preview, applying, done, failed }

class _ImportScreenState extends ConsumerState<ImportScreen> {
  _Phase _phase = _Phase.picking;
  String _message = '';
  ImportPlan? _plan;
  Map<String, int> _written = const {};
  File? _safety;
  final _otherPw = TextEditingController();
  String? _otherError;
  bool _otherBusy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _otherPw.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _phase = _Phase.picking);
    final (String, List<int>)? picked;
    if (widget.file != null) {
      picked = (widget.file!.uri.pathSegments.last, await widget.file!.readAsBytes());
    } else {
      picked = await ref.read(pickWorkbookProvider)();
    }
    if (!mounted) return;
    if (picked == null) {
      // Nothing chosen: back to where we came from.
      if (_plan == null) Navigator.of(context).maybePop();
      return;
    }
    setState(() => _phase = _Phase.reading);
    try {
      final plan = await ref.read(backupServiceProvider).read(picked.$2, fileName: picked.$1, today: ref.read(todayProvider), restore: widget.restore);
      if (mounted) {
        setState(() {
          _plan = plan;
          _phase = _Phase.preview;
        });
      }
    } on ImportRefused catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _phase = _Phase.refused;
        });
      }
    }
  }

  Future<void> _apply() async {
    final plan = _plan!;
    setState(() => _phase = _Phase.applying);
    try {
      final (safety, written) = await ref.read(backupServiceProvider).apply(plan, restore: widget.restore);
      if (widget.restore) await FirstRun.done(ref.read(databaseProvider));
      if (!mounted) return;
      if (widget.restore) {
        final total = written.values.fold(0, (a, b) => a + b);
        context.go(Uri(path: '/welcome/reminder', queryParameters: {'restored': plan.fileName, 'rows': '$total'}).toString());
        return;
      }
      setState(() {
        _safety = safety;
        _written = written;
        _phase = _Phase.done;
      });
    } on Object {
      if (mounted) setState(() => _phase = _Phase.failed);
    }
  }

  /// Locked notes from another vault: this phone's vault must be open, then the file's password.
  Future<void> _unlockOther() async {
    if (!await ensureVaultOpen(context, ref) || !mounted) return;
    setState(() {
      _otherBusy = true;
      _otherError = null;
    });
    final n = await unlockOtherVault(_plan!, _otherPw.text, ref.read(vaultServiceProvider));
    if (!mounted) return;
    setState(() {
      _otherBusy = false;
      _otherError = n == null ? 'That password doesn’t open this file’s locked notes.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final plan = _plan;
    final title = widget.restore ? 'Restore from a workbook' : 'Import preview';

    Widget wait(String s) => Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(children: [
            CircularProgressIndicator(color: c.ink),
            const SizedBox(height: Space.l),
            Semantics(liveRegion: true, child: Text(s, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700))),
          ]),
        );

    final List<Widget> body;
    Widget? bottom;
    switch (_phase) {
      case _Phase.picking:
        body = [wait('Choose a workbook…')];
      case _Phase.reading:
        body = [wait('Reading the file…')];
      case _Phase.applying:
        body = [wait(widget.restore ? 'Restoring…' : 'Saving a safety copy, then importing…')];
      case _Phase.refused:
        body = [
          AttentionBanner(
            title: 'This file can’t be imported',
            body: '$_message Nothing was changed.',
            action: OzoneButton(label: 'Choose another file', onPressed: _start),
          ),
        ];
      case _Phase.failed:
        body = [
          AttentionBanner(
            title: 'The import didn’t finish',
            body: 'Nothing was changed${widget.restore ? '' : ', and the safety export is kept'}. Check the file and try again.',
            action: OzoneButton(label: 'Try again', onPressed: _apply),
          ),
        ];
      case _Phase.done:
        final total = _written.values.fold(0, (a, b) => a + b);
        final when = _safety?.lastModifiedSync();
        body = [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Semantics(liveRegion: true, child: Text('Imported $total ${total == 1 ? 'row' : 'rows'}', style: text.titleLarge)),
              const SizedBox(height: Space.s),
              for (final MapEntry(:key, :value) in _written.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [Expanded(child: Text(key, style: text.bodyLarge)), Text('$value', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800))]),
                ),
            ]),
          ),
          if (when != null)
            Text(
              'To go back, import the safety export from ${when.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][when.month - 1]}, '
              '${when.hour % 12 == 0 ? 12 : when.hour % 12}:${when.minute.toString().padLeft(2, '0')} ${when.hour < 12 ? 'am' : 'pm'} '
              '(Settings › Data & backup › Safety exports).',
              style: text.bodyMedium!.copyWith(fontSize: 13.5, height: 1.5, color: c.inkMuted),
            ),
          OzoneButton(label: 'Done', onPressed: () => Navigator.of(context).maybePop()),
        ];
      case _Phase.preview:
        final p = plan!;
        final counts = p.counts;
        final check = p.rows.where((r) => const {RowClass.error, RowClass.duplicate, RowClass.deletedHere}.contains(r.cls)).toList();
        final changed = p.rows.where((r) => r.cls == RowClass.changed).toList();
        final other = p.rows.where((r) => r.cls == RowClass.otherVault).toList();
        body = [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Space.m),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.table_chart_outlined, size: 20, color: c.ink),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyLarge!.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  Text('Format v${p.formatVersion} · readable · ${p.sheetCount} sheets', style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
                ]),
              ),
            ]),
          ),
          _CountsTable(counts: {for (final e in counts.entries) if (e.value.newRows + e.value.changed + e.value.same + e.value.check > 0) e.key: e.value}),
          for (final e in p.sheetErrors) AttentionBanner(title: 'A sheet was left out', body: e),
          if (p.importVault)
            _Note('The file’s notes vault comes with it. Its vault password opens the locked notes.'),
          if (other.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.attentionBg, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('${other.length} locked ${other.length == 1 ? 'note uses' : 'notes use'} a different vault password',
                    style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: c.attentionInk)),
                const SizedBox(height: Space.xs),
                Text('Enter the vault password they were saved with to bring them into this phone’s vault. Otherwise they’re skipped.',
                    style: text.bodyMedium!.copyWith(fontSize: 13.5, height: 1.45, color: c.attentionInk)),
                const SizedBox(height: Space.m),
                PasswordField(label: 'That file’s vault password', controller: _otherPw, error: _otherError, fill: c.surface, onSubmitted: (_) => _unlockOther()),
                const SizedBox(height: Space.s),
                VaultButton(label: _otherBusy ? 'Opening…' : 'Open these notes', busy: _otherBusy, onPressed: _unlockOther),
              ]),
            ),
          for (final sheet in ImportPlan.sheets)
            if (check.any((r) => r.sheet == sheet)) _CheckCard(sheet: sheet, rows: [for (final r in check) if (r.sheet == sheet) r], onChanged: () => setState(() {})),
          if (changed.isNotEmpty) ...[
            for (final sheet in ImportPlan.sheets)
              if (changed.any((r) => r.sheet == sheet))
                _ChangedCard(
                  sheet: sheet,
                  rows: [for (final r in changed) if (r.sheet == sheet) r],
                  onChanged: () => setState(() {}),
                  onAll: (useFile) => setState(() => p.setSheetChoice(sheet, useFile: useFile)),
                ),
          ],
        ];
        final n = p.toWrite;
        bottom = Container(
          padding: const EdgeInsets.fromLTRB(Space.screen, 10, Space.screen, Space.xl),
          decoration: BoxDecoration(color: c.canvas, border: Border(top: BorderSide(color: c.outline))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.restore ? 'Every row is added to this phone. Locked notes keep the vault password they were saved with.' : 'A safety export is saved first. Nothing in OZONE is deleted.',
                style: text.bodyMedium!.copyWith(fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w600, color: c.inkMuted)),
            const SizedBox(height: Space.s),
            OzoneButton(label: n == 0 ? 'Nothing to import' : '${widget.restore ? 'Restore' : 'Import'} $n ${n == 1 ? 'row' : 'rows'}', onPressed: n == 0 ? null : _apply),
          ]),
        );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DetailTopBar(title: title, overline: widget.restore ? 'Welcome' : 'Data & backup'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, Space.xl),
              children: [for (final w in body) Padding(padding: const EdgeInsets.only(bottom: 10), child: w)],
            ),
          ),
          ?bottom,
        ]),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 13.5, height: 1.45)),
    );
  }
}

/// Sheet · New · Changed · Same · Check (W1 · Import preview).
class _CountsTable extends StatelessWidget {
  const _CountsTable({required this.counts});
  final Map<String, SheetCounts> counts;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    Widget cell(String s, {bool strong = false, Color? color, bool left = false}) => Expanded(
          flex: left ? 3 : 1,
          child: Text(s,
              textAlign: left ? TextAlign.left : TextAlign.center,
              style: text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: strong ? FontWeight.w800 : FontWeight.w500, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
        );
    String n(int v) => v == 0 ? '—' : '$v';
    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          color: c.surfaceSunken.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(children: [
            for (final (h, left) in const [('Sheet', true), ('New', false), ('Changed', false), ('Same', false), ('Check', false)])
              Expanded(
                flex: left ? 3 : 1,
                child: Text(h, textAlign: left ? TextAlign.left : TextAlign.center, style: text.labelSmall!.copyWith(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.inkMuted)),
              ),
          ]),
        ),
        for (final MapEntry(key: sheet, value: v) in counts.entries)
          Container(
            color: v.check > 0 ? c.attentionBg.withValues(alpha: 0.35) : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Semantics(
              label: spokenAmounts('$sheet: ${v.newRows} new, ${v.changed} changed, ${v.same} same, ${v.check} to check'),
              excludeSemantics: true,
              child: Row(children: [
                cell(sheet, left: true, strong: true),
                cell(n(v.newRows), strong: v.newRows > 0),
                cell(n(v.changed), strong: v.changed > 0),
                cell(n(v.same)),
                cell(n(v.check), strong: v.check > 0, color: v.check > 0 ? c.attentionInk : null),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// "Expenses · 5 to check": duplicates and deleted-here rows skipped (switchable), errors listed.
class _CheckCard extends StatelessWidget {
  const _CheckCard({required this.sheet, required this.rows, required this.onChanged});
  final String sheet;
  final List<ImportRow> rows;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final dup = rows.where((r) => r.cls == RowClass.duplicate).length;
    final del = rows.where((r) => r.cls == RowClass.deletedHere).length;
    final err = rows.where((r) => r.cls == RowClass.error).length;
    final style = text.bodyMedium!.copyWith(fontSize: 13.5, height: 1.45, color: c.attentionInk);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, Space.m, 14, Space.xs),
      decoration: BoxDecoration(color: c.attentionBg, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$sheet · ${rows.length} to check', style: style.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (dup > 0) Text('$dup possible ${dup == 1 ? 'duplicate' : 'duplicates'} · skipped unless you add them', style: style),
        if (del > 0) Text('$del deleted on this phone · skipped unless you restore them', style: style),
        if (err > 0) Text('$err with errors · not imported', style: style),
        TextButton(
          onPressed: () => showOzoneSheet<void>(context, builder: (_) => _ReviewSheet(sheet: sheet, rows: rows, onChanged: onChanged)),
          style: TextButton.styleFrom(foregroundColor: c.attentionInk, padding: EdgeInsets.zero, minimumSize: const Size(48, 48)),
          child: Text('Review ${rows.length} ${rows.length == 1 ? 'row' : 'rows'}', style: const TextStyle(fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
        ),
      ]),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.sheet, required this.rows, required this.onChanged});
  final String sheet;
  final List<ImportRow> rows;
  final VoidCallback onChanged;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.xl, Space.m, Space.xl, Space.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Semantics(header: true, child: Text('${widget.sheet} · rows to check', style: text.titleLarge)),
          const SizedBox(height: Space.m),
          GroupCard(children: [
            for (final r in widget.rows)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.s, Space.m),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Row ${r.rowNo} · ${r.label}', style: text.bodyLarge!.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
                      Text(r.cls == RowClass.error ? r.reason!.replaceFirst(RegExp(r'^Row \d+: '), '') : r.reason ?? '',
                          style: text.bodyMedium!.copyWith(fontSize: 12.5, color: r.cls == RowClass.error ? c.danger : c.inkMuted)),
                    ]),
                  ),
                  if (r.cls == RowClass.duplicate || r.cls == RowClass.deletedHere)
                    Semantics(
                      label: spokenAmounts(r.cls == RowClass.duplicate ? 'Add anyway' : 'Restore'),
                      child: OzoneSwitch(
                        label: r.cls == RowClass.duplicate ? 'Add anyway' : 'Restore',
                        value: r.apply,
                        onChanged: (v) {
                          setState(() => r.apply = v);
                          widget.onChanged();
                        },
                      ),
                    ),
                ]),
              ),
          ]),
          const SizedBox(height: Space.m),
          OzoneButton(label: 'Done', primary: false, height: 48, onPressed: () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }
}

/// "1 changed · Emergency Fund": Yours / File per field, newer marked, Keep mine or Use file's.
class _ChangedCard extends StatelessWidget {
  const _ChangedCard({required this.sheet, required this.rows, required this.onChanged, required this.onAll});
  final String sheet;
  final List<ImportRow> rows;
  final VoidCallback onChanged;
  final ValueChanged<bool> onAll;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final shown = rows.take(20).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('$sheet · ${rows.length} changed', style: text.bodyLarge!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800))),
          if (rows.length > 1)
            PopupMenuButton<bool>(
              tooltip: 'Choose for all',
              color: c.surface,
              onSelected: onAll,
              itemBuilder: (_) => const [PopupMenuItem(value: false, child: Text('Keep mine for all')), PopupMenuItem(value: true, child: Text('Use file’s for all'))],
              child: Padding(padding: const EdgeInsets.all(Space.s), child: Text('All ▾', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800))),
            ),
        ]),
        for (final r in shown) ...[
          const SizedBox(height: Space.m),
          Text(r.label, style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: Space.xs),
          for (final (field, mine, file) in r.diffs)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 92, child: Text(field, style: text.bodyMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: c.inkMuted))),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Yours: “$mine”${_newer(r) == false ? ' · newer' : ''}', style: text.bodyMedium!.copyWith(fontSize: 13)),
                    Text('File: “$file”${_newer(r) == true ? ' · newer' : ''}', style: text.bodyMedium!.copyWith(fontSize: 13)),
                  ]),
                ),
              ]),
            ),
          ChoiceChips<bool>(
            label: 'Which version to keep for ${r.label}',
            options: const [(false, 'Keep mine'), (true, 'Use file’s')],
            selected: r.apply,
            onSelected: (v) {
              r.apply = v;
              onChanged();
            },
          ),
        ],
        if (rows.length > shown.length)
          Padding(
            padding: const EdgeInsets.only(top: Space.m),
            child: Text('${rows.length - shown.length} more changed rows follow the choice for all.', style: text.bodyMedium!.copyWith(color: c.inkMuted)),
          ),
      ]),
    );
  }

  /// true = the file's row is newer, false = mine, null = unknown.
  static bool? _newer(ImportRow r) {
    if (r.updated == null || r.mineUpdated == null || r.updated == r.mineUpdated) return null;
    return r.updated! > r.mineUpdated!;
  }
}
