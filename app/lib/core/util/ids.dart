import 'dart:math';

final Random _rng = Random.secure();

/// A RFC-4122 v4 UUID string.
///
/// Used for client-generated session ids and idempotency keys. Not a security
/// primitive — it exists so a session created offline carries a stable identity
/// the server can dedupe against when it later syncs.
String newUuidV4() {
  final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
  String hex(int start, int end) {
    final buffer = StringBuffer();
    for (var i = start; i < end; i++) {
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
