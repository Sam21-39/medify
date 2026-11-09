import 'package:get_it/get_it.dart';
import 'package:medify/core/permissions/permission_service.dart';
import 'package:medify/core/system/system_service.dart';

import 'package:medify/core/database/objectbox_service.dart';
import 'package:medify/features/medicines/data/repositories/medicine_repository_impl.dart';
import 'package:medify/features/schedule/data/repositories/medicine_log_repository_impl.dart';
// import 'package:medify/features/profiles/data/repositories/user_profile_repository_impl.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:medify/features/schedule/domain/repositories/medicine_log_repository.dart';
// import 'package:medify/features/profiles/domain/repositories/user_profile_repository.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_cubit.dart';
import 'package:medify/features/schedule/presentation/cubit/medicine_log_cubit.dart';
import 'package:medify/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:medify/features/statistics/presentation/cubit/statistics_cubit.dart';
import 'package:medify/features/history/presentation/cubit/history_cubit.dart';
// import 'package:medify/features/profiles/presentation/cubit/profile_cubit.dart';
import 'package:medify/core/notifications/notification_service.dart';
import 'package:medify/core/preferences/preferences_service.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/core/voice/reminder_voice.dart';
import 'package:medify/features/profiles/data/repositories/care_link_repository.dart';
import 'package:medify/features/profiles/data/services/profile_service.dart';
import 'package:medify/features/schedule/data/services/daily_log_service.dart';
import 'package:medify/features/schedule/data/services/refill_reminder_service.dart';
import 'package:medify/features/achievements/data/services/achievement_service.dart';

/// Service locator instance
final getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> initializeDependencies() async {
  // Initialize preferences service
  final preferencesService = await PreferencesService.initialize();
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

  // Data sources
  final objectBoxService = ObjectBoxService();
  await objectBoxService.init();
  getIt.registerSingleton<ObjectBoxService>(objectBoxService);

  getIt.registerLazySingleton<ProfileService>(
    () =>
        ProfileService(getIt<ObjectBoxService>(), getIt<PreferencesService>()),
  );
  await getIt<ProfileService>().initialize();

  getIt.registerLazySingleton<CareLinkRepository>(
    () => CareLinkRepository(getIt<ObjectBoxService>()),
  );
  getIt.registerLazySingleton<AppMessenger>(AppMessenger.new);
  getIt.registerLazySingleton<ReminderVoice>(ReminderVoice.new);

  // Repositories
  getIt.registerLazySingleton<MedicineRepository>(
    () => MedicineRepositoryImpl(getIt<ObjectBoxService>()),
  );

  getIt.registerLazySingleton<MedicineLogRepository>(
    () => MedicineLogRepositoryImpl(getIt<ObjectBoxService>()),
  );

  // COMMENTED OUT FOR UPCOMING RELEASE - User Profile Repository
  // getIt.registerLazySingleton<UserProfileRepository>(
  //   () => UserProfileRepositoryImpl(getIt<ProfileService>()),
  // );

  // Refill reminder service for medicine stock tracking
  // Register before cubits that depend on it
  getIt.registerLazySingleton<RefillReminderService>(
    () => RefillReminderService(
      getIt<NotificationService>(),
      getIt<MedicineRepository>(),
    ),
  );

  // Achievement service for gamification
  getIt.registerLazySingleton<AchievementService>(
    () => AchievementService(
      getIt<ObjectBoxService>(),
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

  // COMMENTED OUT FOR UPCOMING RELEASE - ProfileCubit
  // CRITICAL: ProfileCubit MUST be LazySingleton, not Factory
  // Factory creates a new instance every time, breaking state synchronization
  // getIt.registerLazySingleton<ProfileCubit>(
  //   () => ProfileCubit(getIt<UserProfileRepository>()),
  // );

  // Daily log service for generating repeating reminder logs
  getIt.registerLazySingleton<DailyLogService>(
    () => DailyLogService(
      getIt<PreferencesService>(),
      getIt<MedicineRepository>(),
      getIt<MedicineLogRepository>(),
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
  final objectBoxService = getIt<ObjectBoxService>();
  objectBoxService.close();
  await getIt.reset();
}
