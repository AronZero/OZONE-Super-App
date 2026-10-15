import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/search/query_parser.dart';
import '../../../core/search/search_repo.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../tool_registry.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/theme/oz_icons.dart';

/// W2 · Global search (F2-02 §1, docs/04): scope chips, results grouped in bar
/// order with counts and the top 3, "See all", recent searches, and the fixed
/// "Locked notes aren't searched." footer. `/search?scope=book` preselects a scope.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.scope});

  /// An entity ID to search in, or null for All.
  final String? scope;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  int _generation = 0;
  String? _scope;
  List<SearchGroup>? _groups;

  @override
  void initState() {
    super.initState();
    _scope = widget.scope;
    _q.addListener(_changed);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<SearchSource> get _sources {
    final bar = ref.read(barToolsProvider).value ?? defaultBarTools;
    return [for (final t in toolsInBarOrder(bar)) ...t.searchSources];
  }

  SearchSource? _source(String entity) => _sources.where((s) => s.entity == entity).firstOrNull;

  /// 150 ms after typing stops (F2-02 §1).
  void _changed() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _run);
    setState(() {});
  }

  Future<void> _run() async {
    final gen = ++_generation;
    final text = _q.text;
    if (buildMatch(text) == null) {
      setState(() => _groups = null);
      return;
    }
    final order = [for (final s in _sources) s.entity];
    final scope = _scope;
    final groups = await ref.read(searchRepoProvider).search(
          text,
          entities: scope == null ? order : [scope],
          perGroup: scope == null ? 3 : 500,
        );
    if (mounted && gen == _generation) setState(() => _groups = groups);
  }

  void _pickScope(String? s) {
    setState(() => _scope = s);
    unawaited(_run());
  }

  void _openHit(SearchHit h) {
    unawaited(ref.read(searchRepoProvider).remember(_q.text));
    _focus.unfocus();
    _source(h.entity)?.open(context, ref, h.recordId);
  }

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final sources = _sources;
    final searching = buildMatch(_q.text) != null;
    final recent = ref.watch(_recentProvider).value ?? const [];

    Widget chip(String label, String? value) {
      final on = _scope == value;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Semantics(
          inMutuallyExclusiveGroup: true,
          checked: on,
          button: true,
          label: spokenAmounts('Search in $label'),
          excludeSemantics: true,
          child: Material(
            color: on ? c.ink : c.surfaceSunken,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _pickScope(value),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48, minWidth: PillSize.minWidth),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                alignment: Alignment.center,
                child: Text(label, style: text.bodyMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: on ? c.canvas : c.ink)),
              ),
            ),
          ),
        ),
      );
    }

    final body = <Widget>[];
    if (!searching) {
      if (recent.isNotEmpty) {
        body.add(Row(children: [
          Expanded(child: Semantics(header: true, child: Text('Recent searches', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)))),
          TextButton(
            onPressed: () => ref.read(searchRepoProvider).clearRecent(),
            style: TextButton.styleFrom(foregroundColor: c.ink, minimumSize: const Size(48, 48)),
            child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ]));
        body.add(_Card(children: [
          for (final r in recent)
            InkWell(
              onTap: () {
                _q.text = r;
                _q.selection = TextSelection.collapsed(offset: r.length);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(children: [
                    Icon(OzIcons.history, size: 20, color: c.inkMuted),
                    const SizedBox(width: Space.m),
                    Expanded(child: Text(r, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600))),
                  ]),
                ),
              ),
            ),
        ]));
      } else {
        body.add(Text('Type at least 2 letters or numbers. Amounts like 1,299 match exactly.', style: text.bodyLarge!.copyWith(color: c.inkMuted)));
      }
    } else if (_groups != null) {
      final groups = _groups!;
      final total = groups.fold<int>(0, (n, g) => n + g.count);
      body.add(Semantics(
        liveRegion: true,
        child: Text(total == 0 ? 'No results' : '$total ${total == 1 ? 'result' : 'results'}',
            style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.inkMuted)),
      ));
      if (groups.isEmpty) {
        final scoped = _scope == null ? null : _source(_scope!);
        body.add(Container(
          padding: const EdgeInsets.all(Space.xl),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(scoped == null ? 'No matches for “${_q.text.trim()}”' : 'No matches in ${scoped.chip}',
                style: text.bodyLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: Space.s),
            Text(scoped == null ? 'Check the spelling, or try fewer or shorter words.' : 'Try searching everywhere in OZONE.',
                style: text.bodyLarge!.copyWith(fontSize: 14, color: c.inkMuted)),
            if (scoped != null) ...[
              const SizedBox(height: Space.m),
              FilledButton(
                onPressed: () => _pickScope(null),
                style: FilledButton.styleFrom(backgroundColor: c.ink, foregroundColor: c.canvas, minimumSize: const Size(48, 48), shape: const StadiumBorder()),
                child: const Text('Search all', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ]),
        ));
      }
      for (final g in groups) {
        final s = _source(g.entity);
        if (s == null) continue;
        final tint = toolRegistry.firstWhere((t) => t.searchSources.contains(s)).tint.accentOf(context);
        body.add(Row(children: [
          const SizedBox(width: Space.xs),
          ExcludeSemantics(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: tint, shape: BoxShape.circle))),
          const SizedBox(width: Space.s),
          Expanded(child: Semantics(header: true, child: Text('${s.group} · ${g.count}', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)))),
          if (_scope == null && g.count > g.hits.length)
            TextButton(
              onPressed: () => _pickScope(g.entity),
              style: TextButton.styleFrom(foregroundColor: c.ink, minimumSize: const Size(48, 48)),
              child: Text('See all ${g.count}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
        ]));
        body.add(_Card(children: [for (final h in g.hits) _HitRow(hit: h, source: s, onTap: () => _openHit(h))]));
      }
    }
    body.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: Space.xs),
      child: Row(children: [
        Icon(OzIcons.lock, size: 16, color: c.inkMuted),
        const SizedBox(width: Space.s),
        Expanded(child: Text('Locked notes aren’t searched.', style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.inkMuted))),
      ]),
    ));

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s, Space.m, Space.m, Space.s),
            child: Row(children: [
              IconButton(
                tooltip: 'Close search',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(OzIcons.arrowBack, color: c.ink),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _q,
                  focusNode: _focus,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) => ref.read(searchRepoProvider).remember(v),
                  style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700),
                  cursorColor: c.ink,
                  decoration: InputDecoration(
                    hintText: 'Search OZONE',
                    filled: true,
                    fillColor: c.surfaceSunken,
                    prefixIcon: Icon(OzIcons.search, color: c.ink),
                    suffixIcon: _q.text.isEmpty
                        ? null
                        : IconButton(tooltip: 'Clear search', onPressed: _q.clear, icon: Icon(OzIcons.close, color: c.inkMuted)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: c.ink, width: 2)),
                  ),
                ),
              ),
            ]),
          ),
          Semantics(
            container: true,
            label: 'Search in',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.s),
              child: Row(children: [chip('All', null), for (final s in sources) chip(s.chip, s.entity)]),
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, Space.xxxl),
              children: [for (final w in body) Padding(padding: const EdgeInsets.only(bottom: Space.s), child: w)],
            ),
          ),
        ]),
      ),
    );
  }
}

final _recentProvider = StreamProvider.autoDispose<List<String>>((ref) => ref.watch(searchRepoProvider).watchRecent());

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: c.surfaceSunken.withValues(alpha: 0.7)),
          children[i],
        ],
      ]),
    );
  }
}

/// One result: highlighted title, a context line, and a value on the right.
class _HitRow extends ConsumerWidget {
  const _HitRow({required this.hit, required this.source, required this.onTap});
  final SearchHit hit;
  final SearchSource source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final info = source.describe(context, ref, hit.recordId);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mark = c.mono ? c.outline : (dark ? const Color(0xFF6B5A12) : const Color(0xFFFFE98A));

    TextSpan runs(String marked, TextStyle base) => TextSpan(children: [
          for (final (s, m) in highlightRuns(marked)) TextSpan(text: s, style: m ? base.copyWith(backgroundColor: mark, color: c.ink) : base),
        ]);

    final titleStyle = text.bodyLarge!.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      decoration: info?.struck == true ? TextDecoration.lineThrough : null,
    );
    final subStyle = text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.inkMuted);
    // Notes show the matching words of their text; other records their own details.
    final snippetHit = hit.entity == 'note' && hit.snippet.contains('\u0001');
    final plainTitle = hit.title.replaceAll(RegExp('[\u0001\u0002]'), '');

    return Semantics(
      button: true,
      label: spokenAmounts([plainTitle.isEmpty ? 'Untitled' : plainTitle, ?info?.subtitle, ?info?.trailing].join(', ')),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(plainTitle.isEmpty ? TextSpan(text: 'Untitled', style: titleStyle.copyWith(color: c.inkMuted)) : runs(hit.title, titleStyle),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  if (snippetHit)
                    Text.rich(runs(hit.snippet, subStyle), maxLines: 2, overflow: TextOverflow.ellipsis)
                  else if (info != null)
                    Text(info.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: subStyle),
                ]),
              ),
              if (info?.trailing != null) ...[
                const SizedBox(width: Space.m),
                Text(info!.trailing!,
                    style: text.bodyMedium!.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      decoration: info.struck ? TextDecoration.lineThrough : null,
                    )),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
