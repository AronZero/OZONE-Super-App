import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database.dart';
import '../../../core/domain/dates.dart';
import '../../../core/domain/money.dart';
import '../../../core/state/today.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/components/forms.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/expenses.dart';
import '../state/finance_providers.dart';
import 'expense_sheet.dart';
import 'savings_parts.dart';

enum ExpenseSort {
  newest('Newest'),
  oldest('Oldest'),
  highest('Highest'),
  lowest('Lowest');

  const ExpenseSort(this.label);
  final String label;
}

/// Expenses tab (W2 · Expenses): this year so far vs the same period last
/// year, filters (decision M3-3), and expenses grouped by month.
class ExpensesOverview extends ConsumerStatefulWidget {
  const ExpensesOverview({super.key});

  @override
  ConsumerState<ExpensesOverview> createState() => _ExpensesOverviewState();
}

class _ExpensesOverviewState extends ConsumerState<ExpensesOverview> {
  int? _year;
  Set<String> _vendors = {};
  int? _min, _max;
  bool _refundedOnly = false;
  ExpenseSort _sort = ExpenseSort.newest;

  bool get _filtered => _vendors.isNotEmpty || _min != null || _max != null || _refundedOnly;

  void _clear() => setState(() {
        _vendors = {};
        _min = _max = null;
        _refundedOnly = false;
      });

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final data = ref.watch(expensesDataProvider);

    return Stack(children: [
      data.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Text('Expenses couldn’t be loaded. Close and reopen OZONE to try again.', style: text.bodyLarge),
        ),
        data: (d) {
          final firstYear = d.rows.isEmpty ? today.year : d.spends.map((s) => s.date.year).reduce((a, b) => a < b ? a : b);
          final year = (_year ?? today.year).clamp(firstYear, today.year);
          final inYear = [for (final r in d.rows) if (r.date.startsWith('$year-')) r];
          final shown = [
            for (final r in inYear)
              if ((_vendors.isEmpty || _vendors.contains(r.vendor)) &&
                  (_min == null || r.amount >= _min!) &&
                  (_max == null || r.amount <= _max!) &&
                  (!_refundedOnly || r.isRefunded))
                r,
          ];
          switch (_sort) {
            case ExpenseSort.newest:
              break; // already newest first
            case ExpenseSort.oldest:
              shown.sort((a, b) => a.date == b.date ? a.createdAt.compareTo(b.createdAt) : a.date.compareTo(b.date));
            case ExpenseSort.highest:
              shown.sort((a, b) => b.amount.compareTo(a.amount));
            case ExpenseSort.lowest:
              shown.sort((a, b) => a.amount.compareTo(b.amount));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, 104),
            children: [
              _YearCard(
                year: year,
                ytd: yearToDate(d.spends, year, today),
                canBack: year > firstYear,
                canForward: year < today.year,
                onYear: (y) => setState(() => _year = y),
                hasAny: d.rows.isNotEmpty,
              ),
              if (d.rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.l),
                  child: Text('No expenses yet. Add a purchase with the + button; refunds can be marked later.',
                      style: text.bodyLarge!.copyWith(color: c.inkMuted)),
                )
              else ...[
                const SizedBox(height: Space.m),
                _FilterRow(
                  vendors: _vendors,
                  min: _min,
                  max: _max,
                  refundedOnly: _refundedOnly,
                  sort: _sort,
                  allVendors: {for (final r in inYear) r.vendor}.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
                  onVendors: (v) => setState(() => _vendors = v),
                  onAmount: (lo, hi) => setState(() {
                    _min = lo;
                    _max = hi;
                  }),
                  onRefunded: (v) => setState(() => _refundedOnly = v),
                  onSort: (s) => setState(() => _sort = s),
                ),
                const SizedBox(height: Space.s),
                if (shown.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(Space.xl),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
                    child: Column(children: [
                      Text(_filtered ? 'No expenses match these filters' : 'No expenses in $year',
                          style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
                      if (_filtered) TextButton(onPressed: _clear, child: Text('Clear filters', style: TextStyle(color: c.ink, fontWeight: FontWeight.w800))),
                    ]),
                  )
                else if (_sort == ExpenseSort.newest || _sort == ExpenseSort.oldest)
                  ..._byMonth(shown, today)
                else
                  _Group(rows: shown, today: today),
              ],
            ],
          );
        },
      ),
      Positioned(
        right: Space.screen,
        bottom: Space.screen,
        child: FinanceAddButton(label: 'Add expense', onPressed: () => showExpenseSheet(context)),
      ),
    ]);
  }

  List<Widget> _byMonth(List<ExpenseRow> rows, LocalDate today) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final groups = <String, List<ExpenseRow>>{};
    for (final r in rows) {
      groups.putIfAbsent(r.date.substring(0, 7), () => []).add(r);
    }
    return [
      for (final e in groups.entries) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xs, 10, Space.xs, 6),
          child: Row(children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(LocalDate.parseIso('${e.key}-01').valueOrNull!.monthName, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
            // Refunded expenses never count (F1-04 §5).
            Text(Money.format(e.value.where((r) => !r.isRefunded).fold(0, (a, r) => a + r.amount)),
                style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800, color: c.inkMuted)),
          ]),
        ),
        _Group(rows: e.value, today: today),
      ],
    ];
  }
}

class _YearCard extends StatelessWidget {
  const _YearCard({required this.year, required this.ytd, required this.canBack, required this.canForward, required this.onYear, required this.hasAny});
  final int year;
  final YearToDate ytd;
  final bool canBack;
  final bool canForward;
  final ValueChanged<int> onYear;
  final bool hasAny;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final current = !canForward;
    final tenths = ytd.changeTenths;
    final period = current ? 'same period in ${year - 1}' : '${year - 1}';
    final compare = tenths == null
        ? 'Nothing spent in the $period'
        : '${tenths > 0 ? '▲' : tenths < 0 ? '▼' : ''} ${percentTenths(tenths)} vs $period (${Money.format(ytd.lastYear)})'.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.l, 10, Space.l, 14),
      decoration: BoxDecoration(color: financeTile(context), borderRadius: BorderRadius.circular(Radii.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(
            tooltip: 'Previous year',
            onPressed: canBack ? () => onYear(year - 1) : null,
            icon: Icon(Icons.chevron_left_rounded, color: canBack ? c.ink : c.outline),
          ),
          Text('$year', style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800)),
          IconButton(
            tooltip: 'Next year',
            onPressed: canForward ? () => onYear(year + 1) : null,
            icon: Icon(Icons.chevron_right_rounded, color: canForward ? c.ink : c.outline),
          ),
          const Spacer(),
          if (hasAny)
            Material(
              color: c.surface,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => context.push('/finance/expenses/years'),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: Text('Yearly report', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ]),
        Text(current ? 'Spent so far this year' : 'Spent in $year', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
        const SizedBox(height: Space.xs),
        Semantics(
          label: '${current ? 'Spent so far this year' : 'Spent in $year'}: ${Money.spoken(ytd.thisYear)}',
          excludeSemantics: true,
          child: Text(Money.format(ytd.thisYear), style: text.displaySmall!.copyWith(fontSize: 30, letterSpacing: -0.6)),
        ),
        const SizedBox(height: Space.xs),
        // Spending changes use the neutral muted colour (docs/05).
        Text(compare, style: text.bodyMedium!.copyWith(fontSize: 12.5, fontWeight: FontWeight.w800, color: c.inkMuted)),
      ]),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.vendors,
    required this.min,
    required this.max,
    required this.refundedOnly,
    required this.sort,
    required this.allVendors,
    required this.onVendors,
    required this.onAmount,
    required this.onRefunded,
    required this.onSort,
  });

  final Set<String> vendors;
  final int? min;
  final int? max;
  final bool refundedOnly;
  final ExpenseSort sort;
  final List<String> allVendors;
  final ValueChanged<Set<String>> onVendors;
  final void Function(int? min, int? max) onAmount;
  final ValueChanged<bool> onRefunded;
  final ValueChanged<ExpenseSort> onSort;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    Widget chip(String label, bool on, VoidCallback onTap) => Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: on ? financeAccent(context) : c.surfaceSunken,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                child: Text(label, style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: on ? c.onAccent : c.ink)),
              ),
            ),
          ),
        );
    final amountLabel = min == null && max == null
        ? 'Amount ▾'
        : min != null && max != null
            ? '${Money.compact(min!)}–${Money.compact(max!)}'
            : min != null
                ? '≥ ${Money.compact(min!)}'
                : '≤ ${Money.compact(max!)}';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        chip(vendors.isEmpty ? 'Vendor ▾' : vendors.length == 1 ? vendors.first : '${vendors.length} vendors', vendors.isNotEmpty,
            () => _pickVendors(context)),
        const SizedBox(width: Space.s),
        chip(amountLabel, min != null || max != null, () => _pickAmount(context)),
        const SizedBox(width: Space.s),
        chip('Refunded', refundedOnly, () => onRefunded(!refundedOnly)),
        const SizedBox(width: Space.s),
        PopupMenuButton<ExpenseSort>(
          tooltip: 'Sort',
          initialValue: sort,
          color: c.surface,
          onSelected: onSort,
          itemBuilder: (_) => [for (final s in ExpenseSort.values) PopupMenuItem(value: s, child: Text(s.label))],
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: Space.s),
            alignment: Alignment.center,
            child: Text('${sort.label} ⇅', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Future<void> _pickVendors(BuildContext context) async {
    final picked = {...vendors};
    final result = await showOzoneSheet<Set<String>>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SheetFrame(
          title: 'Vendor',
          action: Row(children: [
            Expanded(child: OzoneButton(label: 'Clear', primary: false, onPressed: () => Navigator.of(context).pop(<String>{}))),
            const SizedBox(width: Space.s),
            Expanded(
              child: OzoneButton(
                label: 'Show',
                color: financeAccent(context),
                foreground: OzoneThemeColors.of(context).onAccent,
                onPressed: () => Navigator.of(context).pop(picked),
              ),
            ),
          ]),
          children: [
            if (allVendors.isEmpty) const Text('No vendors in this year.'),
            GroupCard(children: [
              for (final v in allVendors)
                CheckboxListTile(
                  value: picked.contains(v),
                  title: Text(v),
                  activeColor: financeAccent(context),
                  onChanged: (on) => setState(() => on == true ? picked.add(v) : picked.remove(v)),
                ),
            ]),
          ],
        ),
      ),
    );
    if (result != null) onVendors(result);
  }

  Future<void> _pickAmount(BuildContext context) async {
    final lo = TextEditingController(text: min == null ? '' : Money.format(min!).substring(1));
    final hi = TextEditingController(text: max == null ? '' : Money.format(max!).substring(1));
    final result = await showOzoneSheet<(int?, int?)>(
      context,
      builder: (context) => SheetFrame(
        title: 'Amount',
        action: Row(children: [
          Expanded(child: OzoneButton(label: 'Clear', primary: false, onPressed: () => Navigator.of(context).pop((null, null)))),
          const SizedBox(width: Space.s),
          Expanded(
            child: OzoneButton(
              label: 'Show',
              color: financeAccent(context),
              foreground: OzoneThemeColors.of(context).onAccent,
              onPressed: () => Navigator.of(context).pop((
                lo.text.trim().isEmpty ? null : Money.parse(lo.text, allowZero: true).valueOrNull,
                hi.text.trim().isEmpty ? null : Money.parse(hi.text, allowZero: true).valueOrNull,
              )),
            ),
          ),
        ]),
        children: [
          Row(children: [
            Expanded(child: OzoneTextField(label: 'From', controller: lo, prefix: '₱ ', hint: '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: amountFormatters)),
            const SizedBox(width: 10),
            Expanded(child: OzoneTextField(label: 'To', controller: hi, prefix: '₱ ', hint: 'any', keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: amountFormatters)),
          ]),
        ],
      ),
    );
    lo.dispose();
    hi.dispose();
    if (result != null) onAmount(result.$1, result.$2);
  }
}

/// A white group of expense rows.
class _Group extends StatelessWidget {
  const _Group({required this.rows, required this.today});
  final List<ExpenseRow> rows;
  final LocalDate today;

  @override
  Widget build(BuildContext context) => GroupCard(children: [for (final r in rows) ExpenseRowTile(row: r, today: today)]);
}

/// One expense: item, vendor · date, amount (struck through when refunded).
class ExpenseRowTile extends StatelessWidget {
  const ExpenseRowTile({super.key, required this.row, required this.today});
  final ExpenseRow row;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    final text = Theme.of(context).textTheme;
    final date = LocalDate.parseIso(row.date).valueOrNull!.format(today);
    return Semantics(
      button: true,
      label: '${row.item}, ${row.vendor}, $date, ${Money.spoken(row.amount)}${row.isRefunded ? ', refunded, not counted' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push('/finance/expenses/${row.id}'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Space.m),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(row.item, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${row.vendor} · $date', style: text.bodyMedium!.copyWith(fontSize: 12.5, color: c.inkMuted)),
                ]),
              ),
              const SizedBox(width: Space.s),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  Money.format(row.amount),
                  style: text.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                    color: row.isRefunded ? c.inkMuted : c.ink,
                    decoration: row.isRefunded ? TextDecoration.lineThrough : null,
                    decorationColor: c.inkMuted,
                  ),
                ),
                if (row.isRefunded) ...[const SizedBox(height: 3), const RefundedTag()],
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/// "REFUNDED" tag (W2 · Expenses).
class RefundedTag extends StatelessWidget {
  const RefundedTag({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OzoneThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(999)),
      child: Text('REFUNDED',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: c.inkMuted)),
    );
  }
}
