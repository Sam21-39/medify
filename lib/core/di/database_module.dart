import 'package:injectable/injectable.dart';

import '../database/drift/app_database.dart';
import '../database/encryption/database_key_provisioner.dart';

/// Registers the singleton [AppDatabase] instance. Async because opening it
/// requires resolving/provisioning the SQLCipher-equivalent key first —
/// resolved once during `bootstrap.dart`'s `configureDependencies()` call.
@module
abstract class DatabaseModule {
  @preResolve
  @lazySingleton
  Future<AppDatabase> appDatabase(DatabaseKeyProvisioner keyProvisioner) =>
      AppDatabase.open(keyProvisioner);
}
