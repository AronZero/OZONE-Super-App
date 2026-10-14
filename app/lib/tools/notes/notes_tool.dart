import 'package:flutter/material.dart';

import '../../core/ui/theme/tokens.dart';
import '../../shell/tool_registry.dart';
import '../../shell/ui/placeholder_screen.dart';

/// Notes tool definition. Screens arrive in milestone M5–M6 (docs/spec/F3-04).
const ToolDefinition notesTool = ToolDefinition(
  id: 'notes',
  name: 'Notes',
  tint: ToolTint.notes,
  icon: Icons.description_rounded,
  routeBase: '/notes',
  home: _home,
);

Widget _home(BuildContext context) => const PlaceholderScreen(
      title: 'Notes',
      message: 'Notes and the vault arrive in milestones M5 and M6.',
      tint: ToolTint.notes,
      icon: Icons.description_rounded,
    );
