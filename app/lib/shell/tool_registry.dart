import 'package:flutter/material.dart';

import '../core/ui/theme/tokens.dart';
import '../tools/finance/finance_tool.dart';
import '../tools/library/library_tool.dart';
import '../tools/notes/notes_tool.dart';

/// Everything the shell needs to know about one tool (docs/spec/F3-01 §3).
/// M0 holds identity and the main screen; routes, widgets, search sources,
/// workbook sheets and settings are added as each tool is built.
class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.name,
    required this.tint,
    required this.icon,
    required this.routeBase,
    required this.home,
  });

  /// Stable ID stored in settings (`bar.tools`). Never rename.
  final String id;
  final String name;
  final ToolTint tint;
  final IconData icon;
  final String routeBase;
  final WidgetBuilder home;
}

/// All tools, in default bar order. Adding a tool = one line here.
const List<ToolDefinition> toolRegistry = [financeTool, libraryTool, notesTool];

/// Default bar: Home · up to 3 tools · Tools (docs/03).
const List<String> defaultBarTools = ['finance', 'library', 'notes'];
