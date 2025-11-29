class AppConstants {
  // Private constructor
  AppConstants._();
  
  // App Info
  static const String appName = 'Medify';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Never miss a medication dose again';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String medicationsCollection = 'medications';
  static const String doseLogsCollection = 'doseLogs';
  
  // Shared Preferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyRememberMe = 'remember_me';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyThemeMode = 'theme_mode';
  
  // Medication Units
  static const List<String> medicationUnits = [
    'mg',
    'ml',
    'tablet',
    'capsule',
    'drops',
    'puff',
    'unit',
  ];
  
  // Time Groups
  static const String timeMorning = 'Morning';
  static const String timeAfternoon = 'Afternoon';
  static const String timeEvening = 'Evening';
  static const String timeNight = 'Night';
  
  // Time Group Hours
  static const int morningStart = 6;
  static const int morningEnd = 12;
  static const int afternoonStart = 12;
  static const int afternoonEnd = 17;
  static const int eveningStart = 17;
  static const int eveningEnd = 21;
  static const int nightStart = 21;
  static const int nightEnd = 6;
  
  // Snooze Durations (in minutes)
  static const List<int> snoozeDurations = [5, 10, 15, 30];
  
  // Default Refill Threshold
  static const int defaultRefillThreshold = 5;
  
  // Notification Channels
  static const String notificationChannelId = 'medication_reminders';
  static const String notificationChannelName = 'Medication Reminders';
  static const String notificationChannelDescription = 'Notifications for medication reminders';
  
  // Notification Actions
  static const String actionTakeNow = 'TAKE_NOW';
  static const String actionSnooze = 'SNOOZE';
  static const String actionSkip = 'SKIP';
  
  // Date Formats
  static const String dateFormatFull = 'EEEE, MMMM d, y';
  static const String dateFormatShort = 'MMM d, y';
  static const String timeFormat12Hour = 'h:mm a';
  static const String timeFormat24Hour = 'HH:mm';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxInstructionsLength = 200;
  
  // Pagination
  static const int historyPageSize = 20;
  static const int medicationsPageSize = 50;
  
  // Sync
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxSyncRetries = 3;
}
