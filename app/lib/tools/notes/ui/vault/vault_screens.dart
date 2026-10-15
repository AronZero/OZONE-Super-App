import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/vault_crypto.dart';
import '../../../../core/security/vault_service.dart';
import '../../../../core/state/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../core/ui/theme/app_theme.dart';
import '../../../../core/ui/theme/tokens.dart';
import '../notes_parts.dart';
import 'vault_parts.dart';
import '../../../../core/ui/theme/oz_icons.dart';

/// Shared frame: back + step label, scrolling body, button pinned at the bottom.
class _VaultFrame extends StatelessWidget {
  const _VaultFrame({required this.step, required this.children, required this.bottom, this.onBack, this.title});
  final String step;
  final String? title;
  final List<Widget> children;
  final Widget bottom;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.s, 6),
            child: Row(children: [
              IconButton(
                tooltip: 'Back',
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: Icon(OzIcons.arrowBack, color: c.ink),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: title != null
                    ? Semantics(header: true, child: Text(title!, style: text.titleLarge))
                    : Text(step, style: text.bodyMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: c.inkMuted)),
              ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Space.xl, Space.xs, Space.xl, Space.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final w in children) Padding(padding: const EdgeInsets.only(bottom: Space.l), child: w)],
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(Space.xl, Space.m, Space.xl, Space.xl), child: bottom),
        ]),
      ),
    );
  }
}

Widget _h1(BuildContext context, String s) =>
    Semantics(header: true, child: Text(s, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)));

Widget _p(BuildContext context, String s) => Text(s, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 15, height: 1.55, color: OzoneThemeColors.of(context).inkMuted));

/// Checks a new password pair; null when fine.
(String?, String?) _checkNew(String a, String b) {
  if (a.runes.length < 8) return ('Use at least 8 characters', null);
  if (a != b) return (null, 'The two passwords don’t match');
  return (null, null);
}

/// The ✓ / ✕ advice under a recovery code (W1 · Recovery code board).
Widget _codeAdvice(BuildContext context) {
  final text = Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14, height: 1.5);
  Widget line(String mark, String s) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ExcludeSemantics(child: SizedBox(width: 22, child: Text(mark, style: text))),
        Expanded(child: Text(s, style: text)),
      ]);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    line('✓', 'Write it on paper, or store it in a password manager.'),
    const SizedBox(height: Space.s),
    line('✓', 'Keep it apart from your phone.'),
    const SizedBox(height: Space.s),
    line('✕', 'Don’t save it in a note, a photo or a screenshot. Screenshots are blocked on this screen.'),
  ]);
}

// ── Set up (W1 · Vault setup 1/2 and 2/2) ──────────────────────────────────

class VaultSetupScreen extends ConsumerStatefulWidget {
  const VaultSetupScreen({super.key, this.forLocking = false});

  /// Opened from "Lock note": the last button says "Finish · lock this note".
  final bool forLocking;

  @override
  ConsumerState<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

class _VaultSetupScreenState extends ConsumerState<VaultSetupScreen> {
  final _pw = TextEditingController(), _pw2 = TextEditingController();
  String? _e1, _e2;
  bool _bio = false, _bioAvailable = false;
  int _step = 1;
  late final String _code = newRecoveryCode();
  bool _saved = false, _busy = false;

  VaultService get _vault => ref.read(vaultServiceProvider);

  @override
  void initState() {
    super.initState();
    _vault.biometricAvailable().then((v) {
      if (mounted) setState(() => _bioAvailable = _bio = v);
    });
  }

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _continue() {
    final (a, b) = _checkNew(_pw.text, _pw2.text);
    setState(() {
      _e1 = a;
      _e2 = b;
    });
    if (a == null && b == null) setState(() => _step = 2);
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    await _vault.create(password: _pw.text, recoveryCode: _code, biometric: _bio && _bioAvailable);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    if (_step == 1) {
      return _VaultFrame(
        step: 'Step 1 of 2',
        bottom: VaultButton(label: 'Continue', onPressed: _continue),
        children: [
          const Align(alignment: Alignment.centerLeft, child: VaultIcon()),
          _h1(context, 'Set up your notes vault'),
          _p(context, 'One password protects all locked notes on this phone. OZONE never stores it.'),
          AttentionBanner(
            title: 'Keep both safe',
            body: 'If you lose both this password and your recovery code, nobody can open your locked notes, not even OZONE.',
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PasswordField(
              label: 'Vault password',
              hint: 'At least 8 characters',
              controller: _pw,
              error: _e1,
              newPassword: true,
              autofocus: true,
              onChanged: (_) => setState(() => _e1 = null),
            ),
            const SizedBox(height: Space.s),
            StrengthMeter(password: _pw.text),
          ]),
          PasswordField(
            label: 'Confirm password',
            controller: _pw2,
            error: _e2,
            newPassword: true,
            onChanged: (_) => setState(() => _e2 = null),
            onSubmitted: (_) => _continue(),
          ),
          if (_bioAvailable)
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Unlock with fingerprint', style: text.bodyLarge!.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Your password still works as a backup', style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
                ]),
              ),
              OzoneSwitch(value: _bio, onChanged: (v) => setState(() => _bio = v), label: 'Unlock with fingerprint', accent: notesAccent(context)),
            ]),
        ],
      );
    }
    return _VaultFrame(
      step: 'Step 2 of 2',
      onBack: _busy ? () {} : () => setState(() => _step = 1),
      bottom: VaultButton(
        label: _busy ? 'Setting up the vault…' : (_saved ? (widget.forLocking ? 'Finish · lock this note' : 'Finish') : 'Finish · tick the box first'),
        busy: _busy,
        onPressed: _saved ? _finish : null,
      ),
      children: [
        _h1(context, 'Save your recovery code'),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'It’s the only way back in if you forget your vault password. It’s shown '),
            TextSpan(text: 'once', style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
            const TextSpan(text: '.'),
          ]),
          style: text.bodyLarge!.copyWith(fontSize: 15, height: 1.55, color: c.inkMuted),
        ),
        RecoveryCodeView(code: _code),
        _codeAdvice(context),
        SavedCheck(value: _saved, onChanged: _busy ? (_) {} : (v) => setState(() => _saved = v), label: 'I’ve saved my recovery code'),
      ],
    );
  }
}

// ── Forgot password (W3 · Forgot vault password, 3 steps) ──────────────────

class VaultForgotScreen extends ConsumerStatefulWidget {
  const VaultForgotScreen({super.key});

  @override
  ConsumerState<VaultForgotScreen> createState() => _VaultForgotScreenState();
}

class _VaultForgotScreenState extends ConsumerState<VaultForgotScreen> {
  final _code = TextEditingController(), _pw = TextEditingController(), _pw2 = TextEditingController();
  String? _eCode, _e1, _e2;
  int _step = 1;
  bool _busy = false, _saved = false;
  late final String _newCode = newRecoveryCode();

  VaultService get _vault => ref.read(vaultServiceProvider);

  @override
  void dispose() {
    _code.dispose();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _checkCode() async {
    if (normaliseRecoveryCode(_code.text).length != 16) {
      setState(() => _eCode = 'The code has 16 letters and numbers');
      return;
    }
    setState(() => _busy = true);
    final ok = await _vault.openWithRecoveryCode(_code.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _step = 2;
      } else {
        _eCode = 'That code doesn’t match this vault. Check it and try again.';
      }
    });
  }

  void _toStep3() {
    final (a, b) = _checkNew(_pw.text, _pw2.text);
    setState(() {
      _e1 = a;
      _e2 = b;
      if (a == null && b == null) _step = 3;
    });
  }

  Future<void> _done() async {
    setState(() => _busy = true);
    await _vault.finishRecovery(newPassword: _pw.text, newCode: _newCode);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final step = 'Forgot vault password · $_step of 3';
    switch (_step) {
      case 1:
        return _VaultFrame(
          step: step,
          bottom: VaultButton(label: _busy ? 'Checking the code…' : 'Continue', busy: _busy, onPressed: _checkCode),
          children: [
            const Align(alignment: Alignment.centerLeft, child: VaultIcon(icon: OzIcons.key)),
            _h1(context, 'Use your recovery code'),
            _p(context, 'Enter the 16-character code you saved when you set up the vault. Then you’ll choose a new password.'),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recovery code', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _code,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: upperCase,
                onChanged: (_) => setState(() => _eCode = null),
                onSubmitted: (_) => _checkCode(),
                style: text.titleMedium!.copyWith(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.surface,
                  hintText: 'XXXX XXXX XXXX XXXX',
                  errorText: _eCode,
                  errorMaxLines: 3,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.tile), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 6),
              Text('Spaces and lower case are fine.', style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
            ]),
            Container(
              padding: const EdgeInsets.fromLTRB(Space.l, 14, Space.l, Space.s),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Don’t have the code?', style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Without the password or the code, locked notes can’t be opened by anyone. You can reset the vault, which deletes them.',
                    style: text.bodyMedium!.copyWith(fontSize: 13, height: 1.5, fontWeight: FontWeight.w600, color: c.inkMuted)),
                TextButton(
                  onPressed: () => context.pushReplacement('/notes/vault/reset'),
                  style: TextButton.styleFrom(foregroundColor: c.danger, padding: EdgeInsets.zero, minimumSize: const Size(48, 48)),
                  child: const Text('Reset vault…', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ],
        );
      case 2:
        return _VaultFrame(
          step: step,
          bottom: VaultButton(label: 'Save new password', onPressed: _toStep3),
          children: [
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: notesTile(context), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(OzIcons.check, size: 16, color: notesAccent(context)),
                  const SizedBox(width: Space.s),
                  Text('Code accepted', style: text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: notesAccent(context))),
                ]),
              ),
            ),
            _h1(context, 'Choose a new password'),
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PasswordField(label: 'New vault password', controller: _pw, error: _e1, newPassword: true, autofocus: true, fill: c.surface, onChanged: (_) => setState(() => _e1 = null)),
              const SizedBox(height: Space.s),
              StrengthMeter(password: _pw.text),
            ]),
            PasswordField(label: 'Type it again', controller: _pw2, error: _e2, newPassword: true, fill: c.surface, onChanged: (_) => setState(() => _e2 = null), onSubmitted: (_) => _toStep3()),
            _p(context, 'Your locked notes stay as they are. Only the password changes.'),
          ],
        );
      default:
        return _VaultFrame(
          step: step,
          onBack: _busy ? () {} : () => setState(() => _step = 2),
          bottom: VaultButton(label: _busy ? 'Saving…' : 'Done', busy: _busy, onPressed: _saved ? _done : null),
          children: [
            _h1(context, 'Save your new recovery code'),
            _p(context, 'Your old code was used up and no longer works. Write this one down and keep it away from your phone.'),
            RecoveryCodeView(code: _newCode),
            SavedCheck(value: _saved, onChanged: _busy ? (_) {} : (v) => setState(() => _saved = v), label: 'I’ve saved my new code'),
          ],
        );
    }
  }
}

// ── Reset (W3 · Reset vault) ───────────────────────────────────────────────

class VaultResetScreen extends ConsumerStatefulWidget {
  const VaultResetScreen({super.key});

  @override
  ConsumerState<VaultResetScreen> createState() => _VaultResetScreenState();
}

class _VaultResetScreenState extends ConsumerState<VaultResetScreen> {
  final _typed = TextEditingController();
  int? _count;
  int? _deleted;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(vaultServiceProvider).lockedNoteCount().then((n) {
      if (mounted) setState(() => _count = n);
    });
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    setState(() => _busy = true);
    final n = await ref.read(vaultServiceProvider).reset();
    if (mounted) setState(() => _deleted = n);
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final n = _count ?? 0;
    final notes = '$n locked ${n == 1 ? 'note' : 'notes'}';
    if (_deleted != null) {
      final d = _deleted!;
      return _VaultFrame(
        step: '',
        title: 'Reset vault',
        bottom: OzoneButton(label: 'Go to Notes', onPressed: () => context.go('/notes')),
        children: [
          const SizedBox(height: Space.xxl),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
              child: Icon(OzIcons.check, size: 28, color: c.ink),
            ),
          ),
          Semantics(liveRegion: true, child: Text('Vault reset', textAlign: TextAlign.center, style: text.titleLarge!.copyWith(fontSize: 22))),
          Text(
            '${d == 0 ? 'No locked notes were' : '$d locked ${d == 1 ? 'note was' : 'notes were'}'} deleted. Lock any note to set up a new vault with a new password.',
            textAlign: TextAlign.center,
            style: text.bodyLarge!.copyWith(fontSize: 15, height: 1.55, color: c.inkMuted),
          ),
        ],
      );
    }
    final ready = _typed.text.trim().toUpperCase() == 'DELETE';
    return _VaultFrame(
      step: '',
      title: 'Reset vault',
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        VaultButton(label: 'Delete locked notes and reset', danger: true, busy: _busy, onPressed: ready ? _reset : null),
        const SizedBox(height: Space.m),
        OzoneButton(label: 'Keep my vault', primary: false, height: 48, onPressed: () => Navigator.of(context).pop()),
      ]),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, Space.l, 18, Space.l),
          decoration: BoxDecoration(color: c.danger.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(Radii.card)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(OzIcons.warning, size: 20, color: c.danger),
              const SizedBox(width: Space.s),
              Expanded(child: Text(n == 0 ? 'There are no locked notes to delete' : 'This deletes $notes forever', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800, color: c.danger))),
            ]),
            const SizedBox(height: Space.s),
            Text('They can’t be moved to the trash or brought back. Your other notes aren’t touched.', style: text.bodyMedium!.copyWith(fontSize: 14, height: 1.55, fontWeight: FontWeight.w600)),
          ]),
        ),
        for (final s in [
          'The vault password, fingerprint unlock and recovery code are removed.',
          'Next time you lock a note, you’ll set up a new vault.',
          'Older exports still hold the locked notes, encrypted with the old password.',
        ])
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ExcludeSemantics(child: Text('•  ', style: text.bodyMedium!.copyWith(fontSize: 14))),
            Expanded(child: Text(s, style: text.bodyMedium!.copyWith(fontSize: 14, height: 1.5, color: c.inkMuted))),
          ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Type DELETE to confirm', style: text.bodyMedium!.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _typed,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: upperCase,
            onChanged: (_) => setState(() {}),
            style: text.titleMedium!.copyWith(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1.4),
            decoration: InputDecoration(
              filled: true,
              fillColor: c.surface,
              hintText: 'DELETE',
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.tile), borderSide: BorderSide(color: ready ? c.danger : Colors.transparent, width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.tile), borderSide: BorderSide(color: ready ? c.danger : c.ink, width: 2)),
            ),
          ),
        ]),
      ],
    );
  }
}

// ── Change password (not drawn; decision M6-5) ─────────────────────────────

class VaultChangePasswordScreen extends ConsumerStatefulWidget {
  const VaultChangePasswordScreen({super.key});

  @override
  ConsumerState<VaultChangePasswordScreen> createState() => _VaultChangePasswordScreenState();
}

class _VaultChangePasswordScreenState extends ConsumerState<VaultChangePasswordScreen> {
  final _old = TextEditingController(), _pw = TextEditingController(), _pw2 = TextEditingController();
  String? _e0, _e1, _e2;
  bool _busy = false;

  @override
  void dispose() {
    _old.dispose();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final (a, b) = _checkNew(_pw.text, _pw2.text);
    setState(() {
      _e0 = _old.text.isEmpty ? 'Type your current vault password' : null;
      _e1 = a;
      _e2 = b;
    });
    if (_e0 != null || a != null || b != null) return;
    setState(() => _busy = true);
    final ok = await ref.read(vaultServiceProvider).changePassword(_old.text, _pw.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() => _e0 = 'That password isn’t right');
      return;
    }
    Navigator.of(context).pop(true);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Vault password changed')));
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return _VaultFrame(
      step: '',
      title: 'Change vault password',
      bottom: VaultButton(label: _busy ? 'Saving…' : 'Change password', busy: _busy, onPressed: _save),
      children: [
        PasswordField(label: 'Current password', controller: _old, error: _e0, autofocus: true, fill: c.surface, onChanged: (_) => setState(() => _e0 = null)),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PasswordField(label: 'New password', controller: _pw, error: _e1, newPassword: true, fill: c.surface, onChanged: (_) => setState(() => _e1 = null)),
          const SizedBox(height: Space.s),
          StrengthMeter(password: _pw.text),
        ]),
        PasswordField(label: 'Type it again', controller: _pw2, error: _e2, newPassword: true, fill: c.surface, onChanged: (_) => setState(() => _e2 = null), onSubmitted: (_) => _save()),
        _p(context, 'Your locked notes stay as they are. Your recovery code keeps working.'),
      ],
    );
  }
}

// ── New recovery code (Security › Make a new recovery code) ────────────────

class VaultNewCodeScreen extends ConsumerStatefulWidget {
  const VaultNewCodeScreen({super.key});

  @override
  ConsumerState<VaultNewCodeScreen> createState() => _VaultNewCodeScreenState();
}

class _VaultNewCodeScreenState extends ConsumerState<VaultNewCodeScreen> {
  late final String _code = newRecoveryCode();
  bool _saved = false, _busy = false;

  Future<void> _done() async {
    setState(() => _busy = true);
    await ref.read(vaultServiceProvider).replaceRecoveryCode(_code);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => _VaultFrame(
        step: '',
        title: 'New recovery code',
        bottom: VaultButton(label: _busy ? 'Saving…' : (_saved ? 'Use this code' : 'Tick the box first'), busy: _busy, onPressed: _saved ? _done : null),
        children: [
          _p(context, 'When you tap “Use this code”, your old code stops working. Leave this screen now to keep the old one.'),
          RecoveryCodeView(code: _code),
          _codeAdvice(context),
          SavedCheck(value: _saved, onChanged: _busy ? (_) {} : (v) => setState(() => _saved = v), label: 'I’ve saved my new code'),
        ],
      );
}
