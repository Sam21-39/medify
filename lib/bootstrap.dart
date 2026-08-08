import 'package:flutter/widgets.dart';

import 'core/di/di_setup.dart';
import 'core/error/app_error_handler.dart';
import 'core/notifications/flutter_local_notification_scheduler.dart';
import 'core/remote_config/remote_config_service.dart';
import 'core/sync/sync_engine.dart';

/// Runs once before `main.dart` renders anything — a native splash screen
/// covers this window rather than a Flutter-rendered loading screen
/// (Section 7). Order matters: error handling first, then config, then the
/// database, then DI (which itself opens the database via
/// `DatabaseModule.appDatabase`), then app-level services.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppErrorHandler().install();

  // TODO(firebase): run `flutterfire configure` to generate
  // `firebase_options.dart`, then uncomment:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // The app must still boot without it — every dependent service below
  // (RemoteConfigService, sync, auth) already fails safe to its default.

  await configureDependencies();

  await getIt<RemoteConfigService>().initialize();
  await getIt<FlutterLocalNotificationScheduler>().initialize();
  getIt<SyncEngine>().start();
}
