import 'package:flutter/material.dart';

import '../../../core/security/app_lock_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../ozone_mark.dart';
import '../splash/splash_overlay.dart';
import '../../../core/ui/theme/oz_icons.dart';

/// App lock gate (W3 · App lock gate). Covers everything until the phone's own
/// screen lock succeeds; nothing behind it is drawn.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.service});

  final AppLockService service;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  String? _message;

  @override
  void initState() {
    super.initState();
    // Ask straight away, so unlocking is one step; after the splash, so the prompt never covers it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (splashActive.value) {
        splashActive.addListener(_afterSplash);
      } else {
        _unlock();
      }
    });
  }

  void _afterSplash() {
    if (splashActive.value) return;
    splashActive.removeListener(_afterSplash);
    if (mounted) _unlock();
  }

  @override
  void dispose() {
    splashActive.removeListener(_afterSplash);
    super.dispose();
  }

  Future<void> _unlock() async {
    final r = await widget.service.unlock();
    if (!mounted) return;
    setState(() {
      _message = switch (r) {
        AuthOutcome.success || AuthOutcome.cancelled => null,
        AuthOutcome.noScreenLock => 'This phone no longer has a screen lock. Set one in your phone’s settings to unlock OZONE.',
        AuthOutcome.failed => 'Couldn’t unlock. Try again.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      color: c.canvas,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const OzoneMark(size: 96),
                    const SizedBox(height: Space.xl),
                    Semantics(header: true, child: Text('OZONE is locked', style: text.headlineSmall)),
                    const SizedBox(height: Space.s),
                    Text('Unlock the same way you unlock your phone.',
                        textAlign: TextAlign.center, style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                    if (_message != null) ...[
                      const SizedBox(height: Space.l),
                      Text(_message!, textAlign: TextAlign.center, style: text.bodyMedium!.copyWith(color: c.attentionInk)),
                    ],
                  ],
                ),
              ),
              OzoneButton(label: 'Unlock', icon: OzIcons.lockOpen, onPressed: _unlock),
              const SizedBox(height: Space.m),
              Text('Your phone asks for your fingerprint, face or phone password. OZONE never sees it.',
                  textAlign: TextAlign.center, style: text.bodyMedium!.copyWith(color: c.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
