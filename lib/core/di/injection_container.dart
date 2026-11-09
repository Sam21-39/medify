import 'package:get_it/get_it.dart';
import 'package:medify/core/services/permission_service.dart';
import 'package:medify/core/services/system_service.dart';
import '../../data/datasources/objectbox_service.dart';
import '../../data/repositories/medicine_repository_impl.dart';
import '../../data/repositories/medicine_log_repository_impl.dart';
// import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../../domain/repositories/medicine_log_repository.dart';
// import '../../domain/repositories/user_profile_repository.dart';
import '../../presentation/blocs/medicine/medicine_cubit.dart';
import '../../presentation/blocs/medicine_log/medicine_log_cubit.dart';
import '../../presentation/blocs/settings/settings_cubit.dart';
import '../../presentation/blocs/statistics/statistics_cubit.dart';
import '../../presentation/blocs/history/history_cubit.dart';
// import '../../presentation/blocs/profile/profile_cubit.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/daily_log_service.dart';
import '../services/refill_reminder_service.dart';
import '../services/achievement_service.dart';
// import '../services/profile_service.dart';

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

  // COMMENTED OUT FOR UPCOMING RELEASE - Profile service (needs to be before repositories)
  // getIt.registerLazySingleton<ProfileService>(
  //   () =>
  //       ProfileService(getIt<ObjectBoxService>(), getIt<PreferencesService>()),
  // );

  // // Initialize profile service (creates default profile if needed)
  // final profileService = getIt<ProfileService>();
  // await profileService.initialize();

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
    () => RefillReminderService(getIt<NotificationService>(), getIt<MedicineRepository>()),
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
  getIt.registerLazySingleton<MedicineCubit>(() => MedicineCubit(getIt<MedicineRepository>()));

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
    () => HistoryCubit(getIt<MedicineLogRepository>(), getIt<MedicineRepository>()),
  );

  getIt.registerLazySingleton<SettingsCubit>(() => SettingsCubit(getIt<PreferencesService>()));

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
