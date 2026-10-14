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
}

List<RouteBase> _noRoutes(GlobalKey<NavigatorState> root) => const [];
List<AttentionItem> _noAttention(WidgetRef ref) => const [];

/// All tools, in default bar order. Adding a tool = one line here.
const List<ToolDefinition> toolRegistry = [financeTool, libraryTool, notesTool];

/// Default bar: Home · up to 3 tools · Tools (docs/03).
const List<String> defaultBarTools = ['finance', 'library', 'notes'];
