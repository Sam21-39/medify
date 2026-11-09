import 'package:get_it/get_it.dart';
import 'package:medify/core/permissions/permission_service.dart';
import 'package:medify/core/system/system_service.dart';
import 'package:medify/core/database/medify_database.dart';
import 'package:medify/core/database/settings_store.dart';
import 'package:medify/core/security/field_cipher.dart';
import 'package:medify/core/security/key_store.dart';
import 'package:medify/features/medicines/data/sqflite/medicine_sqflite_repository.dart';
import 'package:medify/features/schedule/data/sqflite/medicine_log_sqflite_repository.dart';
import 'package:medify/features/schedule/data/sqflite/occurrence_sqflite_generator.dart';
import 'package:medify/features/profiles/data/sqflite/profile_sqflite_repository.dart';
import 'package:medify/features/profiles/data/sqflite/care_link_sqflite_repository.dart';
import 'package:medify/features/achievements/data/sqflite/achievement_sqflite_repository.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:medify/features/schedule/domain/repositories/medicine_log_repository.dart';
import 'package:medify/features/profiles/domain/repositories/user_profile_repository.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_cubit.dart';
import 'package:medify/features/schedule/presentation/cubit/medicine_log_cubit.dart';
import 'package:medify/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:medify/features/statistics/presentation/cubit/statistics_cubit.dart';
import 'package:medify/features/history/presentation/cubit/history_cubit.dart';
import 'package:medify/core/notifications/notification_service.dart';
import 'package:medify/core/preferences/preferences_service.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/core/voice/reminder_voice.dart';
import 'package:medify/features/profiles/data/services/profile_service.dart';
import 'package:medify/features/schedule/data/services/daily_log_service.dart';
import 'package:medify/features/schedule/data/services/refill_reminder_service.dart';
import 'package:medify/features/achievements/data/services/achievement_service.dart';
import 'package:sqflite/sqflite.dart';

/// Service locator instance
final getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> initializeDependencies() async {
  // Data sources: one database handle, one field cipher
  final database = await MedifyDatabase.open();
  getIt.registerSingleton<Database>(database);
  final profileRows =
      Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM profiles'),
      ) ??
      0;
  // Throws KeyStoreUnavailable / KeyMismatch: repos never open without a key.
  final keyBytes = await DatabaseKeyStore(FlutterSecretStore())
      .loadOrCreate(databaseHasData: profileRows > 0);
  final cipher = FieldCipher(keyBytes);
  getIt.registerSingleton<FieldCipher>(cipher);
  getIt.registerSingleton<SettingsStore>(SettingsStore(database));

  // Initialize preferences service
  final preferencesService = await PreferencesService.initialize(
    getIt<SettingsStore>(),
  );
  getIt.registerSingleton<PreferencesService>(preferencesService);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  getIt.registerSingleton<NotificationService>(notificationService);

  // Initalize permission service
  final permissionService = AppPermissionService();
  getIt.registerSingleton<AppPermissionService>(permissionService);

  // Initialize system service
  final systemService = SystemService();
  getIt.registerSingleton<SystemService>(systemService);

  getIt.registerLazySingleton<UserProfileRepository>(
    () => ProfileSqfliteRepository(database, cipher),
  );
  getIt.registerLazySingleton<ProfileService>(
    () => ProfileService(
      getIt<UserProfileRepository>(),
      getIt<PreferencesService>(),
    ),
  );
  await getIt<ProfileService>().initialize();

  getIt.registerLazySingleton<CareLinkSqfliteRepository>(
    () => CareLinkSqfliteRepository(database),
  );
  getIt.registerLazySingleton<AppMessenger>(AppMessenger.new);
  getIt.registerLazySingleton<ReminderVoice>(ReminderVoice.new);

  // Repositories
  getIt.registerLazySingleton<MedicineRepository>(
    () => SqfliteMedicineRepository(database, cipher),
  );

  getIt.registerLazySingleton<MedicineLogRepository>(
    () => SqfliteMedicineLogRepository(database, cipher),
  );

  getIt.registerLazySingleton<OccurrenceSqfliteGenerator>(
    () => OccurrenceSqfliteGenerator(database),
  );

  // Refill reminder service for medicine stock tracking
  // Register before cubits that depend on it
  getIt.registerLazySingleton<RefillReminderService>(
    () => RefillReminderService(
      getIt<NotificationService>(),
      getIt<MedicineRepository>(),
    ),
  );

  // Achievement service for gamification
  getIt.registerLazySingleton<AchievementSqfliteRepository>(
    () => AchievementSqfliteRepository(database),
  );
  getIt.registerLazySingleton<AchievementService>(
    () => AchievementService(
      getIt<ProfileService>(),
      getIt<AchievementSqfliteRepository>(),
      getIt<MedicineLogRepository>(),
      getIt<NotificationService>(),
      getIt<PreferencesService>(),
    ),
  );

  // Cubits - Using LazySingleton to ensure single instance across app
  // This ensures all pages use the SAME cubit instance for state synchronization
  getIt.registerLazySingleton<MedicineCubit>(
    () => MedicineCubit(getIt<MedicineRepository>()),
  );

  getIt.registerLazySingleton<MedicineLogCubit>(
    () => MedicineLogCubit(
      getIt<MedicineLogRepository>(),
      getIt<RefillReminderService>(),
      getIt<AchievementService>(),
    ),
  );

  getIt.registerLazySingleton<StatisticsCubit>(
    () => StatisticsCubit(getIt<MedicineLogRepository>()),
  );

  getIt.registerLazySingleton<HistoryCubit>(
    () => HistoryCubit(
      getIt<MedicineLogRepository>(),
      getIt<MedicineRepository>(),
    ),
  );

  getIt.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(getIt<PreferencesService>()),
  );

  // Daily occurrence generation for the next 7 local days
  getIt.registerLazySingleton<DailyLogService>(
    () => DailyLogService(
      getIt<PreferencesService>(),
      getIt<OccurrenceSqfliteGenerator>(),
    ),
  );

  // Generate daily logs at startup
  final dailyLogService = getIt<DailyLogService>();
  await dailyLogService.generateDailyLogsIfNeeded();

  // Check refill reminders at startup
  final refillReminderService = getIt<RefillReminderService>();
  await refillReminderService.checkAndScheduleRefillReminders();

  // Check for new achievements at startup
  final achievementService = getIt<AchievementService>();
  await achievementService.checkAndAwardAchievements();
}

/// Clean up dependencies
Future<void> disposeDependencies() async {
  await getIt<Database>().close();
  await getIt.reset();
}
