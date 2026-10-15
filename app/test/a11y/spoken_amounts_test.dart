import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/ui/amounts.dart';

/// TalkBack wording for amounts in text (docs/04 › Accessibility).
void main() {
  test('plain amounts in pesos and centavos', () {
    expect(spokenAmounts('₱1,234.50'), '1,234 pesos and 50 centavos');
    expect(spokenAmounts('₱125,000.00'), '125,000 pesos');
    expect(spokenAmounts('₱1.01'), '1 peso and 1 centavo');
  });

  test('changes, signs and compact chart labels', () {
    expect(spokenAmounts('▲ +₱3,600.00 · 19.5%'), 'up 3,600 pesos · 19.5%');
    expect(spokenAmounts('▼ −₱2,000.00'), 'down 2,000 pesos');
    expect(spokenAmounts('−₱5'), 'minus 5 pesos');
    expect(spokenAmounts('₱125k'), '125 thousand pesos');
    expect(spokenAmounts('₱1.25M'), '1.25 million pesos');
  });

  test('hidden amounts and sentences', () {
    expect(spokenAmounts('₱ ••••'), 'amount hidden');
    expect(spokenAmounts('₱'), 'pesos');
    expect(spokenAmounts('Shows ₱ •••• until you tap the eye'), 'Shows amount hidden until you tap the eye');
    expect(spokenAmounts('2026 so far is ₱14,703.15, more than 2025 (₱3,899.00).'),
        '2026 so far is 14,703 pesos and 15 centavos, more than 2025 (3,899 pesos).');
  });
}
