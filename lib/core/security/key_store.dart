import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medify/core/security/security_exceptions.dart';

/// Minimal secure key/value interface, so tests can fake platform storage.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class FlutterSecretStore implements SecretStore {
  FlutterSecretStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

/// Reads or creates the 32-byte database key (base64 under [keyName]).
/// Never deletes or overwrites an existing key.
class DatabaseKeyStore {
  DatabaseKeyStore(this._store);

  static const keyName = 'medify.db.key.v1';

  final SecretStore _store;

  /// [databaseHasData]: true when an encrypted database already holds rows.
  /// A missing key then throws [KeyMismatch] instead of creating a new one.
  Future<Uint8List> loadOrCreate({required bool databaseHasData}) async {
    final String? stored;
    try {
      stored = await _store.read(keyName);
    } on Exception catch (e) {
      throw KeyStoreUnavailable('read failed: ${e.runtimeType}');
    }
    if (stored != null) {
      final Uint8List key;
      try {
        key = base64Decode(stored);
      } on FormatException {
        throw const KeyMismatch('stored key is not valid base64');
      }
      if (key.length != 32) {
        throw const KeyMismatch('stored key is not 32 bytes');
      }
      return key;
    }
    if (databaseHasData) {
      throw const KeyMismatch('key missing but database has rows');
    }
    final random = Random.secure();
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    try {
      await _store.write(keyName, base64Encode(key));
    } on Exception catch (e) {
      throw KeyStoreUnavailable('write failed: ${e.runtimeType}');
    }
    return key;
  }
}
