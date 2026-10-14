import 'package:flutter/material.dart';

import '../placeholder_screen.dart';

/// Tools launcher (W3 · Tools launcher). Built fully in M1.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Tools',
        message: 'The tools launcher and Edit bar arrive in milestone M1.',
      );
}
