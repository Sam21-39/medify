import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'di_setup.config.dart';

final getIt = GetIt.instance;

/// Registers every repository, use case, and service into [getIt] via
/// code-generated `injectable` registration — singletons for
/// `NotificationScheduler`, `SyncEngine`, `RemoteConfigService`; factories
/// for per-feature use cases (Section 7).
@InjectableInit()
Future<void> configureDependencies() => getIt.init();
