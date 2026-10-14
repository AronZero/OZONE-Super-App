import 'dart:math';

final Random _secure = Random.secure();

/// A new random UUID v4 in lower case (docs/spec/F1-01 §1). IDs are made on
/// the phone, never reused and never changed: they link database rows to
/// workbook rows.
String newId() {
  final b = List<int>.generate(16, (_) => _secure.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // RFC 4122 variant
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

final RegExp _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

/// Whether [s] looks like an OZONE ID (used when reading workbooks).
bool isId(String s) => _uuid.hasMatch(s);
