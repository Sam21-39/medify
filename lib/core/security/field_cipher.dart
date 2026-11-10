import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:medify/core/security/security_exceptions.dart';

/// AES-256-GCM over single text fields. Stored form:
/// `v1.<base64 nonce (12 bytes)>.<base64 ciphertext+tag>`.
class FieldCipher {
  FieldCipher(List<int> keyBytes) : _key = SecretKey(keyBytes) {
    if (keyBytes.length != 32) {
      throw ArgumentError.value(keyBytes.length, 'keyBytes', 'must be 32');
    }
  }

  static const _prefix = 'v1.';
  static const _tagLength = 16;

  static final _algorithm = AesGcm.with256bits();

  final SecretKey _key;

  /// [aad] binds the value to its place, e.g. `medicines.name.<row id>`.
  Future<String> seal(String plain, {required List<int> aad}) async {
    final box = await _algorithm.encrypt(
      utf8.encode(plain),
      secretKey: _key,
      aad: aad,
    );
    final body = [...box.cipherText, ...box.mac.bytes];
    return '$_prefix${base64Encode(box.nonce)}.${base64Encode(body)}';
  }

  Future<String> open(String stored, {required List<int> aad}) async {
    if (!stored.startsWith(_prefix)) {
      throw const CorruptField('missing v1 prefix');
    }
    final parts = stored.substring(_prefix.length).split('.');
    if (parts.length != 2) throw const CorruptField('malformed envelope');
    final List<int> nonce;
    final List<int> body;
    try {
      nonce = base64Decode(parts[0]);
      body = base64Decode(parts[1]);
    } on FormatException {
      throw const CorruptField('bad base64');
    }
    if (body.length < _tagLength) throw const CorruptField('body too short');
    final box = SecretBox(
      body.sublist(0, body.length - _tagLength),
      nonce: nonce,
      mac: Mac(body.sublist(body.length - _tagLength)),
    );
    try {
      return utf8.decode(
        await _algorithm.decrypt(box, secretKey: _key, aad: aad),
      );
    } on SecretBoxAuthenticationError {
      throw const CorruptField('authentication failed');
    }
  }
}
