import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/platform/external_activity.dart';
import '../../../core/platform/files_channel.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/workbook/backup_service.dart';
import '../../../core/workbook/ozone_export.dart';

/// The phone's "Save to" dialog; tests replace it.
final saveAsProvider = Provider<Future<String?> Function(String path, String name)>((ref) => FilesChannel.saveAs);

/// W3 · Export progress → done (F1-03 §1, F2-03 §2): per-tool progress, then
/// the phone's "Save to" dialog, then "Export saved" with the plain warning
/// that the file isn't encrypted, and "Share or save a copy…".
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

enum _Phase { working, ready, saved, failed }

class _ExportScreenState extends ConsumerState<ExportScreen> {
  _Phase _phase = _Phase.working;
  ExportStep? _step;
  bool _cancelled = false;
  BuiltExport? _built;
  String? _savedAs;

  static const _rows = {
    ExportStep.savings: ('Savings', 'Accounts and their balance updates'),
    ExportStep.gold: ('Gold', 'Items and karat price history'),
    ExportStep.expenses: ('Expenses', 'All years, refunded ones included'),
    ExportStep.library: ('Library', 'Every book'),
    ExportStep.notes: ('Notes', 'Locked ones stay encrypted'),
    ExportStep.settings: ('Settings', 'Theme, dashboard, bar, reminders'),
  };

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    setState(() {
      _phase = _Phase.working;
      _step = null;
      _cancelled = false;
    });
    try {
      final built = await ref.read(backupServiceProvider).build(
            onStep: (s) {
              if (mounted) setState(() => _step = s);
            },
            cancelled: () => _cancelled,
          );
      if (!mounted) return;
      setState(() {
        _built = built;
        _phase = _Phase.ready;
      });
      await _save();
    } on ExportCancelled {
      if (mounted) Navigator.of(context).maybePop();
    } on Object {
      if (mounted) setState(() => _phase = _Phase.failed);
    }
  }

  Future<void> _save() async {
    final b = _built!;
    try {
      final name = await ref.read(saveAsProvider)(b.file.path, b.name);
      if (name == null || !mounted) return; // cancelled: stay on "ready"
      await ref.read(backupServiceProvider).recordExport(b, savedAs: name);
      if (mounted) {
        setState(() {
          _savedAs = name.isEmpty ? b.name : name;
          _phase = _Phase.saved;
        });
      }
    } on PlatformException {
      if (mounted) setState(() => _phase = _Phase.failed);
    }
  }

  Future<void> _share() async {
    final b = _built!;
    final r = await ExternalActivity.run(() => SharePlus.instance.share(ShareParams(files: [XFile(b.file.path)], title: b.name)));
    // Shared somewhere: that counts as a backup too.
    if (r.status == ShareResultStatus.success && _phase != _Phase.saved) {
      await ref.read(backupServiceProvider).recordExport(b);
      if (mounted) {
        setState(() {
          _savedAs = b.name;
          _phase = _Phase.saved;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final steps = ExportStep.values;
    final done = _step == null ? 0 : steps.indexOf(_step!);
    final pct = _phase == _Phase.working ? done / steps.length : 1.0;

    Widget warning() => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.attentionBg, borderRadius: BorderRadius.circular(Radii.card)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.error_outline_rounded, size: 18, color: c.attentionInk),
            const SizedBox(width: Space.s),
            Expanded(
              child: Text('This file isn’t encrypted. Anyone who opens it can read everything in it except locked notes, which stay encrypted.',
                  style: text.bodyMedium!.copyWith(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600, color: c.attentionInk)),
            ),
          ]),
        );

    final body = switch (_phase) {
      _Phase.working => [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text('Writing your workbook…', style: text.bodyLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w800))),
                Text('${(pct * 100).round()}%', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: Space.m),
              Semantics(
                label: 'Export progress',
                value: '${(pct * 100).round()}%',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(value: pct, minHeight: 10, backgroundColor: c.surfaceSunken, color: c.ink),
                ),
              ),
              const SizedBox(height: Space.s),
              for (var i = 0; i < steps.length; i++)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: i < done ? c.ink : Colors.transparent,
                        shape: BoxShape.circle,
                        border: i < done ? null : Border.all(color: i == done ? c.ink : c.outline, width: i == done ? 2.5 : 2),
                      ),
                      child: i < done ? Icon(Icons.check_rounded, size: 14, color: c.canvas) : null,
                    ),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_rows[steps[i]]!.$1, style: text.bodyLarge!.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700, color: i <= done ? c.ink : c.inkMuted)),
                        Text(_rows[steps[i]]!.$2, style: text.bodyMedium!.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: c.inkMuted)),
                      ]),
                    ),
                    Text(i < done ? 'Done' : (i == done ? 'Writing…' : ''), style: text.labelSmall!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted)),
                  ]),
                ),
            ]),
          ),
          Text('Keep OZONE open. Nothing in the app changes while this runs.',
              style: text.bodyMedium!.copyWith(fontSize: 13, height: 1.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
          OzoneButton(label: 'Cancel', primary: false, height: 48, onPressed: () => setState(() => _cancelled = true)),
        ],
      _Phase.ready => [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
            child: Column(children: [
              Text('Your workbook is ready', style: text.titleLarge),
              const SizedBox(height: Space.s),
              Text('${_built!.name} · ${_built!.total} rows. Choose where to save it.', textAlign: TextAlign.center, style: text.bodyLarge!.copyWith(color: c.inkMuted)),
            ]),
          ),
          warning(),
          OzoneButton(label: 'Save to…', onPressed: _save),
          OzoneButton(label: 'Share or save a copy…', primary: false, height: 48, onPressed: _share),
        ],
      _Phase.saved => [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
            child: Column(children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, size: 30, color: c.canvas),
              ),
              const SizedBox(height: Space.m),
              Semantics(liveRegion: true, child: Text('Export saved', style: text.titleLarge)),
              const SizedBox(height: Space.xs),
              Text(_savedAs ?? '', textAlign: TextAlign.center, style: text.bodyMedium!.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.inkMuted)),
            ]),
          ),
          warning(),
          Text('Copy it somewhere off this phone, like your computer or a USB drive, so it survives if the phone is lost.',
              style: text.bodyMedium!.copyWith(fontSize: 13, height: 1.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
          OzoneButton(label: 'Share or save a copy…', onPressed: _share),
          OzoneButton(label: 'Done', primary: false, height: 48, onPressed: () => Navigator.of(context).maybePop()),
        ],
      _Phase.failed => [
          AttentionBanner(
            title: 'Couldn’t save the export',
            body: 'Nothing was changed. Check that the phone has free space, then try again.',
            action: OzoneButton(label: 'Try again', onPressed: _built == null ? _run : _save),
          ),
        ],
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.s, 6),
              child: Row(children: [
                IconButton(
                  tooltip: 'Close',
                  onPressed: () {
                    _cancelled = true;
                    Navigator.of(context).maybePop();
                  },
                  icon: Icon(Icons.close_rounded, color: c.ink),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                const SizedBox(width: Space.xs),
                Expanded(child: Semantics(header: true, child: Text('Export workbook', style: text.titleLarge))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.screen, Space.s, Space.screen, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final w in body) Padding(padding: const EdgeInsets.only(bottom: Space.m), child: w)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
