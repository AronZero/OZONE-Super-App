import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'core/data/settings_repo.dart';
import 'core/state/providers.dart';
import 'core/state/today.dart';
import 'core/ui/theme/app_theme.dart';
import 'core/ui/theme/tokens.dart';
import 'shell/ui/lock_gate/lock_gate.dart';
import 'tools/notes/state/notes_providers.dart';

/// Root widget: theme from Settings › Appearance, the App lock gate above
/// everything, the Undo message, and an edge-to-edge status bar.
class OzoneApp extends ConsumerStatefulWidget {
  const OzoneApp({super.key});

  @override
  ConsumerState<OzoneApp> createState() => _OzoneAppState();
}

class _OzoneAppState extends ConsumerState<OzoneApp> with WidgetsBindingObserver {
  late final GoRouter _router = buildRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Notes trashed over 30 days ago are deleted on start and on resume (F2-02 §5).
    ref.read(notesRepoProvider).purge();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pending Undo deletes are committed when OZONE goes to the background (F2-02 §6).
    if (state == AppLifecycleState.paused) ref.read(undoControllerProvider).flush();
    if (state == AppLifecycleState.resumed) {
      ref.read(todayProvider.notifier).refresh();
      ref.read(notesRepoProvider).purge();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeChoiceProvider).value ?? ThemeChoice.system;
    final lock = ref.watch(appLockServiceProvider);
    final undo = ref.watch(undoControllerProvider);

    return MaterialApp.router(
      title: 'OZONE',
      debugShowCheckedModeBanner: false,
      theme: buildOzoneTheme(Brightness.light),
      darkTheme: buildOzoneTheme(Brightness.dark),
      themeMode: switch (theme) {
        ThemeChoice.system => ThemeMode.system,
        ThemeChoice.light => ThemeMode.light,
        ThemeChoice.dark => ThemeMode.dark,
      },
      routerConfig: _router,
      // The note editor's few built-in labels (flutter_quill).
      localizationsDelegates: const [FlutterQuillLocalizations.delegate],
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              ListenableBuilder(
                listenable: undo,
                builder: (context, _) => undo.pending == null ? const SizedBox.shrink() : _UndoBar(message: undo.pending!.message, onUndo: undo.undo),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: lock.locked,
                builder: (context, locked, _) => locked ? LockGate(service: lock) : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Expense deleted · Undo" (W3 States board).
class _UndoBar extends StatelessWidget {
  const _UndoBar({required this.message, required this.onUndo});

  final String message;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      left: Space.l,
      right: Space.l,
      bottom: 92,
      child: SafeArea(
        top: false,
        child: Semantics(
          liveRegion: true,
          child: Material(
            color: c.ink,
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 8, 6),
              child: Row(children: [
                Expanded(
                  child: Text(message,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: c.canvas, fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: onUndo,
                  style: TextButton.styleFrom(foregroundColor: dark ? ToolTint.finance.accentLight : ToolTint.finance.accentDark, minimumSize: const Size(64, 48)),
                  child: const Text('Undo', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
