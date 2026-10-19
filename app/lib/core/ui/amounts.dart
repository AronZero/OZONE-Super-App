import 'package:flutter/widgets.dart';

import '../domain/money.dart';

/// "Hide amounts" (docs/04, F2-01 §6): while on, every ₱ figure on display
/// screens and Home widgets shows as `₱ ••••`, and screen readers say
/// "amount hidden". Display only: nothing changes in the data. Forms where
/// amounts are typed keep showing them (decision M7-3).
class AmountsVisibility extends ChangeNotifier {
  AmountsVisibility({bool hidden = false}) : _hidden = hidden; // ignore: prefer_initializing_formals
  bool _hidden;

  bool get hidden => _hidden;

  set hidden(bool v) {
    if (v == _hidden) return;
    _hidden = v;
    notifyListeners();
  }

  void toggle() => hidden = !_hidden;
}

/// Puts [AmountsVisibility] above the app, so widgets that show amounts
/// rebuild when it changes.
class AmountsScope extends InheritedNotifier<AmountsVisibility> {
  const AmountsScope({super.key, required AmountsVisibility visibility, required super.child}) : super(notifier: visibility);

  /// True while amounts are hidden. Widgets calling this rebuild on a toggle.
  static bool hidden(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AmountsScope>()?.notifier?.hidden ?? false;
}

/// `₱1,234.56`, or `₱ ••••` while hidden.
String money(BuildContext context, int centavos) => AmountsScope.hidden(context) ? Money.hidden : Money.format(centavos);

/// `▲ +₱18,420.00`, or `₱ ••••` while hidden.
String moneyChange(BuildContext context, int centavos) => AmountsScope.hidden(context) ? Money.hidden : Money.change(centavos);

/// Chart axis labels; blank while hidden.
String moneyCompact(BuildContext context, int centavos) => AmountsScope.hidden(context) ? '' : Money.compact(centavos);

/// Screen-reader wording, or "amount hidden".
String moneySpoken(BuildContext context, int centavos) => AmountsScope.hidden(context) ? 'amount hidden' : Money.spoken(centavos);

final _amount = RegExp(r'(▲ \+|▼ −|−|\+)?₱ ?(••••|[\d,]+(?:\.\d{1,2})?)?([kM])?');

/// The same text with every amount in words, for TalkBack (docs/04: amounts are
/// read as "1,234 pesos and 50 centavos"): `▲ +₱3,600.00` → "up 3,600 pesos",
/// `₱125k` → "125 thousand pesos", `₱ ••••` → "amount hidden".
String spokenAmounts(String text) => text
    .replaceAllMapped(_amount, (m) {
      final digits = m[2];
      if (digits == null) return 'pesos'; // the ₱ before an amount field
      if (digits == '••••') return 'amount hidden';
      final sign = switch (m[1]) { '▲ +' => 'up ', '▼ −' => 'down ', '−' => 'minus ', '+' => 'plus ', _ => '' };
      final plain = digits.replaceAll(',', '');
      if (m[3] != null) return '$sign$plain ${m[3] == 'k' ? 'thousand' : 'million'} pesos';
      final parts = plain.split('.');
      final cents = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
      return '$sign${Money.spoken(int.parse(parts[0]) * 100 + cents)}';
    })
    // Arrows before a percentage: "▲ 17.9%" → "up 17.9%".
    .replaceAll('▲ ', 'up ')
    .replaceAll('▼ ', 'down ');
