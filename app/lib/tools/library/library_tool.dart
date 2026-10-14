import 'package:flutter/material.dart';

import '../../core/ui/theme/tokens.dart';
import '../../shell/tool_registry.dart';
import '../../shell/ui/placeholder_screen.dart';

/// Library tool definition. Screens arrive in milestone M4 (docs/spec/F3-04).
const ToolDefinition libraryTool = ToolDefinition(
  id: 'library',
  name: 'Library',
  tint: ToolTint.library,
  icon: Icons.menu_book_rounded,
  routeBase: '/library',
  home: _home,
);

Widget _home(BuildContext context) => const PlaceholderScreen(
      title: 'Library',
      message: 'Your books arrive in milestone M4.',
      tint: ToolTint.library,
      icon: Icons.menu_book_rounded,
    );
