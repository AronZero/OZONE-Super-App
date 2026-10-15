import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/vault_service.dart';
import '../../../../core/state/providers.dart';
import '../../../../core/ui/components/forms.dart';
import '../../../../core/ui/theme/app_theme.dart';
import '../../../../core/ui/theme/tokens.dart';
import '../notes_parts.dart';
import 'vault_parts.dart';

/// Makes sure the vault is open: sets it up the first time (F2-01 §4: "the
/// first time a note is locked"), otherwise asks to unlock. True when open.
Future<bool> ensureVaultOpen(BuildContext context, WidgetRef ref, {bool forLocking = false}) async {
  final vault = ref.read(vaultServiceProvider);
  if (vault.isOpen.value) return true;
  if (!await vault.exists()) {
    if (!context.mounted) return false;
    return await context.push<bool>('/notes/vault/setup${forLocking ? '?lock=1' : ''}') ?? false;
  }
  if (!context.mounted) return false;
  return await showVaultUnlock(context) ?? false;
}

/// W1 · Vault unlock: fingerprint (when on), or the vault password.
Future<bool?> showVaultUnlock(BuildContext context) => showOzoneSheet<bool>(context, builder: (_) => const _UnlockSheet());

class _UnlockSheet extends ConsumerStatefulWidget {
  const _UnlockSheet();

  @override
  ConsumerState<_UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends ConsumerState<_UnlockSheet> {
  final _pw = TextEditingController();
  bool _busy = false;
  bool _fingerprint = false;
  String? _error;
  Duration? _wait;
  Timer? _tick;

  VaultService get _vault => ref.read(vaultServiceProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    final on = await _vault.biometricOn() && await _vault.biometricAvailable();
    final wait = await _vault.waitLeft();
    if (!mounted) return;
    setState(() => _fingerprint = on);
    _startWait(wait);
    // Offer the fingerprint straight away, as the board's main button does.
    if (on && wait == null) unawaited(_useFingerprint());
  }

  void _startWait(Duration? wait) {
    _tick?.cancel();
    setState(() => _wait = wait);
    if (wait == null) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) async {
      final left = await _vault.waitLeft();
      if (!mounted) return;
      setState(() => _wait = left);
      if (left == null) _tick?.cancel();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _useFingerprint() async {
    final r = await _vault.unlockWithFingerprint();
    if (!mounted) return;
    switch (r) {
      case Unlocked():
        Navigator.of(context).pop(true);
      case FingerprintChanged():
        setState(() {
          _fingerprint = false;
          _error = 'Your fingerprints changed on this phone. Unlock with your password, then turn fingerprint unlock on again in Settings › Security.';
        });
      default:
        break;
    }
  }

  Future<void> _usePassword() async {
    if (_pw.text.isEmpty) {
      setState(() => _error = 'Type your vault password');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await _vault.unlock(_pw.text);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case Unlocked():
        Navigator.of(context).pop(true);
      case WrongSecret(:final wait):
        setState(() => _error = 'That password isn’t right. Check it and try again.');
        if (wait != null) _startWait(wait);
      case MustWait(:final left):
        _startWait(left);
      default:
        break;
    }
  }

  static String _waitText(Duration d) {
    final s = d.inSeconds + 1;
    if (s < 60) return '$s s';
    final m = s ~/ 60, r = s % 60;
    return r == 0 ? '$m min' : '$m min $r s';
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final waiting = _wait != null;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.outline, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: Space.l),
          const Center(child: VaultIcon()),
          const SizedBox(height: 14),
          Semantics(header: true, child: Text('Unlock notes', textAlign: TextAlign.center, style: text.titleLarge!.copyWith(fontSize: 22, fontWeight: FontWeight.w800))),
          const SizedBox(height: 6),
          Text('Locked notes stay open until you leave OZONE.', textAlign: TextAlign.center, style: text.bodyMedium!.copyWith(fontSize: 14, color: c.inkMuted)),
          const SizedBox(height: Space.l),
          if (_fingerprint) ...[
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _useFingerprint,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Use fingerprint'),
                style: FilledButton.styleFrom(
                  backgroundColor: notesAccent(context),
                  foregroundColor: c.onAccent,
                  shape: const StadiumBorder(),
                  textStyle: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Divider(color: c.outline)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: Space.m), child: Text('or', style: text.labelLarge!.copyWith(color: c.inkMuted, fontWeight: FontWeight.w700))),
              Expanded(child: Divider(color: c.outline)),
            ]),
            const SizedBox(height: 14),
          ],
          PasswordField(
            label: 'Vault password',
            controller: _pw,
            error: _error,
            autofocus: !_fingerprint,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => waiting ? null : _usePassword(),
          ),
          if (waiting) ...[
            const SizedBox(height: Space.s),
            Semantics(
              liveRegion: true,
              child: Text('Too many wrong passwords. Try again in ${_waitText(_wait!)}.',
                  style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: c.attentionInk)),
            ),
          ],
          const SizedBox(height: Space.m),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _busy || waiting ? null : _usePassword,
              style: FilledButton.styleFrom(
                backgroundColor: _fingerprint ? c.surfaceSunken : notesAccent(context),
                foregroundColor: _fingerprint ? c.ink : c.onAccent,
                disabledBackgroundColor: c.surfaceSunken,
                shape: const StadiumBorder(),
                textStyle: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
              ),
              child: Text(_busy ? 'Unlocking…' : 'Unlock with password'),
            ),
          ),
          const SizedBox(height: Space.s),
          Wrap(alignment: WrapAlignment.center, children: [
            TextButton(
              onPressed: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop(false);
                unawaited(router.push('/notes/vault/forgot'));
              },
              style: TextButton.styleFrom(foregroundColor: c.ink, minimumSize: const Size(48, 44)),
              child: const Text('Forgot password?', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: c.ink, minimumSize: const Size(48, 44)),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
        ]),
      ),
    );
  }
}
