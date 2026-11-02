import 'dart:math';

abstract final class IdGenerator {
  static final Random _random = Random.secure();

  static String generate() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // UUID version 4.
    bytes[6] = (bytes[6] & 0x0F) | 0x40;

    // RFC 4122 variant.
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));

    final value = hex.join();

    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20, 32)}';
  }
}
