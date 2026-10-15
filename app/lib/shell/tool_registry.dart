import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/ui/theme/tokens.dart';
import '../tools/finance/finance_tool.dart';
import '../tools/library/library_tool.dart';
import '../tools/notes/notes_tool.dart';

/// One "Needs attention" line on Home and the screen that fixes it.
class AttentionItem {
  const AttentionItem(this.message, this.route);
  final String message;
  final String route;
}

/// What a search row shows besides the title: a second line, a value on the
/// right (an amount, already hidden when "Hide amounts" is on), and whether
/// it's struck through (refunded).
class SearchRowInfo {
  const SearchRowInfo(this.subtitle, {this.trailing, this.struck = false});
  final String subtitle;
  final String? trailing;
  final bool struck;
}

/// One kind of record a tool puts in the search index (F2-02 §1).
class SearchSource {
  const SearchSource({required this.entity, required this.group, required this.chip, required this.open, required this.describe});

  /// `search_index.entity`.
  final String entity;

  /// Group heading: "Gold items".
  final String group;

  /// Scope chip: "Gold".
  final String chip;

  /// Opens the exact record above the search screen (Back returns to the results).
  final void Function(BuildContext context, WidgetRef ref, String id) open;

  /// Row details from the tool's own data; null while it loads.
  final SearchRowInfo? Function(BuildContext context, WidgetRef ref, String id) describe;
}

/// One entry of Home's quick-add menu (Components board).
class QuickAddAction {
  const QuickAddAction({required this.label, required this.icon, required this.run});
  final String label;
  final IconData icon;
  final void Function(BuildContext context) run;
}

/// Everything the shell needs to know about one tool (docs/spec/F3-01 §3).
/// Search sources, workbook sheets and settings are added as each tool is built.
class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.name,
    required this.tint,
    required this.icon,
    required this.routeBase,
    required this.home,
    this.routes = _noRoutes,
    this.widgets = const {},
    this.attention = _noAttention,
    this.searchSources = const [],
    this.quickAdd = const [],
  });

  /// Stable ID stored in settings (`bar.tools`). Never rename.
  final String id;
  final String name;
  final ToolTint tint;
  final IconData icon;
  final String routeBase;
  final WidgetBuilder home;

  /// Screens below [routeBase]. Routes that hide the bar use [root] as their
  /// `parentNavigatorKey` (docs/04: the bar is hidden in detail screens and forms).
  final List<RouteBase> Function(GlobalKey<NavigatorState> root) routes;

  /// Home dashboard widgets this tool owns, by widget ID (docs/04 W1–W10).
  final Map<String, WidgetBuilder> widgets;

  /// Lines for Home's "Needs attention" widget.
  final List<AttentionItem> Function(WidgetRef ref) attention;

  /// Records this tool puts in global search, in display order.
  final List<SearchSource> searchSources;

  /// Entries for Home's quick-add menu.
  final List<QuickAddAction> quickAdd;
}

List<RouteBase> _noRoutes(GlobalKey<NavigatorState> root) => const [];
List<AttentionItem> _noAttention(WidgetRef ref) => const [];

/// All tools, in default bar order. Adding a tool = one line here.
const List<ToolDefinition> toolRegistry = [financeTool, libraryTool, notesTool];

/// Default bar: Home · up to 3 tools · Tools (docs/03).
const List<String> defaultBarTools = ['finance', 'library', 'notes'];

/// Tools in bar order, then the rest (search groups and quick add follow it, F2-02 §1).
List<ToolDefinition> toolsInBarOrder(List<String> bar) => [
      for (final id in bar) ...toolRegistry.where((t) => t.id == id),
      ...toolRegistry.where((t) => !bar.contains(t.id)),
    ];
