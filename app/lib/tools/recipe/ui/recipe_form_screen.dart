import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/settings_repo.dart';
import '../../../core/domain/validation.dart';
import '../../../core/platform/external_activity.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/components/prompt_name.dart';
import '../../../core/ui/components/states.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/oz_icons.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/amounts.dart';
import '../domain/ingredient_words.dart';
import '../domain/recipe.dart';
import '../state/recipe_providers.dart';
import 'recipe_parts.dart';

/// Opens the phone's camera app or the system photo picker (decision R-6: no
/// camera or storage permission) and returns the picture's path, or null.
Future<String?> pickPicture(ImageSource source) async {
  final x = await ExternalActivity.run(() => ImagePicker().pickImage(source: source, requestFullMetadata: false));
  return x?.path;
}

/// The picture picker; tests replace it.
final picturePickerProvider = Provider<Future<String?> Function(ImageSource)>((ref) => pickPicture);

/// Categories hidden in Settings › Lists, lower case (they stay on recipes that use them).
final _hiddenCategoriesProvider = StreamProvider<Set<String>>((ref) => ref
    .watch(settingsRepoProvider)
    .watch(SettingKeys.listsHidden)
    .map((m) => {for (final v in m['category'] ?? const <String>[]) v.toLowerCase()}));

/// One line of the Ingredients editor: an ingredient, or a section heading.
class _Line {
  _Line.ingredient({String amount = '', String name = ''})
      : section = false,
        amount = TextEditingController(text: amount),
        name = TextEditingController(text: name);
  _Line.heading(String text)
      : section = true,
        amount = TextEditingController(),
        name = TextEditingController(text: text);

  final bool section;
  final TextEditingController amount;

  /// The ingredient's name, or the heading's text.
  final TextEditingController name;

  /// Set when the person edited "Matches as"; otherwise it follows the name.
  String? keyName;
  final Key key = UniqueKey();
  final FocusNode amountFocus = FocusNode();

  String get matchesAs => keyName ?? keyNameFor(name.text);

  void dispose() {
    amount.dispose();
    name.dispose();
    amountFocus.dispose();
  }
}

class _StepLine {
  _StepLine([String text = '']) : body = TextEditingController(text: text);
  final TextEditingController body;
  final Key key = UniqueKey();
}

/// New / Edit recipe (board R5): full screen, since it has more than 6 fields.
class RecipeFormScreen extends ConsumerStatefulWidget {
  const RecipeFormScreen({super.key, this.recipeId});
  final String? recipeId;

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _title = TextEditingController();
  final _servings = TextEditingController();
  final _prep = TextEditingController();
  final _cook = TextEditingController();
  final _source = TextEditingController();
  final _notes = TextEditingController();
  String? _category;
  final List<String> _newCategories = [];
  String? _photo;
  bool _favourite = false;
  final List<_Line> _lines = [];
  final List<_StepLine> _steps = [];
  final Map<Object, String?> _err = {};
  String _initial = '';
  bool _saving = false;
  bool _picking = false;
  bool _editing = false;

  /// The Amount field that has focus, for the ½ ⅓ ¼ ¾ row.
  _Line? _amountInFocus;

  @override
  void initState() {
    super.initState();
    final id = widget.recipeId;
    final e = id == null ? null : ref.read(recipesDataProvider).value?.byId(id);
    _editing = e != null;
    if (e != null) {
      final r = e.row;
      _title.text = r.title;
      _servings.text = r.servings?.toString() ?? '';
      _prep.text = r.prepMin?.toString() ?? '';
      _cook.text = r.cookMin?.toString() ?? '';
      _source.text = r.source ?? '';
      _notes.text = r.notes ?? '';
      _category = r.category;
      _photo = r.photoFile;
      _favourite = r.isFavourite;
      String? section;
      for (final i in e.ingredients) {
        if (i.section != section) {
          section = i.section;
          if (section != null) _addLine(_Line.heading(section));
        }
        final line = _Line.ingredient(amount: amountFieldText(RecipeFullAmount.of(i.amountMilli, i.amountMaxMilli), i.unit), name: i.name);
        if (i.keyName != keyNameFor(i.name)) line.keyName = i.keyName;
        _addLine(line);
      }
      for (final s in e.steps) {
        _steps.add(_StepLine(s.body));
      }
    }
    if (_lines.isEmpty) _addLine(_Line.ingredient());
    if (_steps.isEmpty) _steps.add(_StepLine());
    _initial = _snapshot();
  }

  void _addLine(_Line l) {
    l.amountFocus.addListener(() {
      if (!mounted) return;
      setState(() => _amountInFocus = l.amountFocus.hasFocus ? l : (_amountInFocus == l ? null : _amountInFocus));
    });
    _lines.add(l);
  }

  @override
  void dispose() {
    for (final c in [_title, _servings, _prep, _cook, _source, _notes]) {
      c.dispose();
    }
    for (final l in _lines) {
      l.dispose();
    }
    for (final s in _steps) {
      s.body.dispose();
    }
    super.dispose();
  }

  String _snapshot() => [
        _title.text, _servings.text, _prep.text, _cook.text, _source.text, _notes.text, _category, _photo, //
        for (final l in _lines) '${l.section}|${l.amount.text}|${l.name.text}|${l.keyName}',
        for (final s in _steps) s.body.text,
      ].join('\u0001');

  Future<void> _pickPhoto() async {
    final c = OzoneThemeColors.of(context);
    final source = await showModalBottomSheet<Object>(
      context: context,
      useRootNavigator: true,
      backgroundColor: c.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            minTileHeight: 56,
            leading: Icon(OzIcons.photoCamera, color: recipeAccent(context)),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            minTileHeight: 56,
            leading: Icon(OzIcons.image, color: recipeAccent(context)),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          if (_photo != null)
            ListTile(
              minTileHeight: 56,
              leading: Icon(OzIcons.delete, color: c.danger),
              title: Text('Remove photo', style: TextStyle(color: c.danger)),
              onTap: () => Navigator.of(context).pop(false),
            ),
          const SizedBox(height: Space.s),
        ]),
      ),
    );
    if (!mounted || source == null) return;
    if (source == false) return setState(() => _photo = null);
    setState(() => _picking = true);
    String? picked;
    try {
      picked = await ref.read(picturePickerProvider)(source as ImageSource);
      if (picked != null) {
        final name = await ref.read(photoStoreProvider).adopt(picked);
        if (mounted) setState(() => _photo = name);
      }
    } on Object catch (e, st) {
      unawaited(ref.read(errorLogProvider).record(e, st, where: 'recipe photo'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn’t use that picture. Try another one.')));
      }
    } finally {
      // The picker's copy in the cache isn't needed once the photo is in the store.
      if (picked != null) {
        try {
          File(picked).deleteSync();
        } on FileSystemException {
          // Already gone.
        }
      }
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _newCategory() async {
    final name = await promptName(
      context,
      title: 'New category',
      label: 'Category',
      action: 'Add',
      accent: recipeAccent(context),
      parse: (s) => switch (requiredText(s, RecipeLimits.category, 'Enter a name')) {
        Ok(:final value) => Ok(value),
        Invalid(:final reason) => Invalid(reason),
      },
    );
    if (name == null || !mounted) return;
    setState(() {
      final known = [...?ref.read(recipesDataProvider).value?.categories, ..._newCategories];
      final same = known.where((k) => k.toLowerCase() == name.toLowerCase()).firstOrNull;
      if (same == null) _newCategories.add(name);
      _category = same ?? name;
    });
  }

  Future<void> _editKey(_Line l) async {
    final key = await promptName(
      context,
      title: 'Matches as',
      label: 'Ingredient for What can I cook?',
      action: 'Save',
      initial: l.matchesAs,
      hint: 'garlic',
      accent: recipeAccent(context),
      parse: (s) => switch (requiredText(s.toLowerCase(), RecipeLimits.keyName, 'Enter the ingredient')) {
        Ok(:final value) => Ok(value),
        Invalid(:final reason) => Invalid(reason),
      },
    );
    if (key == null || !mounted) return;
    setState(() => l.keyName = key == keyNameFor(l.name.text) ? null : key);
  }

  void _insertFraction(String f) {
    final l = _amountInFocus;
    if (l == null) return;
    final v = l.amount.value;
    final start = v.selection.isValid ? v.selection.start : v.text.length;
    final end = v.selection.isValid ? v.selection.end : v.text.length;
    final t = v.text.replaceRange(start, end, f);
    l.amount.value = TextEditingValue(text: t, selection: TextSelection.collapsed(offset: start + f.length));
    setState(() {});
  }

  Future<void> _save() async {
    final title = requiredText(_title.text, RecipeLimits.title, 'Give the recipe a title');
    final servings = parseServings(_servings.text);
    final prep = parseMinutes(_prep.text);
    final cook = parseMinutes(_cook.text);
    final source = optionalText(_source.text, RecipeLimits.source);
    final notes = optionalText(_notes.text, RecipeLimits.notes);
    String? m<T>(Validation<T> v) => v is Invalid<T> ? v.reason : null;
    final err = <Object, String?>{
      'title': m(title),
      'servings': m(servings),
      'prep': m(prep),
      'cook': m(cook),
      'source': m(source),
      'notes': m(notes),
    };

    final ingredients = <IngredientInput>[];
    String? section;
    for (final l in _lines) {
      if (l.section) {
        final s = optionalText(l.name.text, RecipeLimits.section);
        err[l.key] = m(s);
        section = s.valueOrNull;
        continue;
      }
      if (l.amount.text.trim().isEmpty && l.name.text.trim().isEmpty) continue;
      final amount = parseAmountField(l.amount.text);
      final name = requiredText(l.name.text, RecipeLimits.name, 'Name the ingredient');
      err[l.amount] = m(amount);
      err[l.key] = m(name);
      if (amount is Ok<(Amount?, String?)> && name is Ok<String>) {
        ingredients.add(IngredientInput(section: section, amount: amount.value.$1, unit: amount.value.$2, name: name.value, keyName: l.matchesAs));
      }
    }
    if (ingredients.isEmpty && !_lines.any((l) => !l.section && err[l.key] != null)) err['ingredients'] = 'Add at least one ingredient';
    if (ingredients.length > RecipeLimits.maxIngredients) err['ingredients'] = 'A recipe can have up to 100 ingredients';
    final steps = <String>[];
    for (final s in _steps) {
      final v = optionalText(s.body.text, RecipeLimits.step);
      err[s.key] = m(v);
      if (v.valueOrNull != null) steps.add(v.valueOrNull!);
    }
    if (steps.length > RecipeLimits.maxSteps) err['steps'] = 'A recipe can have up to 60 steps';
    setState(() => _err
      ..clear()
      ..addAll(err));
    if (_err.values.any((x) => x != null)) {
      // Floats above the Save bar, so Save stays reachable.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Check the fields marked in red'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, 96),
      ));
      return;
    }
    setState(() => _saving = true);
    final input = RecipeInput(
      title: title.valueOrNull!,
      category: _category,
      servings: servings.valueOrNull,
      prepMin: prep.valueOrNull,
      cookMin: cook.valueOrNull,
      source: source.valueOrNull,
      notes: notes.valueOrNull,
      isFavourite: _favourite,
      photoFile: _photo,
      ingredients: ingredients,
      steps: steps,
    );
    final repo = ref.read(recipesRepoProvider);
    String? newId;
    final ok = await guardSave(context, ref.read(errorLogProvider), what: 'save recipe', () async {
      if (_editing) {
        await repo.edit(widget.recipeId!, input);
      } else {
        newId = await repo.add(input);
      }
    });
    if (!mounted) return;
    if (!ok) return setState(() => _saving = false);
    if (newId != null) {
      // A new recipe opens, as on board R5 → R2.
      context.pushReplacement('/recipe/$newId');
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final label = text.bodyMedium!.copyWith(fontWeight: FontWeight.w700);
    void edited(Object key) => setState(() {
          _err.remove(key);
          _err.remove('ingredients');
        });
    Widget gap() => const SizedBox(height: 16);
    final hidden = ref.watch(_hiddenCategoriesProvider).value ?? const <String>{};
    final categories = [
      for (final k in ref.watch(recipesDataProvider).value?.categories ?? const <String>[]) if (!hidden.contains(k.toLowerCase())) k,
      ..._newCategories,
    ];
    if (_category != null && !categories.contains(_category)) categories.add(_category!);
    Widget error(Object key) => _err[key] == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Text(_err[key]!, style: text.bodyMedium!.copyWith(color: c.danger, fontWeight: FontWeight.w700)),
          );

    return DiscardGuard(
      dirty: _snapshot() != _initial && !_saving,
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.s, Space.s),
              child: Row(children: [
                IconButton(
                  tooltip: 'Close without saving',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(OzIcons.close, color: c.ink),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                const SizedBox(width: Space.xs),
                Expanded(child: Semantics(header: true, child: Text(_editing ? 'Edit recipe' : 'New recipe', style: text.titleLarge))),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, Space.xl),
                children: [
                  Text.rich(TextSpan(text: 'Photo', children: [TextSpan(text: ' · optional', style: TextStyle(fontWeight: FontWeight.w600, color: c.inkMuted))]), style: label),
                  const SizedBox(height: Space.s),
                  Semantics(
                    button: true,
                    label: _photo == null ? 'Add photo' : 'Recipe photo. Change or remove',
                    onTap: _picking ? null : _pickPhoto,
                    excludeSemantics: true,
                    child: Material(
                      color: recipeTile(context),
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _picking ? null : _pickPhoto,
                        child: SizedBox(
                          height: 180,
                          child: Stack(fit: StackFit.expand, children: [
                            RecipePhoto(file: _photo, height: 180, width: double.infinity, iconSize: 44, label: _photo == null ? 'Add photo' : null),
                            if (_picking) const Center(child: CircularProgressIndicator()),
                            if (_photo != null)
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
                                  child: Text('Change', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  gap(),
                  OzoneTextField(label: 'Title *', controller: _title, error: _err['title'], autofocus: !_editing, onChanged: (_) => edited('title'), fieldKey: const ValueKey('recipe-title')),
                  gap(),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: OzoneTextField(label: 'Servings', controller: _servings, error: _err['servings'], keyboardType: TextInputType.number, onChanged: (_) => edited('servings'), fieldKey: const ValueKey('recipe-servings'))),
                    const SizedBox(width: Space.s),
                    Expanded(child: OzoneTextField(label: 'Prep (min)', controller: _prep, error: _err['prep'], keyboardType: TextInputType.number, onChanged: (_) => edited('prep'), fieldKey: const ValueKey('recipe-prep'))),
                    const SizedBox(width: Space.s),
                    Expanded(child: OzoneTextField(label: 'Cook (min)', controller: _cook, error: _err['cook'], keyboardType: TextInputType.number, onChanged: (_) => edited('cook'), fieldKey: const ValueKey('recipe-cook'))),
                  ]),
                  gap(),
                  Text('Category', style: label),
                  const SizedBox(height: Space.s),
                  Wrap(spacing: Space.s, runSpacing: Space.s, children: [
                    RecipeChoice<String?>(
                      label: 'Category',
                      options: [(null, 'None'), for (final k in categories) (k, k)],
                      selected: _category,
                      onSelected: (v) => setState(() => _category = v),
                    ),
                    Semantics(
                      button: true,
                      label: 'New category',
                      onTap: _newCategory,
                      excludeSemantics: true,
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: _newCategory,
                        child: CustomPaint(
                          painter: DashedRRectPainter(color: c.inkMuted, radius: 24),
                          child: SizedBox(
                            height: 48,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Center(widthFactor: 1, child: Text('+ New', style: text.bodyMedium!.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800))),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  gap(),
                  Text('Ingredients', style: label),
                  const SizedBox(height: Space.s),
                  Container(
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: _lines.length,
                      onReorderItem: (from, to) => setState(() => _lines.insert(to, _lines.removeAt(from))),
                      itemBuilder: (context, i) => _lineRow(context, i, error),
                    ),
                  ),
                  error('ingredients'),
                  const SizedBox(height: Space.s),
                  Row(children: [
                    Expanded(child: OzoneButton(label: '+ Ingredient', primary: false, height: 48, onPressed: () => setState(() => _addLine(_Line.ingredient())))),
                    const SizedBox(width: Space.s),
                    Expanded(child: OzoneButton(label: '+ Section heading', primary: false, height: 48, onPressed: () => setState(() => _addLine(_Line.heading(''))))),
                  ]),
                  gap(),
                  Text('Steps', style: label),
                  const SizedBox(height: Space.s),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: _steps.length,
                    onReorderItem: (from, to) => setState(() => _steps.insert(to, _steps.removeAt(from))),
                    itemBuilder: (context, i) => _stepRow(context, i, error),
                  ),
                  error('steps'),
                  const SizedBox(height: Space.s),
                  OzoneButton(label: '+ Step', primary: false, height: 48, onPressed: () => setState(() => _steps.add(_StepLine()))),
                  gap(),
                  OzoneTextField(label: 'Source (optional)', controller: _source, error: _err['source'], hint: 'Cookbook, website or person', onChanged: (_) => edited('source')),
                  gap(),
                  OzoneTextField(label: 'Notes (optional)', controller: _notes, error: _err['notes'], maxLines: 3, onChanged: (_) => edited('notes')),
                ],
              ),
            ),
            if (_amountInFocus != null)
              Container(
                color: c.surface,
                padding: const EdgeInsets.symmetric(horizontal: Space.screen, vertical: Space.xs),
                child: Row(children: [
                  for (final f in const ['½', '⅓', '¼', '¾', '⅔'])
                    Padding(
                      padding: const EdgeInsets.only(right: Space.s),
                      child: TextButton(
                        onPressed: () => _insertFraction(f),
                        style: TextButton.styleFrom(minimumSize: const Size(48, 44), backgroundColor: c.surfaceSunken, shape: const StadiumBorder()),
                        child: Text(f, semanticsLabel: 'Insert $f', style: text.titleMedium!.copyWith(color: c.ink)),
                      ),
                    ),
                ]),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(Space.screen, Space.m, Space.screen, Space.xl),
              decoration: BoxDecoration(color: c.canvas, border: Border(top: BorderSide(color: c.outline.withValues(alpha: 0.6)))),
              child: OzoneButton(label: 'Save recipe', onPressed: _saving || _picking ? null : _save, color: recipeAccent(context), foreground: c.onAccent),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _lineRow(BuildContext context, int i, Widget Function(Object) error) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final l = _lines[i];
    final handle = ReorderableDragStartListener(
      index: i,
      child: Semantics(
        label: 'Drag to reorder',
        child: SizedBox(width: 32, height: 48, child: Icon(OzIcons.dragIndicator, color: c.inkMuted)),
      ),
    );
    final remove = IconButton(
      tooltip: l.section ? 'Remove heading' : 'Remove ingredient',
      onPressed: () => setState(() {
        _lines.removeAt(i);
        l.dispose();
        if (_amountInFocus == l) _amountInFocus = null;
      }),
      icon: Icon(OzIcons.close, size: 20, color: c.inkMuted),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
    InputDecoration field(String hint, {String? error}) => InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: c.surfaceSunken,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          errorText: error,
          errorMaxLines: 3,
        );
    return Container(
      key: l.key,
      padding: const EdgeInsets.fromLTRB(2, 6, 0, 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.surfaceSunken))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        handle,
        if (l.section)
          Expanded(
            child: TextField(
              controller: l.name,
              onChanged: (_) => setState(() {}),
              style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
              decoration: field('Section heading, e.g. For the sauce', error: _err[l.key]),
            ),
          )
        else ...[
          SizedBox(
            width: 96,
            child: TextField(
              controller: l.amount,
              focusNode: l.amountFocus,
              onChanged: (_) => setState(() {
                _err.remove(l.amount);
                _err.remove('ingredients');
              }),
              style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
              decoration: field('Amount', error: _err[l.amount]),
            ),
          ),
          const SizedBox(width: Space.s),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: l.name,
                onChanged: (_) => setState(() {
                  _err.remove(l.key);
                  _err.remove('ingredients');
                }),
                textCapitalization: TextCapitalization.sentences,
                style: text.bodyLarge,
                decoration: field('Ingredient', error: _err[l.key]),
              ),
              if (l.name.text.trim().isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => _editKey(l),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1,
                          child: Text('Matches as: ${l.matchesAs}',
                              semanticsLabel: 'Matches as ${l.matchesAs}. Tap to change',
                              style: text.labelLarge!.copyWith(fontWeight: FontWeight.w700, color: recipeAccent(context))),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ],
        remove,
      ]),
    );
  }

  Widget _stepRow(BuildContext context, int i, Widget Function(Object) error) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final s = _steps[i];
    return Padding(
      key: s.key,
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ReorderableDragStartListener(
          index: i,
          child: Semantics(
            label: 'Step ${i + 1}. Drag to reorder',
            child: Container(
              width: 32,
              height: 48,
              alignment: Alignment.center,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: recipeTile(context), shape: BoxShape.circle),
                child: Text('${i + 1}', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: recipeAccent(context))),
              ),
            ),
          ),
        ),
        const SizedBox(width: Space.s),
        Expanded(
          child: TextField(
            controller: s.body,
            minLines: 2,
            maxLines: 6,
            onChanged: (_) => setState(() => _err.remove(s.key)),
            textCapitalization: TextCapitalization.sentences,
            style: text.bodyLarge!.copyWith(height: 1.45),
            decoration: InputDecoration(
              hintText: 'Describe step ${i + 1}',
              filled: true,
              fillColor: c.surfaceSunken,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              errorText: _err[s.key],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Remove step ${i + 1}',
          onPressed: _steps.length == 1
              ? null
              : () => setState(() {
                    _steps.removeAt(i).body.dispose();
                  }),
          icon: Icon(OzIcons.close, size: 20, color: c.inkMuted),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ]),
    );
  }
}

/// A stored amount for the form's Amount field.
abstract final class RecipeFullAmount {
  static Amount? of(int? milli, int? max) => milli == null ? null : Amount(milli, max);
}
