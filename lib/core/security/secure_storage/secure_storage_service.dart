import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Typed wrapper around [FlutterSecureStorage] — the *only* place allowed to
/// touch it directly. Reserved for small, sensitive values: the local DEK
/// wrapper, session/auth tokens, and a handful of app-level flags. Bulk
/// records belong in Drift, never here (Section 1.3 of the architecture doc).
@lazySingleton
class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _authTokenKey = 'auth_token';
  static const _sqlCipherKeyKey = 'sqlcipher_db_key';
  static const _dataEncryptionKeyKey = 'data_encryption_key';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _migrationCompleteKey = 'migration_complete';
  static const _homeWidgetSnapshotKey = 'home_widget_snapshot';

  Future<String?> readAuthToken() => _storage.read(key: _authTokenKey);
  Future<void> writeAuthToken(String value) =>
      _storage.write(key: _authTokenKey, value: value);
  Future<void> deleteAuthToken() => _storage.delete(key: _authTokenKey);

  Future<String?> readSqlCipherKey() => _storage.read(key: _sqlCipherKeyKey);
  Future<void> writeSqlCipherKey(String value) =>
      _storage.write(key: _sqlCipherKeyKey, value: value);

  Future<String?> readDataEncryptionKey() =>
      _storage.read(key: _dataEncryptionKeyKey);
  Future<void> writeDataEncryptionKey(String value) =>
      _storage.write(key: _dataEncryptionKeyKey, value: value);

  Future<bool> readOnboardingComplete() async =>
      (await _storage.read(key: _onboardingCompleteKey)) == 'true';
  Future<void> writeOnboardingComplete(bool value) =>
      _storage.write(key: _onboardingCompleteKey, value: value.toString());

  Future<bool> readMigrationComplete() async =>
      (await _storage.read(key: _migrationCompleteKey)) == 'true';
  Future<void> writeMigrationComplete(bool value) =>
      _storage.write(key: _migrationCompleteKey, value: value.toString());

  Future<String?> readHomeWidgetSnapshot() =>
      _storage.read(key: _homeWidgetSnapshotKey);
  Future<void> writeHomeWidgetSnapshot(String jsonSnapshot) =>
      _storage.write(key: _homeWidgetSnapshotKey, value: jsonSnapshot);
}
