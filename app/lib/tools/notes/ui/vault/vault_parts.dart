import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/security/secure_screen.dart';
import '../../../../core/security/vault_crypto.dart';
import '../../../../core/ui/theme/app_theme.dart';
import '../../../../core/ui/theme/tokens.dart';
import '../notes_parts.dart';
import '../../../../core/ui/amounts.dart';
import '../../../../core/ui/theme/oz_icons.dart';

/// The violet lock tile at the top of vault screens.
class VaultIcon extends StatelessWidget {
  const VaultIcon({super.key, this.icon = OzIcons.lock});
  final IconData icon;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: notesTile(context), borderRadius: BorderRadius.circular(20)),
      child: Icon(icon, size: 28, color: notesAccent(context)),
    ),
  );
}

/// A password field with Show/Hide. Never suggests, autocorrects or offers the
/// password to the keyboard's learning.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.error,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.newPassword = false,
    this.fill,
  });

  final String label;
  final TextEditingController controller;
  final String? error;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool newPassword;
  final Color? fill;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    OutlineInputBorder border(Color color, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.tile),
      borderSide: BorderSide(color: color, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: !_show,
          enableSuggestions: false,
          autocorrect: false,
          enableIMEPersonalizedLearning: false,
          autofocus: widget.autofocus,
          autofillHints: [widget.newPassword ? AutofillHints.newPassword : AutofillHints.password],
          keyboardType: TextInputType.visiblePassword,
          textInputAction: widget.onSubmitted == null ? TextInputAction.next : TextInputAction.done,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          cursorColor: c.ink,
          style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.fill ?? c.surfaceSunken,
            hintText: widget.hint,
            hintStyle: text.bodyLarge!.copyWith(color: c.inkMuted),
            contentPadding: const EdgeInsets.fromLTRB(Space.l, 15, Space.s, 15),
            suffixIcon: IconButton(
              tooltip: _show ? 'Hide password' : 'Show password',
              onPressed: () => setState(() => _show = !_show),
              icon: Icon(_show ? OzIcons.visibilityOff : OzIcons.visibility, color: c.inkMuted),
            ),
            border: border(Colors.transparent, 0),
            enabledBorder: border(widget.error == null ? Colors.transparent : c.danger, 2),
            focusedBorder: border(widget.error == null ? c.ink : c.danger, 2),
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              widget.error!,
              style: text.bodyMedium!.copyWith(color: c.danger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

/// Four bars and the words from the W1 · Vault setup board.
class StrengthMeter extends StatelessWidget {
  const StrengthMeter({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final level = passwordStrength(password);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 1; i <= 4; i++) ...[
                if (i > 1) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(color: i <= level ? notesAccent(context) : c.outline, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          liveRegion: true,
          child: Text(strengthWords[level], style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

/// The 16-character code in four boxes. Screenshots are blocked while it shows.
class RecoveryCodeView extends StatefulWidget {
  const RecoveryCodeView({super.key, required this.code});
  final String code;

  @override
  State<RecoveryCodeView> createState() => _RecoveryCodeViewState();
}

class _RecoveryCodeViewState extends State<RecoveryCodeView> {
  @override
  void initState() {
    super.initState();
    SecureScreen.set(SecureReason.recoveryCode, true);
  }

  @override
  void dispose() {
    SecureScreen.set(SecureReason.recoveryCode, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final groups = formatRecoveryCode(widget.code).split(' ');
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: spokenAmounts('Recovery code, in order: ${[for (var i = 0; i < groups.length; i++) 'group ${i + 1}, ${groups[i].split('').join(' ')}'].join('; ')}'),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
        child: Column(
          children: [
            for (var r = 0; r < 2; r++) ...[
              if (r > 0) const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: notesTile(context), borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        // Numbered 1–4 so the groups are read in order: left to right, then down.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${r * 2 + i + 1}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.inkMuted),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                groups[r * 2 + i],
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.2,
                                  color: dark ? notesAccent(context) : const Color(0xFF2E1F52),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "I've saved my recovery code" row.
class SavedCheck extends StatelessWidget {
  const SavedCheck({super.key, required this.value, required this.onChanged, required this.label});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      child: CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: notesAccent(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(label, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// A full-width violet (or disabled) button for vault screens.
class VaultButton extends StatelessWidget {
  const VaultButton({super.key, required this.label, required this.onPressed, this.busy = false, this.danger = false});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final bg = danger ? c.danger : notesAccent(context);
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: danger ? c.canvas : c.onAccent,
          disabledBackgroundColor: c.surfaceSunken,
          disabledForegroundColor: c.inkMuted,
          shape: const StadiumBorder(),
          textStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
        ),
        child: busy
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: c.inkMuted)),
                  const SizedBox(width: Space.m),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }
}

/// Upper-case input for codes and DELETE.
final List<TextInputFormatter> upperCase = [TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase()))];
