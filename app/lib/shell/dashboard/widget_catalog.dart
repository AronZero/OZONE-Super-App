import '../../core/ui/theme/tokens.dart';

/// Names and owners of the preset dashboard widgets (docs/04, W1–W10).
/// Tools supply each widget's content through the tool registry (from M2);
/// this catalog keeps every widget's display name in one place.
class WidgetInfo {
  const WidgetInfo(this.name, this.detail, this.tint, this.milestone);
  final String name;
  final String detail;

  /// Null for the shell's own "Needs attention" widget.
  final ToolTint? tint;

  /// When its content arrives (docs/spec/F3-04).
  final String milestone;
}

const Map<String, WidgetInfo> widgetCatalog = {
  'needs_attention': WidgetInfo('Needs attention', 'Due balances, stale prices, backup', null, 'M2'),
  'total_savings': WidgetInfo('Total savings', 'Finance', ToolTint.finance, 'M2'),
  'savings_trend': WidgetInfo('Savings trend', 'Finance · 12 months', ToolTint.finance, 'M2'),
  'gold_holdings': WidgetInfo('Gold holdings', 'Finance', ToolTint.finance, 'M3'),
  'spending_this_year': WidgetInfo('Spending this year', 'Finance', ToolTint.finance, 'M3'),
  'recent_expenses': WidgetInfo('Recent expenses', 'Finance', ToolTint.finance, 'M3'),
  'currently_reading': WidgetInfo('Currently reading', 'Library', ToolTint.library, 'M4'),
  'library_snapshot': WidgetInfo('Library snapshot', 'Library', ToolTint.library, 'M4'),
  'pinned_notes': WidgetInfo('Pinned notes', 'Notes · locked ones show "Locked note"', ToolTint.notes, 'M5'),
  'recent_notes': WidgetInfo('Recent notes', 'Notes', ToolTint.notes, 'M5'),
};
