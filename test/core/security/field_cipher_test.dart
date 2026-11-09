import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/security/field_cipher.dart';
import 'package:medify/core/security/security_exceptions.dart';

void main() {
  final cipher = FieldCipher(List.filled(32, 7));

  test('round trip', () async {
    final stored = await cipher.seal('Ann — 1 tablet');
    expect(stored, startsWith('v1.'));
    expect(await cipher.open(stored), 'Ann — 1 tablet');
  });

  test('tampered ciphertext throws CorruptField', () async {
    final stored = await cipher.seal('secret');
    final parts = stored.split('.');
    final body = parts[2].codeUnits.toList();
    body[0] = body[0] == 'A'.codeUnitAt(0)
        ? 'B'.codeUnitAt(0)
        : 'A'.codeUnitAt(0);
    final tampered = '${parts[0]}.${parts[1]}.${String.fromCharCodes(body)}';
    await expectLater(cipher.open(tampered), throwsA(isA<CorruptField>()));
  });

  test('value without v1 prefix throws CorruptField', () async {
    await expectLater(cipher.open('Ann'), throwsA(isA<CorruptField>()));
  });

  test('nonce differs per call', () async {
    final a = await cipher.seal('same');
    final b = await cipher.seal('same');
    expect(a, isNot(b));
    expect(a.split('.')[1], isNot(b.split('.')[1]));
  });
}
