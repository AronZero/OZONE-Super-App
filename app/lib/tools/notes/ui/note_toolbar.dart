import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/ui/theme/app_theme.dart';
import '../domain/notes.dart';
import 'notes_parts.dart';
import '../../../core/ui/amounts.dart';

Color _hex(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));

/// A palette colour as drawn in the current theme.
Color paletteColour(BuildContext context, String stored) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return _hex(dark ? (darkColourOf(stored) ?? stored) : stored);
}

/// Draws stored palette colours with their dark values in dark mode.
TextStyle noteColourStyles(BuildContext context, Attribute<dynamic> attr) {
  if (Theme.of(context).brightness != Brightness.dark || attr.value is! String) return const TextStyle();
  final v = attr.value as String;
  if (attr.key == Attribute.color.key) return TextStyle(color: paletteColour(context, v));
  if (attr.key == Attribute.background.key) return TextStyle(backgroundColor: paletteColour(context, v));
  return const TextStyle();
}

enum _Palette { none, highlight, colour }

/// The formatting bar of W1 · Note editor (F2-02 §2), with the text colour and
/// highlight palettes of the Components board opening above it.
class NoteToolbar extends StatefulWidget {
  const NoteToolbar({super.key, required this.controller});
  final QuillController controller;

  @override
  State<NoteToolbar> createState() => _NoteToolbarState();
}

class _NoteToolbarState extends State<NoteToolbar> {
  _Palette _open = _Palette.none;

  QuillController get _q => widget.controller;

  @override
  void initState() {
    super.initState();
    _q.addListener(_changed);
  }

  @override
  void didUpdateWidget(NoteToolbar old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _q.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Map<String, Attribute<dynamic>> get _style => _q.getSelectionStyle().attributes;

  void _toggle(Attribute<dynamic> a) {
    final on = _style[a.key]?.value == a.value;
    _q.formatSelection(on ? Attribute.clone(a, null) : a);
  }

  void _toggleList(Attribute<dynamic> a) {
    final cur = _style[Attribute.list.key]?.value;
    final on = a == Attribute.unchecked ? (cur == 'checked' || cur == 'unchecked') : cur == a.value;
    _q.formatSelection(on ? Attribute.clone(Attribute.list, null) : a);
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final accent = notesAccent(context);
    final s = _style;
    final list = s[Attribute.list.key]?.value;
    final colour = s[Attribute.color.key]?.value as String?;
    final highlight = s[Attribute.background.key]?.value as String?;

    Widget button(String label, Widget icon, {bool active = false, VoidCallback? onTap, bool toggle = true}) => Expanded(
          child: Semantics(
            button: true,
            toggled: toggle ? active : null,
            label: spokenAmounts(label),
            excludeSemantics: true,
            child: Tooltip(
              message: label,
              child: Material(
                color: active ? notesTile(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap,
                  child: SizedBox(
                    height: 48,
                    child: Center(child: IconTheme(data: IconThemeData(color: active ? accent : c.ink, size: 20), child: icon)),
                  ),
                ),
              ),
            ),
          ),
        );

    TextStyle letter(bool active, {FontStyle? style, TextDecoration? deco, double size = 17}) => TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          fontStyle: style,
          decoration: deco,
          decorationColor: active ? accent : c.ink,
          color: active ? accent : c.ink,
          height: 1,
        );

    Widget swatch(String label, Color fill, {required bool selected, required VoidCallback onTap, bool round = true, bool dashed = false}) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Semantics(
            button: true,
            selected: selected,
            label: spokenAmounts(label),
            excludeSemantics: true,
            child: InkResponse(
              onTap: onTap,
              radius: 24,
              child: SizedBox(
                width: 44,
                height: 48,
                // The chosen colour gets an accent ring with a gap, visible on any fill.
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(round ? 20 : 13),
                      border: Border.all(color: selected ? notesAccent(context) : Colors.transparent, width: 2),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: dashed ? Colors.transparent : fill,
                        borderRadius: BorderRadius.circular(round ? 15 : 9),
                        border: dashed ? Border.all(color: c.inkMuted, width: 1.5) : null,
                      ),
                      child: dashed ? Icon(Icons.format_color_reset_outlined, size: 16, color: c.inkMuted) : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    final palette = switch (_open) {
      _Palette.none => null,
      _Palette.colour => Row(children: [
          swatch('Default colour', c.ink, selected: colour == null, onTap: () => _q.formatSelection(const ColorAttribute(null))),
          for (final (name, hex, _) in textColours)
            swatch(name, paletteColour(context, hex), selected: colour?.toUpperCase() == hex, onTap: () => _q.formatSelection(ColorAttribute(hex))),
        ]),
      _Palette.highlight => Row(children: [
          for (final (name, hex, _) in highlightColours)
            swatch('$name highlight', paletteColour(context, hex), round: false, selected: highlight?.toUpperCase() == hex, onTap: () => _q.formatSelection(BackgroundAttribute(hex))),
          swatch('No highlight', Colors.transparent, round: false, dashed: true, selected: false, onTap: () => _q.formatSelection(const BackgroundAttribute(null))),
        ]),
    };

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (palette != null)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: palette),
        ),
      Semantics(
        container: true,
        label: 'Formatting',
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            button('Bold', Text('B', style: letter(s.containsKey('bold'))), active: s.containsKey('bold'), onTap: () => _toggle(Attribute.bold)),
            button('Italic', Text('I', style: letter(s.containsKey('italic'), style: FontStyle.italic)), active: s.containsKey('italic'), onTap: () => _toggle(Attribute.italic)),
            button('Underline', Text('U', style: letter(s.containsKey('underline'), deco: TextDecoration.underline)),
                active: s.containsKey('underline'), onTap: () => _toggle(Attribute.underline)),
            button('Heading', Text('H', style: letter(s[Attribute.header.key]?.value == 2, size: 16)),
                active: s[Attribute.header.key]?.value == 2, onTap: () => _toggle(Attribute.h2)),
            button('Bulleted list', const Icon(Icons.format_list_bulleted_rounded), active: list == 'bullet', onTap: () => _toggleList(Attribute.ul)),
            button('Numbered list', Text('1.', style: letter(list == 'ordered', size: 13)), active: list == 'ordered', onTap: () => _toggleList(Attribute.ol)),
            button('Checklist', const Icon(Icons.check_box_outlined), active: list == 'checked' || list == 'unchecked', onTap: () => _toggleList(Attribute.unchecked)),
            button(
              'Highlight',
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('ab', style: letter(_open == _Palette.highlight, size: 14)),
                const SizedBox(height: 2),
                Container(width: 18, height: 4, decoration: BoxDecoration(color: paletteColour(context, highlight ?? highlightColours.first.$2), borderRadius: BorderRadius.circular(2))),
              ]),
              active: _open == _Palette.highlight,
              onTap: () => setState(() => _open = _open == _Palette.highlight ? _Palette.none : _Palette.highlight),
            ),
            button(
              'Text colour',
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('A', style: letter(_open == _Palette.colour, size: 15)),
                const SizedBox(height: 2),
                Container(width: 18, height: 4, decoration: BoxDecoration(color: colour == null ? accent : paletteColour(context, colour), borderRadius: BorderRadius.circular(2))),
              ]),
              active: _open == _Palette.colour,
              onTap: () => setState(() => _open = _open == _Palette.colour ? _Palette.none : _Palette.colour),
            ),
            button('Undo', Icon(Icons.undo_rounded, color: _q.hasUndo ? c.ink : c.outline), toggle: false, onTap: _q.hasUndo ? _q.undo : null),
          ]),
        ),
      ),
    ]);
  }
}
