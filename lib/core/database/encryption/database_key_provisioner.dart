import 'dart:convert';
import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../security/secure_storage/secure_storage_service.dart';

/// Generates (on first launch) and retrieves the local SQLCipher database
/// key, stored exclusively via [SecureStorageService] (Android Keystore /
/// iOS Keychain-backed). This key is device-local and never leaves the
/// device — losing it means the local database is unrecoverable by design
/// (Section 5.2). It is intentionally distinct from the cloud-payload DEK
/// managed by `core/security/encryption_engine`.
@lazySingleton
class DatabaseKeyProvisioner {
  DatabaseKeyProvisioner(this._secureStorage);

  final SecureStorageService _secureStorage;

  Future<String> resolveKey() async {
    final existing = await _secureStorage.readSqlCipherKey();
    if (existing != null) return existing;

    final generated = _generateKey();
    await _secureStorage.writeSqlCipherKey(generated);
    return generated;
  }

  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
