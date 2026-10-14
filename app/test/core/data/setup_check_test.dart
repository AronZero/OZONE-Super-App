import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/data/setup_check.dart';

void main() {
  test('bundled SQLite opens and supports accent-insensitive FTS5 search', () async {
    final r = await runSetupCheck();
    expect(r.sqliteVersion, isNotEmpty);
    expect(r.fts5, isTrue);
  });
}
