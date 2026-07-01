import 'package:injectable/injectable.dart';

import '../database/app_database.dart';

/// Registers shared-kernel singletons that aren't annotated in place
/// (third-party or cross-cutting types). Feature modules register their own
/// dependencies via `@injectable`/`@lazySingleton` on their own classes.
@module
abstract class RegisterModule {
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();
}
