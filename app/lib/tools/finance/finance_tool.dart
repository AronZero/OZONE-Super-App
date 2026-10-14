import 'package:flutter/material.dart';

import '../../core/ui/theme/tokens.dart';
import '../../shell/tool_registry.dart';
import '../../shell/ui/placeholder_screen.dart';

/// Finance tool definition. Screens arrive in milestone M2–M3 (docs/spec/F3-04).
const ToolDefinition financeTool = ToolDefinition(
  id: 'finance',
  name: 'Finance',
  tint: ToolTint.finance,
  icon: Icons.account_balance_wallet_rounded,
  routeBase: '/finance',
  home: _home,
);

Widget _home(BuildContext context) => const PlaceholderScreen(
      title: 'Finance',
      message: 'Savings, Gold and Expenses arrive in the next milestones.',
      tint: ToolTint.finance,
      icon: Icons.account_balance_wallet_rounded,
    );
