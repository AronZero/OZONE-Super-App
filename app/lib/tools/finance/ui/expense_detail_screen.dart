import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/dates.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/amounts.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../state/finance_providers.dart';
import 'expense_sheet.dart';
import 'expenses_overview.dart';
import 'savings_parts.dart';

/// Expense detail (W3 · Expense detail): facts, Refunded switch with Undo,
/// Edit, and Delete with Undo.
class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});
  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final data = ref.watch(expensesDataProvider).value;
    final e = data?.byId(expenseId);
    if (e == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(children: [
            const DetailTopBar(title: 'Expense'),
            if (data != null) Padding(padding: const EdgeInsets.all(Space.xl), child: Text('This expense no longer exists.', style: text.bodyLarge)),
          ]),
        ),
      );
    }
    final date = LocalDate.parseIso(e.date).valueOrNull!;
    final repo = ref.read(expensesRepoProvider);
    final undo = ref.read(undoControllerProvider);

    Future<void> setRefunded(bool on) async {
      await repo.setRefunded(e.id, on);
      await undo.run(
        message: on ? 'Marked as refunded. Totals updated.' : 'No longer refunded. Totals updated.',
        hideNow: () {},
        commit: () async {},
        restore: () => unawaited(repo.setRefunded(e.id, !on)),
      );
    }

    Future<void> delete() async {
      Navigator.of(context).pop();
      final row = await repo.delete(e.id);
      await undo.run(
        message: '${row.item} deleted',
        hideNow: () {},
        commit: () => repo.recordDeleted(row.id),
        restore: () => unawaited(repo.restore(row)),
      );
    }

    Widget fact(String label, String value, {bool muted = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: text.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.inkMuted)),
            const SizedBox(width: Space.m),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: text.bodyLarge!.copyWith(fontWeight: muted ? FontWeight.w600 : FontWeight.w700, color: muted ? c.inkMuted : c.ink)),
            ),
          ]),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            DetailTopBar(title: 'Expense', overline: 'Expenses', trailing: [
              Padding(
                padding: const EdgeInsets.only(right: Space.s),
                child: FilledButton(
                  onPressed: () => showExpenseSheet(context, existing: e),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.surfaceSunken,
                    foregroundColor: c.ink,
                    minimumSize: const Size(48, 40),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: e.isRefunded ? c.surface : financeTile(context), borderRadius: BorderRadius.circular(Radii.card)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.item, style: text.titleMedium!.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: Space.s),
                    Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(
                        money(context, e.amount),
                        style: text.displaySmall!.copyWith(
                          fontSize: 32,
                          letterSpacing: -0.6,
                          color: e.isRefunded ? c.inkMuted : c.ink,
                          decoration: e.isRefunded ? TextDecoration.lineThrough : null,
                          decorationColor: c.inkMuted,
                        ),
                      ),
                      if (e.isRefunded) const RefundedTag(),
                    ]),
                    const SizedBox(height: Space.s),
                    Text(
                      e.isRefunded ? 'Not counted in ${date.year} spending' : 'Counted in ${date.year} spending · ${date.monthName}',
                      style: text.bodyMedium!.copyWith(color: c.inkMuted),
                    ),
                  ]),
                ),
                const SizedBox(height: Space.m),
                GroupCard(children: [
                  fact('Vendor', e.vendor),
                  fact('Date', date.formatLong()),
                  fact('Remarks', e.remarks ?? 'None', muted: e.remarks == null),
                ]),
                const SizedBox(height: Space.m),
                Container(
                  constraints: const BoxConstraints(minHeight: 76),
                  padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 14),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Refunded', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('Left out of every total, as if deleted. It stays in the list, struck through.',
                            style: text.bodyMedium!.copyWith(fontSize: 12.5, height: 1.4, color: c.inkMuted)),
                      ]),
                    ),
                    OzoneSwitch(value: e.isRefunded, label: 'Refunded', accent: financeAccent(context), onChanged: setRefunded),
                  ]),
                ),
                const SizedBox(height: Space.m),
                TextButton.icon(
                  onPressed: delete,
                  icon: Icon(Icons.delete_outline_rounded, color: c.danger),
                  label: Text('Delete expense', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800, color: c.danger)),
                ),
                Text('You can undo a delete for a few seconds.',
                    textAlign: TextAlign.center, style: text.bodyMedium!.copyWith(fontSize: 12.5, color: c.inkMuted)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
