import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/dates.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../amounts.dart';
import '../motion.dart';
import '../theme/oz_icons.dart';

/// Opens a form sheet (docs/04: forms with 6 fields or fewer are sheets).
/// Sheets have rounded tops (28) and lift above the keyboard.
Future<T?> showOzoneSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  final c = OzoneThemeColors.of(context);
  return showModalBottomSheet<T>(
    context: context,
    sheetAnimationStyle: Motion.of(context).sheetStyle,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: builder(context),
    ),
  );
}

/// Sheet layout: title row with close, scrolling fields, and a main button.
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.title, required this.children, required this.action, this.dirty = false});

  final String title;
  final List<Widget> children;
  final Widget action;

  /// When true, closing asks before discarding the changes (docs/04).
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return DiscardGuard(
      dirty: dirty,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.xl, Space.m, Space.xl, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: c.outline, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: Space.m),
            Row(
              children: [
                Expanded(child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleLarge))),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(OzIcons.close, color: c.ink),
                ),
              ],
            ),
            const SizedBox(height: Space.s),
            for (final w in children) ...[w, const SizedBox(height: Space.l)],
            action,
          ],
        ),
      ),
    );
  }
}

/// Asks "Discard changes?" before a form with unsaved changes closes.
class DiscardGuard extends StatelessWidget {
  const DiscardGuard({super.key, required this.dirty, required this.child});

  final bool dirty;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final nav = Navigator.of(context);
          final discard = await confirmDialog(
            context,
            title: 'Discard changes?',
            body: 'What you typed here won’t be saved.',
            confirm: 'Discard',
            cancel: 'Keep editing',
            danger: true,
          );
          if (discard == true && nav.mounted) nav.pop();
        },
        child: child,
      );
}

/// A plain confirmation dialog (W3 States: dialogs for permanent actions).
Future<bool?> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  String cancel = 'Cancel',
  bool danger = false,
}) {
  final c = OzoneThemeColors.of(context);
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (context) => AlertDialog(
      backgroundColor: c.surface,
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      content: Text(body, style: Theme.of(context).textTheme.bodyLarge),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancel, style: TextStyle(color: c.ink, fontWeight: FontWeight.w800))),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirm, style: TextStyle(color: danger ? c.danger : c.ink, fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}

/// Label above a filled input (radius 14), with the error in words below.
class OzoneTextField extends StatelessWidget {
  const OzoneTextField({
    super.key,
    required this.label,
    required this.controller,
    this.error,
    this.hint,
    this.prefix,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.autofocus = false,
    this.onChanged,
    this.textInputAction,
    this.fieldKey,
    this.focusNode,
    this.large = false,
  });

  final String label;
  final TextEditingController controller;
  final String? error;
  final String? hint;
  final String? prefix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final Key? fieldKey;
  final FocusNode? focusNode;

  /// Large bold text, for amounts.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    OutlineInputBorder border(Color color, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.tile),
          borderSide: BorderSide(color: color, width: w),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          minLines: 1,
          onChanged: onChanged,
          textInputAction: textInputAction,
          style: large ? text.titleMedium!.copyWith(fontSize: 18, fontWeight: FontWeight.w800) : text.bodyLarge,
          cursorColor: c.ink,
          decoration: InputDecoration(
            filled: true,
            fillColor: c.surfaceSunken,
            hintText: hint,
            hintStyle: text.bodyLarge!.copyWith(color: c.inkMuted),
            // An icon slot, so the ₱ shows even before the field is focused (W1 boards).
            prefixIcon: prefix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: Space.l, right: 6),
                    child: Text(prefix!.trim(), semanticsLabel: spokenAmounts(prefix!.trim()), style: text.bodyLarge!.copyWith(color: c.inkMuted, fontWeight: FontWeight.w700)),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: EdgeInsets.fromLTRB(prefix == null ? Space.l : 0, 15, Space.l, 15),
            border: border(Colors.transparent, 0),
            enabledBorder: border(error == null ? Colors.transparent : c.danger, 2),
            focusedBorder: border(error == null ? c.ink : c.danger, 2),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Semantics(liveRegion: true, child: Text(error!, style: text.bodyMedium!.copyWith(color: c.danger, fontWeight: FontWeight.w700))),
        ],
      ],
    );
  }
}

/// Lets only amount characters through: digits, `.` and `,`.
final List<TextInputFormatter> amountFormatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,₱ ]'))];

/// A tinted date button ("13 Oct 2026") that opens the date picker.
/// Dates after [today] can't be picked (F1-01: no future business dates).
class DateButton extends StatelessWidget {
  const DateButton({super.key, required this.date, required this.today, required this.onChanged, this.accent, this.tile, this.firstDate});

  final LocalDate date;
  final LocalDate today;
  final ValueChanged<LocalDate> onChanged;
  final Color? accent;
  final Color? tile;
  final LocalDate? firstDate;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final fg = accent ?? c.ink;
    return Semantics(
      button: true,
      label: spokenAmounts('Change date, currently ${date.formatLong()}'),
      excludeSemantics: true,
      child: Material(
        color: tile ?? c.surfaceSunken,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final first = firstDate ?? LocalDate(2000, 1, 1);
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(date.year, date.month, date.day),
              firstDate: DateTime(first.year, first.month, first.day),
              lastDate: DateTime(today.year, today.month, today.day),
            );
            if (picked != null) onChanged(LocalDate.fromDateTime(picked));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(OzIcons.calendarToday, size: 18, color: fg),
                const SizedBox(width: Space.s),
                // Wraps at large text sizes instead of overflowing (docs/04).
                Flexible(child: Text(date.formatLong(), style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w800, color: fg))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small pill with a dashed outline: the "Carried" mark (W1 boards).
class DashedPill extends StatelessWidget {
  const DashedPill(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return CustomPaint(
      painter: DashedRRectPainter(color: c.inkMuted, radius: 999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted)),
      ),
    );
  }
}

/// Paints a dashed rounded rectangle along the widget's bounds.
class DashedRRectPainter extends CustomPainter {
  DashedRRectPainter({required this.color, this.radius = 6, this.strokeWidth = 1.5, this.dash = 4, this.gap = 3, this.topOnlyRadius = false});

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;
  final bool topOnlyRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(radius.clamp(0, size.shortestSide / 2));
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final rr = topOnlyRadius
        ? RRect.fromRectAndCorners(rect, topLeft: r, topRight: r, bottomLeft: const Radius.circular(2), bottomRight: const Radius.circular(2))
        : RRect.fromRectAndRadius(rect, r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in (Path()..addRRect(rr)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, (d + dash).clamp(0, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedRRectPainter old) => old.color != color || old.radius != radius;
}
