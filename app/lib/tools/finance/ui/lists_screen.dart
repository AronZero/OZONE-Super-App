import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../data/lists_repo.dart';
import '../domain/savings_rules.dart';
import '../state/finance_providers.dart';
import 'savings_parts.dart';
import '../../../core/ui/motion.dart';

final _listProvider = StreamProvider.family<List<ListValue>, ListField>((ref, f) => ref.watch(listsRepoProvider).watch(f));

/// Settings › Lists (F1-01 §3): rename a value everywhere it's used, or hide
/// it from suggestions. Values come from your records; nothing is stored apart.
class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> {
  ListField _field = ListField.vendor;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final values = ref.watch(_listProvider(_field)).value;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: staggered([
            const DetailTopBar(title: 'Lists', overline: 'Settings'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentTabs(
                    labels: const ['Vendors', 'Platforms', 'Types'],
                    selected: ListField.values.indexOf(_field),
                    onSelected: (i) => setState(() => _field = ListField.values[i]),
                  ),
                  const SizedBox(height: Space.m),
                  Text(
                    'Suggestions come from what you’ve typed before. Rename a value to fix it everywhere, or hide it from suggestions.',
                    style: text.bodyLarge!.copyWith(fontSize: 14, height: 1.5, color: c.inkMuted),
                  ),
                  const SizedBox(height: Space.m),
                  if (values != null && values.isEmpty)
                    Text('No ${_field.title.toLowerCase()} yet.', style: text.bodyLarge)
                  else if (values != null)
                    GroupCard(
                      children: [
                        for (final v in values)
                          SettingsRow(
                            title: v.value,
                            subtitle: '${v.uses} ${v.uses == 1 ? 'record' : 'records'}${v.hidden ? ' · hidden from suggestions' : ''}',
                            titleColor: v.hidden ? c.inkMuted : null,
                            onTap: () => _edit(v),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _edit(ListValue v) async {
    final repo = ref.read(listsRepoProvider);
    final field = _field;
    final ctl = TextEditingController(text: v.value);
    String? err;
    var hidden = v.hidden;
    await showOzoneSheet<void>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInner) {
          final c = OzoneThemeColors.of(context);
          return SheetFrame(
            title: v.value,
            action: OzoneButton(
              label: 'Save',
              color: financeAccent(context),
              foreground: c.onAccent,
              onPressed: () async {
                final name = validateOptionalShort(ctl.text);
                final to = name.valueOrNull;
                if (to == null) {
                  setInner(() => err = 'Enter a name');
                  return;
                }
                final nav = Navigator.of(context);
                if (to != v.value) await repo.rename(field, v.value, to);
                if (hidden != v.hidden || to != v.value) {
                  if (v.hidden) await repo.setHidden(field, v.value, false);
                  if (hidden) await repo.setHidden(field, to, true);
                }
                nav.pop();
              },
            ),
            children: [
              OzoneTextField(label: 'Name', controller: ctl, error: err),
              Text(
                'Renaming changes all ${v.uses} ${v.uses == 1 ? 'record' : 'records'}. Using a name that already exists merges the two.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c.inkMuted),
              ),
              GroupCard(
                children: [
                  SettingsRow(
                    title: 'Hide from suggestions',
                    subtitle: 'Records keep it',
                    trailing: OzoneSwitch(
                      value: hidden,
                      label: 'Hide from suggestions',
                      accent: financeAccent(context),
                      onChanged: (x) => setInner(() => hidden = x),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    ctl.dispose();
  }
}
