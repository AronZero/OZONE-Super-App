import 'package:flutter/material.dart';

import '../../domain/validation.dart';
import '../theme/app_theme.dart';
import 'forms.dart';

/// A one-field dialog ("New folder", "Rename tag"). Returns the parsed value,
/// or null when cancelled. [parse] gives the error in words. [accent] colours
/// the action (the tool's accent).
Future<String?> promptName(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  String initial = '',
  String? hint,
  required Validation<String> Function(String) parse,
  required Color accent,
}) =>
    showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _NameDialog(title: title, label: label, action: action, initial: initial, hint: hint, parse: parse, accent: accent),
    );

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.label, required this.action, required this.initial, required this.hint, required this.parse, required this.accent});
  final String title, label, action, initial;
  final String? hint;
  final Validation<String> Function(String) parse;
  final Color accent;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _ctl = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _submit() {
    switch (widget.parse(_ctl.text)) {
      case Ok(:final value):
        Navigator.of(context).pop(value);
      case Invalid(:final reason):
        setState(() => _error = reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return AlertDialog(
      backgroundColor: c.surface,
      title: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
      content: OzoneTextField(
        label: widget.label,
        controller: _ctl,
        hint: widget.hint,
        error: _error,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() => _error = null),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: TextStyle(color: c.ink, fontWeight: FontWeight.w800))),
        TextButton(onPressed: _submit, child: Text(widget.action, style: TextStyle(color: widget.accent, fontWeight: FontWeight.w800))),
      ],
    );
  }
}
