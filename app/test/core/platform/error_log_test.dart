import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/platform/error_log.dart';

void main() {
  late Directory dir;
  late ErrorLog log;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ozone_errors');
    log = ErrorLog(() async => File('${dir.path}/errors.log'), maxBytes: 2000, clock: () => DateTime.utc(2026, 10, 15, 9));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('keeps the time, place and error type, never the message', () async {
    await log.record(StateError('Card 4111 for Maria'), StackTrace.current, where: 'save expense');
    final text = await File('${dir.path}/errors.log').readAsString();
    expect(text, startsWith('2026-10-15T09:00:00.000Z · save expense · StateError'));
    expect(text, isNot(contains('4111')));
    expect(text, isNot(contains('Maria')));
    expect(await log.count(), 1);
  });

  test('drops the oldest entries past the size cap', () async {
    for (var i = 0; i < 40; i++) {
      await log.record(StateError('x'), StackTrace.current);
    }
    final f = File('${dir.path}/errors.log');
    expect(await f.length(), lessThanOrEqualTo(2000));
    expect(await f.readAsString(), startsWith('2026-'));
    expect(await log.count(), greaterThan(0));
  });

  test('clear removes the file and notifies', () async {
    await log.record(StateError('x'), null);
    final before = log.changes.value;
    await log.clear();
    expect(await log.count(), 0);
    expect(log.changes.value, before + 1);
  });

  test('the disabled log writes nothing', () async {
    final off = ErrorLog.disabled();
    await off.record(StateError('x'), null);
    expect(await off.count(), 0);
    expect(await off.file(), isNull);
  });
}
