import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/ingredient_words.dart';
import '../state/recipe_providers.dart';
import 'cook_screen.dart';
import 'recipe_parts.dart';

/// Most always-there ingredients kept (a sanity limit, not a design rule).
const int maxStaples = 30;

/// Settings › Recipes (F4-02 §1, owner M13 Q1/Q3): always-there ingredients
/// as chips with × and an Add field (stored as key names), and Clear my kitchen.
class RecipeSettingsScreen extends ConsumerStatefulWidget {
  const RecipeSettingsScreen({super.key});

  @override
  ConsumerState<RecipeSettingsScreen> createState() => _RecipeSettingsScreenState();
}

class _RecipeSettingsScreenState extends ConsumerState<RecipeSettingsScreen> {
  final _add = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  Future<void> _save(List<String> staples) => ref.read(settingsRepoProvider).set(SettingKeys.recipeStaples, staples);

  Future<void> _addStaple(List<String> staples) async {
    final raw = _add.text.trim();
    if (raw.isEmpty) return;
    final key = keyNameFor(raw);
    String? error;
    if (staples.contains(key)) {
      error = '“$key” is already in the list';
    } else if (staples.length >= maxStaples) {
      error = 'Keep it to $maxStaples ingredients or fewer';
    }
    setState(() => _error = error);
    if (error != null) return;
    _add.clear();
    await _save([...staples, key]);
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final staples = ref.watch(staplesProvider).value ?? const <String>[];
    final kitchen = ref.watch(kitchenProvider).value ?? const <String>{};

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: staggered([
            const DetailTopBar(title: 'Recipes', overline: 'Settings'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SectionLabel('Always-there ingredients'),
                GroupCard(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.l),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('What can I cook? counts these as in your kitchen for every recipe.',
                          style: text.bodyMedium!.copyWith(color: c.inkMuted)),
                      const SizedBox(height: Space.m),
                      if (staples.isEmpty)
                        Text('None. Every ingredient has to be ticked.', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700))
                      else
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          for (final s in staples) _StapleChip(label: s, onRemove: () => _save([...staples]..remove(s))),
                        ]),
                      const SizedBox(height: Space.m),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: TextField(
                            controller: _add,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.none,
                            maxLength: 80,
                            onSubmitted: (_) => _addStaple(staples),
                            onChanged: (_) {
                              if (_error != null) setState(() => _error = null);
                            },
                            style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
                            cursorColor: c.ink,
                            decoration: InputDecoration(
                              hintText: 'Add ingredient',
                              counterText: '',
                              errorText: _error,
                              filled: true,
                              fillColor: c.surfaceSunken,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.ink, width: 2)),
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.s),
                        // OzoneButton fills its width; keep it button-sized beside the field.
                        SizedBox(
                          width: 88,
                          child: OzoneButton(
                            label: 'Add',
                            height: 48,
                            color: recipeAccent(context),
                            foreground: c.onAccent,
                            onPressed: () => _addStaple(staples),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ]),
                const SectionLabel('Kitchen'),
                GroupCard(children: [
                  SettingsRow(
                    title: 'Clear my kitchen',
                    subtitle: kitchen.isEmpty
                        ? 'Nothing is ticked'
                        : '${kitchen.length} ${kitchen.length == 1 ? 'ingredient' : 'ingredients'} ticked on What can I cook?',
                    enabled: kitchen.isNotEmpty,
                    onTap: kitchen.isEmpty ? null : () => clearKitchen(ref),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// An always-there ingredient with × to remove it.
class _StapleChip extends StatelessWidget {
  const _StapleChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: 'Remove $label',
      onTap: onRemove,
      excludeSemantics: true,
      child: PressScale(
        scale: PressScale.button,
        child: Material(
          color: recipeTile(context),
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onRemove,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800, color: c.ink)),
                  ),
                  const SizedBox(width: 4),
                  Icon(OzIcons.close, size: 18, color: recipeAccent(context)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
