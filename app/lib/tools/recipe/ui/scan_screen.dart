import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/recipes_repo.dart';
import '../data/scan_pages.dart';
import '../domain/recipe.dart';
import '../domain/scan_parser.dart';
import '../state/recipe_providers.dart';
import 'recipe_parts.dart';

/// What a scan hands to the New recipe form.
class ScanFill {
  const ScanFill(this.draft, {this.photo});
  final ScanDraft draft;

  /// A photo already in the store ("Use this picture as the recipe's photo?").
  final String? photo;
}

/// One captured page: the picture, its four corners (0–1 as shown, top left
/// first, clockwise) and how often it was turned.
class _Page {
  _Page(this.picture, this.size);
  String picture;
  Size size;
  int turns = 0;
  List<Offset> corners = _start;

  static const _start = [Offset(.05, .05), Offset(.95, .05), Offset(.95, .95), Offset(.05, .95)];

  Size get shown => turns.isOdd ? size.flipped : size;
}

class _Row {
  _Row(this.id, this.line);
  final int id;
  ReadLine line;
}

/// Scan a page (board R3) and Check what was read (board R4), as steps 1 and
/// 2 of one screen (docs/spec/F4-02 §3). The pictures and straightened pages
/// live in the cache and are deleted when the screen closes.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, this.fromGallery = false});

  /// From a photo: pages come from the system photo picker, and the picture
  /// can become the recipe's photo.
  final bool fromGallery;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  static const maxPages = 4;

  final List<_Page> _pages = [];
  final Set<String> _pictures = {};
  int _current = 0;
  bool _picking = false;

  /// The page being read (0-based), or null.
  int? _reading;
  bool _cancelled = false;

  /// Step 1 error: (title, body, retake page or null for Try again).
  (String, String, int?)? _error;

  // Step 2
  ScanResult? _result;
  final List<_Row> _rows = [];
  final _title = TextEditingController();
  int _nextId = 0;
  bool _photoAsked = false;
  String? _photo;

  ImageSource get _source => widget.fromGallery ? ImageSource.gallery : ImageSource.camera;

  /// Read once: `ref` can't be used in dispose.
  late final Future<Directory> Function() _cacheDir = ref.read(scanCacheProvider);

  @override
  void initState() {
    super.initState();
    unawaited(clearScanCache(_cacheDir));
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  @override
  void dispose() {
    _title.dispose();
    _cancelled = true;
    for (final p in _pictures) {
      _deleteQuietly(p);
    }
    unawaited(clearScanCache(_cacheDir));
    super.dispose();
  }

  void _deleteQuietly(String path) {
    try {
      File(path).deleteSync();
    } on FileSystemException {
      // Already gone.
    }
  }

  /// Takes a picture: a new page, or [replace] for Retake.
  Future<void> _capture({int? replace}) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final path = await ref.read(pagePickerProvider)(_source);
      if (!mounted) return;
      if (path == null) {
        if (_pages.isEmpty) context.pop();
        return;
      }
      _pictures.add(path);
      final size = await ref.read(pictureSizeProvider)(path);
      if (!mounted) return;
      setState(() {
        _error = null;
        if (replace != null) {
          _deleteQuietly(_pages[replace].picture);
          _pages[replace] = _Page(path, size);
          _current = replace;
        } else {
          _pages.add(_Page(path, size));
          _current = _pages.length - 1;
        }
      });
    } on Object catch (e, st) {
      unawaited(ref.read(errorLogProvider).record(e, st, where: 'scan picture'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn’t use that picture. Try another one.')));
        if (_pages.isEmpty) context.pop();
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _rotate() {
    final p = _pages[_current];
    Offset turn(Offset o) => Offset(1 - o.dy, o.dx);
    setState(() {
      p.turns = (p.turns + 1) % 4;
      p.corners = [turn(p.corners[3]), turn(p.corners[0]), turn(p.corners[1]), turn(p.corners[2])];
    });
  }

  Future<void> _read() async {
    setState(() {
      _error = null;
      _cancelled = false;
      _reading = 0;
    });
    final reader = ref.read(pageReaderProvider)();
    final straighten = ref.read(pageStraightenerProvider);
    final scanned = <ScanPage>[];
    try {
      final dir = await _cacheDir();
      await dir.create(recursive: true);
      for (var i = 0; i < _pages.length; i++) {
        if (_cancelled || !mounted) return;
        setState(() => _reading = i);
        final p = _pages[i];
        final out = '${dir.path}/page_${i + 1}_${DateTime.now().microsecondsSinceEpoch}.png';
        final size = await straighten(p.picture, p.corners, p.turns, out);
        if (_cancelled || !mounted) return;
        final page = await reader.read(out, size);
        _deleteQuietly(out);
        if (_cancelled || !mounted) return;
        if (page.lines.isEmpty) {
          setState(() => _error = ('No text found on this page', 'Try more light, or hold the phone straight above the page.', i));
          return;
        }
        scanned.add(page);
      }
    } on Object catch (e, st) {
      unawaited(ref.read(errorLogProvider).record(e, st, where: 'scan read'));
      if (mounted && !_cancelled) setState(() => _error = ('Couldn’t read the text.', 'Something went wrong on the phone.', null));
      return;
    } finally {
      unawaited(reader.close());
      if (mounted) setState(() => _reading = null);
    }
    if (!mounted || _cancelled) return;

    final result = parseScan(scanned);
    if (widget.fromGallery && !_photoAsked) {
      _photoAsked = true;
      final use = await confirmDialog(
        context,
        title: 'Use this picture as the recipe’s photo?',
        body: 'It’s saved with the recipe. You can change it later.',
        confirm: 'Use it',
        cancel: 'No',
      );
      if (use == true) {
        try {
          _photo = await ref.read(photoStoreProvider).adopt(_pages.first.picture);
        } on Object catch (e, st) {
          unawaited(ref.read(errorLogProvider).record(e, st, where: 'scan photo'));
        }
      }
      if (!mounted) return;
    }
    setState(() {
      _result = result;
      _title.text = result.title;
      _rows
        ..clear()
        ..addAll([for (final l in result.lines) _Row(_nextId++, l)]);
    });
  }

  void _continue() {
    final r = _result!;
    final draft = draftFromLines(
      title: _title.text,
      servings: r.servings,
      prepMin: r.prepMin,
      cookMin: r.cookMin,
      lines: [for (final row in _rows) row.line],
    );
    context.pushReplacement('/recipe/new', extra: ScanFill(draft, photo: _photo));
  }

  @override
  Widget build(BuildContext context) {
    final checking = _result != null;
    return PopScope(
      canPop: !checking && _reading == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_reading != null) {
          setState(() => _cancelled = true);
        } else if (checking) {
          setState(() => _result = null);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            _topBar(context, checking),
            Expanded(child: checking ? _check(context) : _scan(context)),
          ]),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, bool checking) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.m, Space.s),
      child: Row(children: [
        IconButton(
          tooltip: checking ? 'Back to the photo' : 'Cancel scan',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(checking ? OzIcons.arrowBack : OzIcons.close, color: c.ink),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        const SizedBox(width: Space.xs),
        Expanded(child: Semantics(header: true, child: Text(checking ? 'Check what was read' : 'Scan a page', style: text.titleLarge))),
        Text(checking ? 'Step 2 of 2' : 'Step 1 of 2', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
      ]),
    );
  }

  // ---- Step 1: Scan a page ----

  Widget _scan(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final reading = _reading != null;
    if (_pages.isEmpty) return const Center(child: CircularProgressIndicator());
    final page = _pages[_current];
    final error = _error;
    return Column(children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: ColoredBox(
              color: const Color(0xFF2A2F2C),
              child: Stack(fit: StackFit.expand, children: [
                _Corners(
                  key: ValueKey(page),
                  page: page,
                  accent: recipeAccent(context),
                  enabled: !reading,
                  onChanged: (corners) => setState(() => page.corners = corners),
                ),
                Positioned(
                  right: 12,
                  bottom: 10,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Rotate',
                      onPressed: reading ? null : _rotate,
                      icon: const Icon(OzIcons.rotateRight, color: Color(0xFF15201B)),
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
        child: Text('Drag the corners to the edges of the page.',
            textAlign: TextAlign.center, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
      ),
      SizedBox(
        height: 64 + Space.m,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(Space.screen, Space.m, Space.screen, 0),
          children: [
            for (var i = 0; i < _pages.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: Space.s),
                child: Semantics(
                  button: true,
                  selected: i == _current,
                  label: 'Page ${i + 1} of ${_pages.length}',
                  excludeSemantics: true,
                  onTap: reading ? null : () => setState(() => _current = i),
                  child: GestureDetector(
                    onTap: reading ? null : () => setState(() => _current = i),
                    child: Container(
                      width: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: i == _current ? recipeAccent(context) : Colors.transparent, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(fit: StackFit.expand, children: [
                          RotatedBox(quarterTurns: _pages[i].turns, child: Image.file(File(_pages[i].picture), fit: BoxFit.cover, cacheWidth: 120)),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8)),
                              child: Text('${i + 1}', style: text.labelSmall!.copyWith(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            if (_pages.length < maxPages)
              OutlinedButton.icon(
                onPressed: reading || _picking ? null : () => _capture(),
                icon: Icon(OzIcons.add, color: c.ink),
                label: Text('Add page', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 64),
                  side: BorderSide(color: c.outline, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: Space.s),
                child: Text(_pages.length == 1 ? 'Recipe goes over the page?' : '${_pages.length} pages, read in order',
                    style: text.bodySmall!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
              ),
            ),
          ],
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: Space.m),
        padding: const EdgeInsets.fromLTRB(Space.screen, Space.m, Space.screen, Space.xl),
        decoration: BoxDecoration(color: c.canvas, border: Border(top: BorderSide(color: c.outline.withValues(alpha: 0.6)))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (error != null) ...[
            Semantics(
              liveRegion: true,
              child: AttentionBanner(
                title: error.$1,
                body: error.$2,
                action: OzoneButton(
                  label: error.$3 == null ? 'Try again' : 'Retake page ${error.$3! + 1}',
                  primary: false,
                  height: 44,
                  onPressed: error.$3 == null ? _read : () => _capture(replace: error.$3),
                ),
              ),
            ),
            const SizedBox(height: Space.m),
          ],
          if (reading) ...[
            Semantics(
              liveRegion: true,
              child: Text('Reading page ${_reading! + 1} of ${_pages.length}…', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: Space.s),
            LinearProgressIndicator(value: (_reading! + 0.5) / _pages.length, color: recipeAccent(context), backgroundColor: c.surfaceSunken),
            const SizedBox(height: Space.m),
            OzoneButton(label: 'Cancel', primary: false, onPressed: () => setState(() => _cancelled = true)),
          ] else ...[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(OzIcons.lock, size: 16, color: c.inkMuted),
              const SizedBox(width: Space.s),
              Flexible(
                child: Text('Text is read on your phone. Nothing is uploaded.',
                    style: text.bodySmall!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
              ),
            ]),
            const SizedBox(height: Space.s),
            Row(children: [
              Expanded(
                flex: 10,
                child: OzoneButton(label: 'Retake', primary: false, onPressed: _picking ? null : () => _capture(replace: _current)),
              ),
              const SizedBox(width: Space.s),
              Expanded(
                flex: 16,
                child: OzoneButton(label: 'Read text', color: recipeAccent(context), foreground: c.onAccent, onPressed: _picking ? null : _read),
              ),
            ]),
          ],
        ]),
      ),
    ]);
  }

  // ---- Step 2: Check what was read ----

  Set<String> get _knownKeys => {
        for (final r in ref.read(recipesDataProvider).value?.recipes ?? const <RecipeFull>[])
          for (final i in r.ingredients) i.keyName,
      };

  static const _groupNames = {
    ScanLabel.ingredient: 'Ingredients',
    ScanLabel.step: 'Steps',
    ScanLabel.note: 'Notes',
    ScanLabel.unused: 'Not used',
  };
  static const _labelNames = {
    ScanLabel.ingredient: 'Ingredient',
    ScanLabel.step: 'Step',
    ScanLabel.note: 'Note',
    ScanLabel.unused: 'Not used',
  };

  Future<void> _editLine(_Row row) async {
    final c = OzoneThemeColors.of(context);
    final ctl = TextEditingController(text: row.line.text);
    final res = await showDialog<(String, int?)>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Edit line', style: Theme.of(context).textTheme.titleLarge),
        content: TextField(controller: ctl, autofocus: true, minLines: 1, maxLines: 5),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: TextStyle(color: c.ink, fontWeight: FontWeight.w800))),
          TextButton(
            onPressed: () => Navigator.of(context).pop((ctl.text, ctl.selection.isValid ? ctl.selection.baseOffset : null)),
            child: Text('Split here', style: TextStyle(color: c.ink, fontWeight: FontWeight.w800)),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop((ctl.text, null)), child: Text('Save', style: TextStyle(color: c.ink, fontWeight: FontWeight.w800))),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => ctl.dispose());
    if (res == null || !mounted) return;
    final (t, at) = res;
    setState(() {
      final i = _rows.indexOf(row);
      if (at != null && at > 0 && at < t.length) {
        final a = t.substring(0, at).trim(), b = t.substring(at).trim();
        row.line = row.line.copyWith(text: a, lowConfidence: false);
        if (b.isNotEmpty) _rows.insert(i + 1, _Row(_nextId++, ReadLine(b, row.line.label)));
      } else {
        row.line = row.line.copyWith(text: t.trim(), lowConfidence: false);
      }
      if (row.line.text.isEmpty) _rows.remove(row);
    });
  }

  Widget _check(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final r = _result!;
    final known = _knownKeys;
    final reasons = {for (final row in _rows) row.id: checkReason(row.line, knownKeys: known)};
    final flagged = reasons.values.whereType<String>().length;
    final time = durationText(r.prepMin, r.cookMin);

    // Move: a menu of the four groups (owner Q5 a); the line moves only when one is picked.
    void moveTo(_Row row, ScanLabel to) {
      if (to == row.line.label) return;
      setState(() => row.line = row.line.copyWith(label: to));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        // Floats above the Continue bar, so Continue stays reachable.
        ..showSnackBar(SnackBar(
          content: Text('Moved to ${_groupNames[to]}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, 96),
        ));
    }

    Widget moveButton(_Row row) {
      final l = row.line.label;
      final (bg, fg) = switch (l) {
        ScanLabel.ingredient => (recipeTile(context), recipeAccent(context)),
        ScanLabel.step => (ToolTint.library.tileOf(context), ToolTint.library.accentOf(context)),
        ScanLabel.note => (c.surfaceSunken, c.ink),
        ScanLabel.unused => (c.surfaceSunken, c.inkMuted),
      };
      return PopupMenuButton<ScanLabel>(
        tooltip: '${_labelNames[l]}. Move to another group',
        color: c.surface,
        position: PopupMenuPosition.under,
        onSelected: (to) => moveTo(row, to),
        itemBuilder: (context) => [
          PopupMenuItem<ScanLabel>(
            enabled: false,
            height: 36,
            child: Semantics(
              header: true,
              child: Text('Move to', style: text.labelMedium!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
            ),
          ),
          for (final to in ScanLabel.values)
            PopupMenuItem(
              value: to,
              height: 48,
              child: Row(children: [
                SizedBox(width: 28, child: to == l ? Icon(OzIcons.check, size: 20, color: c.ink) : null),
                Text(_groupNames[to]!,
                    style: text.bodyLarge!.copyWith(fontWeight: to == l ? FontWeight.w800 : FontWeight.w600)),
              ]),
            ),
        ],
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(OzIcons.moveItem, size: 20, color: fg),
          ),
        ),
      );
    }

    Widget line(_Row row) {
      final reason = reasons[row.id];
      return Container(
        key: ValueKey(row.id),
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.canvas))),
        child: Row(children: [
          Expanded(
            child: Semantics(
              hint: 'Long press to edit or split',
              child: InkWell(
                onLongPress: () => _editLine(row),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: AlignmentDirectional.centerStart,
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(row.line.text, style: text.bodyMedium!.copyWith(height: 1.4, fontWeight: FontWeight.w500)),
                    if (reason != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: c.attentionBg, borderRadius: BorderRadius.circular(999)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(OzIcons.warning, size: 12, color: c.attentionInk),
                          const SizedBox(width: 4),
                          Flexible(child: Text(reason, style: text.labelSmall!.copyWith(fontWeight: FontWeight.w800, color: c.attentionInk))),
                        ]),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.only(right: 4), child: moveButton(row)),
        ]),
      );
    }

    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, Space.l),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 62,
                  decoration: BoxDecoration(color: recipeTile(context), borderRadius: BorderRadius.circular(8)),
                  child: Icon(OzIcons.documentScanner, color: recipeAccent(context)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_pages.length} ${_pages.length == 1 ? 'page' : 'pages'} · ${r.lineCount} ${r.lineCount == 1 ? 'line' : 'lines'} read',
                        style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('Use the move button to put a line in another group. Nothing is saved yet.',
                        style: text.bodySmall!.copyWith(fontWeight: FontWeight.w600, color: c.inkMuted)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: Space.m),
            OzoneTextField(label: 'Title', controller: _title, fieldKey: const ValueKey('scan-title')),
            if (r.servings != null || time != null) ...[
              const SizedBox(height: Space.m),
              Wrap(spacing: Space.s, runSpacing: Space.s, children: [
                if (r.servings != null) _chip(context, 'Servings: ${r.servings}'),
                if (time != null) _chip(context, 'Time: $time'),
              ]),
            ],
            if (flagged > 0) ...[
              const SizedBox(height: Space.m),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: c.attentionBg, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(OzIcons.warning, size: 18, color: c.attentionInk),
                  const SizedBox(width: Space.s),
                  Expanded(
                    child: Text(flagged == 1 ? '1 line may be misread. It’s marked Check.' : '$flagged lines may be misread. They’re marked Check.',
                        style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: c.attentionInk)),
                  ),
                ]),
              ),
            ],
            for (final label in ScanLabel.values)
              if (_rows.any((row) => row.line.label == label)) ...[
                const SizedBox(height: Space.m),
                Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                    child: Text.rich(
                      TextSpan(text: _groupNames[label], children: [
                        TextSpan(text: ' · ${_rows.where((row) => row.line.label == label).length}', style: TextStyle(color: c.inkMuted, fontWeight: FontWeight.w700)),
                      ]),
                      style: text.titleSmall!.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedRows(
                    children: [for (final row in _rows) if (row.line.label == label) line(row)],
                    builder: (children) => Column(children: children),
                  ),
                ),
              ],
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(Space.screen, Space.m, Space.screen, Space.xl),
        decoration: BoxDecoration(color: c.canvas, border: Border(top: BorderSide(color: c.outline.withValues(alpha: 0.6)))),
        child: OzoneButton(label: 'Continue to recipe', color: recipeAccent(context), foreground: c.onAccent, onPressed: _continue),
      ),
    ]);
  }

  Widget _chip(BuildContext context, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(color: recipeTile(context), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700, color: recipeAccent(context))),
      );
}

/// The picture with the page outline and four draggable corner handles.
class _Corners extends StatelessWidget {
  const _Corners({super.key, required this.page, required this.accent, required this.enabled, required this.onChanged});

  final _Page page;
  final Color accent;
  final bool enabled;
  final ValueChanged<List<Offset>> onChanged;

  static const _names = ['Top left', 'Top right', 'Bottom right', 'Bottom left'];

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final shown = page.shown;
        // Room below the picture for the Rotate button, so no handle sits under it.
        final area = const EdgeInsets.fromLTRB(16, 16, 16, 72).deflateRect(Offset.zero & box.biggest);
        final rect = Alignment.center.inscribe(applyBoxFit(BoxFit.contain, shown, area.size).destination, area);
        Offset at(Offset c) => rect.topLeft + Offset(c.dx * rect.width, c.dy * rect.height);
        return Stack(children: [
          Positioned.fromRect(
            rect: rect,
            child: RotatedBox(
              quarterTurns: page.turns,
              child: Image.file(File(page.picture), fit: BoxFit.fill, cacheWidth: 1200, semanticLabel: 'Page picture'),
            ),
          ),
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _OutlinePainter([for (final c in page.corners) at(c)], ToolTint.recipe.accent(Brightness.dark))))),
          for (var i = 0; i < 4; i++)
            Positioned(
              left: at(page.corners[i]).dx - 24,
              top: at(page.corners[i]).dy - 24,
              child: Semantics(
                label: '${_names[i]} corner',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: !enabled
                      ? null
                      : (d) {
                          final next = [...page.corners];
                          final p = next[i] + Offset(d.delta.dx / rect.width, d.delta.dy / rect.height);
                          next[i] = Offset(p.dx.clamp(0, 1), p.dy.clamp(0, 1));
                          onChanged(next);
                        },
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: accent, width: 3)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ]);
      });
}

class _OutlinePainter extends CustomPainter {
  _OutlinePainter(this.points, this.color);
  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_OutlinePainter old) => old.points != points || old.color != color;
}
