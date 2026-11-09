import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/security/key_store.dart';
import 'package:medify/core/security/security_exceptions.dart';

class _FakeSecretStore implements SecretStore {
  final values = <String, String>{};
  bool failRead = false;
  bool failWrite = false;
  int writes = 0;

  @override
  Future<String?> read(String key) async {
    if (failRead) throw Exception('keychain locked');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw Exception('keychain locked');
    writes++;
    values[key] = value;
  }
}

void main() {
  late _FakeSecretStore store;
  late DatabaseKeyStore keys;

  setUp(() {
    store = _FakeSecretStore();
    keys = DatabaseKeyStore(store);
  });

  test('creates a 32-byte key when absent', () async {
    final key = await keys.loadOrCreate(databaseHasData: false);
    expect(key.length, 32);
    expect(store.writes, 1);
    expect(base64Decode(store.values[DatabaseKeyStore.keyName]!), key);
  });

  test('reads an existing key without writing', () async {
    final first = await keys.loadOrCreate(databaseHasData: false);
    final again = await keys.loadOrCreate(databaseHasData: true);
    expect(again, first);
    expect(store.writes, 1);
  });

  test('read error is KeyStoreUnavailable and writes nothing', () async {
    store.failRead = true;
    await expectLater(
      keys.loadOrCreate(databaseHasData: false),
      throwsA(isA<KeyStoreUnavailable>()),
    );
    expect(store.writes, 0);
  });

  test('write error is KeyStoreUnavailable', () async {
    store.failWrite = true;
    await expectLater(
      keys.loadOrCreate(databaseHasData: false),
      throwsA(isA<KeyStoreUnavailable>()),
    );
  });

  test(
    'missing key with existing rows is KeyMismatch, not overwritten',
    () async {
      await expectLater(
        keys.loadOrCreate(databaseHasData: true),
        throwsA(isA<KeyMismatch>()),
      );
      expect(store.values, isEmpty);
      expect(store.writes, 0);
    },
  );
}
