import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/security/vault_crypto.dart';
import '../../../core/security/vault_service.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/notes_repo.dart';
import '../domain/notes.dart';
import '../state/note_autosave.dart';
import '../state/notes_providers.dart';
import '../state/notes_vault.dart';
import 'note_sheets.dart';
import 'note_toolbar.dart';
import 'notes_parts.dart';
import 'vault/vault_unlock.dart';

/// W1 · Note editor: folder and tag chips, title, "Edited …", rich text and the
/// formatting bar. Saves itself (F2-02 §3) and never asks "discard changes?".
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId, this.isNew = false});
  final String noteId;
  final bool isNew;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> with WidgetsBindingObserver {
  late final NotesRepo _repo = ref.read(notesRepoProvider);
  late final VaultService _vault = ref.read(vaultServiceProvider);
  late final NotesVault _notesVault = ref.read(notesVaultProvider);
  final _title = TextEditingController();
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();
  final _scroll = ScrollController();
  QuillController? _q;
  StreamSubscription<DocChange>? _changes;
  NoteAutosave? _autosave;
  bool _missing = false;
  bool _recovered = false;
  bool _trashing = false;

  /// A locked note: its text is sealed with DK on every save, its tags live
  /// inside the lock (read-only here, decision M6-2), and it closes when the
  /// vault relocks (F2-01 §4).
  bool _locked = false;
  List<String> _lockedTags = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vault.isOpen.addListener(_vaultChanged);
    _vault.addBeforeLock(_saveBeforeLock);
    unawaited(_load());
  }

  Future<void> _saveBeforeLock() async => _autosave?.saveNow();

  /// The vault relocked: a locked note closes (its text was saved first).
  void _vaultChanged() {
    if (_locked && !_vault.isOpen.value && mounted) Navigator.of(context).maybePop();
  }

  Future<void> _load() async {
    _title.removeListener(_titleChanged);
    _autosave?.removeListener(_rebuild);
    _autosave?.dispose();
    _autosave = null;
    final n = await _repo.note(widget.noteId);
    if (!mounted) return;
    if (n == null || n.trashedAt != null || (n.isLocked && !_vault.isOpen.value)) {
      setState(() => _missing = true);
      return;
    }
    final id = n.id;
    NoteDraft? draft;
    String? title;
    List<Object?> ops;
    if (n.isLocked) {
      final LockedNote p;
      try {
        p = await _notesVault.read(id, n.cipher!);
      } on Object {
        if (mounted) setState(() => _missing = true);
        return;
      }
      draft = await _notesVault.recoverableDraft(id);
      title = p.title;
      ops = _decode(p.content);
      _lockedTags = p.tags;
      _autosave = NoteAutosave(
        save: (t, o) => _notesVault.save(id, title: t, ops: o, tags: _lockedTags),
        draft: (t, o) => _notesVault.writeDraft(id, title: t, ops: o),
        read: _read,
      );
    } else {
      draft = await _repo.recoverableDraft(id);
      title = n.title;
      ops = _decode(n.content);
      _lockedTags = const [];
      _autosave = NoteAutosave(
        save: (t, o) => _repo.save(id, title: t, ops: o),
        draft: (t, o) => _repo.writeDraft(id, title: t, ops: o),
        read: _read,
      );
    }
    if (!mounted) return;
    _locked = n.isLocked;
    _title.text = draft?.title ?? title ?? '';
    _lastTitle = _title.text;
    _setDocument(draft?.ops ?? ops);
    _autosave!.addListener(_rebuild);
    _title.addListener(_titleChanged);
    setState(() {
      _missing = false;
      _recovered = draft != null;
    });
    if (widget.isNew) _titleFocus.requestFocus();
  }

  static List<Object?> _decode(String? json) {
    try {
      return sanitizeDelta(jsonDecode(json ?? '[]') as List<Object?>);
    } on Object {
      return sanitizeDelta(const []);
    }
  }

  void _setDocument(List<Object?> ops) {
    _changes?.cancel();
    final old = _q;
    _q = QuillController(
      document: Document.fromJson(sanitizeDelta(ops)),
      selection: const TextSelection.collapsed(offset: 0),
      // Pasting from other apps brings plain text only (no links, fonts or sizes).
      // The setting is marked experimental upstream; sanitizeDelta still cleans every save.
      config: const QuillControllerConfig(
        // ignore: experimental_member_use
        clipboardConfig: QuillClipboardConfig(
          // ignore: experimental_member_use
          enableExternalRichPaste: false,
        ),
      ),
    );
    _changes = _q!.document.changes.listen(_docChanged);
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  String _lastTitle = '';
  void _titleChanged() {
    if (_title.text == _lastTitle) return; // selection moves only
    _lastTitle = _title.text;
    _autosave?.changed();
  }

  void _docChanged(DocChange c) {
    if (c.source != ChangeSource.local) return;
    // Typed web addresses become plain text: links aren't part of v1 (F2-02 §2).
    if (c.change.toList().any((op) => op.attributes?.containsKey(Attribute.link.key) ?? false)) {
      scheduleMicrotask(_stripLinks);
    }
    _autosave?.changed();
  }

  void _stripLinks() {
    final q = _q;
    if (q == null) return;
    var at = 0;
    for (final op in q.document.toDelta().toList()) {
      final len = op.length ?? 0;
      if (op.attributes?.containsKey(Attribute.link.key) ?? false) q.formatText(at, len, const LinkAttribute(null));
      at += len;
    }
  }

  (String, List<Object?>) _read() => (_title.text, _q?.document.toDelta().toJson() ?? const []);

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save at once when OZONE leaves the screen (F2-02 §3).
    if (state != AppLifecycleState.resumed) unawaited(_autosave?.saveNow());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vault.isOpen.removeListener(_vaultChanged);
    _vault.removeBeforeLock(_saveBeforeLock);
    final save = _autosave?.saveNow() ?? Future<void>.value();
    final repo = _repo;
    final id = widget.noteId;
    // A new note left empty is deleted silently (F2-02 §3).
    unawaited(save.then((_) => repo.deleteIfBlankNew(id)));
    _autosave?.dispose();
    _changes?.cancel();
    _q?.dispose();
    _title.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _keep() async {
    _autosave?.changed();
    await _autosave?.saveNow();
    if (mounted) setState(() => _recovered = false);
  }

  Future<void> _discard() async {
    await _repo.discardDraft(widget.noteId);
    await _load();
  }

  Future<void> _menu() async {
    await _autosave?.saveNow();
    if (!mounted) return;
    final r = await showNoteMenu(context, widget.noteId);
    if (!mounted) return;
    switch (r) {
      case NoteMenuResult.trash:
        await _trash();
      case NoteMenuResult.lock:
        await _lockNote();
      case NoteMenuResult.removeLock:
        await _removeLock();
      case null:
        break;
    }
  }

  /// Lock note (F2-01 §4): set up the vault the first time, else unlock it; then seal.
  Future<void> _lockNote() async {
    await _autosave?.saveNow();
    if (!mounted || !await ensureVaultOpen(context, ref, forLocking: true) || !mounted) return;
    await _notesVault.lock(widget.noteId);
    await _load();
    if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Note locked. It isn’t searched while locked.')));
  }

  Future<void> _removeLock() async {
    await _autosave?.saveNow();
    await _notesVault.removeLock(widget.noteId);
    await _load();
  }

  Future<void> _trash() async {
    if (_trashing) return;
    _trashing = true;
    await _autosave?.saveNow();
    final n = await _repo.note(widget.noteId);
    if (!mounted || n == null) return;
    Navigator.of(context).pop();
    await trashWithUndo(ref, n);
  }

  DefaultStyles _styles(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final body = Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 17, height: 26 / 17, color: c.ink, fontWeight: FontWeight.w400);
    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(body, HorizontalSpacing.zero, const VerticalSpacing(0, 6), VerticalSpacing.zero, null),
      h2: DefaultTextBlockStyle(body.copyWith(fontSize: 20, height: 1.35, fontWeight: FontWeight.w800), HorizontalSpacing.zero, const VerticalSpacing(10, 4),
          VerticalSpacing.zero, null),
      lists: DefaultListBlockStyle(body, HorizontalSpacing.zero, const VerticalSpacing(2, 6), const VerticalSpacing(0, 4), null, null),
      placeHolder: DefaultTextBlockStyle(body.copyWith(color: c.inkMuted), HorizontalSpacing.zero, VerticalSpacing.zero, VerticalSpacing.zero, null),
      bold: const TextStyle(fontWeight: FontWeight.w800),
      underline: const TextStyle(decoration: TextDecoration.underline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final data = ref.watch(notesDataProvider).value;
    final n = data?.byId(widget.noteId);
    final q = _q;

    if (_missing || (data != null && n == null && q != null && !_trashing)) {
      return Scaffold(
        backgroundColor: c.surface,
        body: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const DetailTopBar(title: 'Note', overline: 'Notes'),
            Padding(padding: const EdgeInsets.all(Space.xl), child: Text('This note isn\'t available.', style: text.bodyLarge)),
          ]),
        ),
      );
    }

    final saving = _autosave?.dirty ?? false;
    final tags = n == null ? const <TagRow>[] : data!.tagsOf(n.id);
    final folderName = data?.folder(n?.folderId)?.name ?? 'Unfiled';
    final accent = notesAccent(context);

    Widget pill(String label, {IconData? icon, required VoidCallback onTap, bool tinted = false, bool plain = false}) => Material(
          color: plain ? Colors.transparent : (tinted ? notesTile(context) : c.surfaceSunken),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 15, color: c.ink), const SizedBox(width: 6)],
                Text(label, style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: tinted ? FontWeight.w800 : FontWeight.w700, color: tinted ? accent : (plain ? c.inkMuted : c.ink))),
              ]),
            ),
          ),
        );

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.s, Space.xs),
            child: Row(children: [
              IconButton(
                tooltip: 'Back to Notes',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.arrow_back_rounded, color: c.ink),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Row(children: [
                    if (!saving) ...[Icon(Icons.check_rounded, size: 16, color: c.inkMuted), const SizedBox(width: 6)],
                    Text(q == null ? '' : (saving ? 'Saving…' : 'Saved'), style: text.bodyMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: c.inkMuted)),
                  ]),
                ),
              ),
              if (n != null)
                IconButton(
                  tooltip: n.isPinned ? 'Unpin' : 'Pin to top',
                  isSelected: n.isPinned,
                  onPressed: () => _repo.setPinned(n.id, !n.isPinned),
                  icon: Icon(n.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: n.isPinned ? accent : c.ink, size: 21),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              IconButton(
                tooltip: 'Note options: folder, tags, lock, move to trash',
                onPressed: q == null ? null : _menu,
                icon: Icon(Icons.more_vert_rounded, color: c.ink),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ]),
          ),
          if (q == null)
            const Expanded(child: SizedBox.shrink())
          else ...[
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                // A tap below the text puts the cursor at the end.
                onTap: () => _bodyFocus.requestFocus(),
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(22, Space.xs, 22, Space.xxl),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (_recovered) ...[
                      AttentionBanner(
                        title: 'Recovered unsaved changes',
                        body: 'OZONE closed before this note was saved. The text below includes what you typed.',
                        action: Row(children: [
                          Expanded(child: OzoneButton(label: 'Keep', height: 44, color: c.attentionInk, foreground: c.attentionBg, onPressed: _keep)),
                          const SizedBox(width: Space.s),
                          Expanded(child: OzoneButton(label: 'Discard', height: 44, primary: false, onPressed: _discard)),
                        ]),
                      ),
                      const SizedBox(height: Space.m),
                    ],
                    Wrap(spacing: Space.s, runSpacing: Space.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      pill('$folderName ▾', icon: Icons.folder_outlined, onTap: () => showFolderPicker(context, widget.noteId)),
                      if (_locked) ...[
                        pill('Locked', icon: Icons.lock_outline_rounded, tinted: true, onTap: _menu),
                        // Tags are sealed with the note; they change after Remove lock (M6-2).
                        for (final t in _lockedTags)
                          pill('#$t', tinted: true, onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tags of a locked note change after you remove the lock.')),
                              )),
                      ] else ...[
                        for (final t in tags) pill('#${t.name}', tinted: true, onTap: () => showTagsSheet(context, widget.noteId)),
                        pill('+ Tag', plain: true, onTap: () => showTagsSheet(context, widget.noteId)),
                      ],
                    ]),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _title,
                      focusNode: _titleFocus,
                      maxLines: null,
                      maxLength: noteTitleMax,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _bodyFocus.requestFocus(),
                      cursorColor: accent,
                      style: text.headlineMedium!.copyWith(fontSize: 28, fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: text.headlineMedium!.copyWith(fontSize: 28, fontWeight: FontWeight.w800, color: c.inkMuted.withValues(alpha: 0.6)),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                    if (n != null && n.editedAt != n.createdAt) ...[
                      const SizedBox(height: 6),
                      Text('Edited ${dateTimeText(n.editedAt)}', style: text.bodyMedium!.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: c.inkMuted)),
                    ],
                    const SizedBox(height: 14),
                    Theme(
                      // Checkboxes and the cursor in the Notes accent.
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(primary: accent, onPrimary: c.onAccent),
                        textSelectionTheme: TextSelectionThemeData(cursorColor: accent, selectionColor: accent.withValues(alpha: 0.25), selectionHandleColor: accent),
                      ),
                      child: QuillEditor(
                        controller: q,
                        focusNode: _bodyFocus,
                        scrollController: _scroll,
                        config: QuillEditorConfig(
                          scrollable: false,
                          placeholder: 'Start writing…',
                          customStyles: _styles(context),
                          customStyleBuilder: (attr) => noteColourStyles(context, attr),
                          onLaunchUrl: (_) {},
                          linkActionPickerDelegate: (_, _, _) async => LinkMenuAction.none,
                          textCapitalization: TextCapitalization.sentences,
                          minHeight: 240,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Space.s, 0, Space.s, MediaQuery.viewInsetsOf(context).bottom > 0 ? Space.s : Space.l),
              child: NoteToolbar(controller: q),
            ),
          ],
        ]),
      ),
    );
  }
}
