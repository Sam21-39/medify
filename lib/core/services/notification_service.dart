import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_log.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../../domain/repositories/medicine_log_repository.dart';
import '../di/injection_container.dart';
import '../utils/date_time_utils.dart';
import 'navigation_service.dart';

/// Service for managing local notifications
/// Handles foreground, background, and terminated app states
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification channel constants
  static const String _channelId = 'medicine_reminders';
  static const String _channelName = 'Medicine Reminders';
  static const String _channelDescription =
      'Notifications for medicine reminders';

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      _log('Notification service already initialized');
      return;
    }

    try {
      _log('Initializing notification service...');

      // Initialize timezone database with local timezone
      tz.initializeTimeZones();
      _setLocalTimezone();

      // Create notification channel for Android
      await _createNotificationChannel();

      // Android initialization settings
      // Use @mipmap/ic_launcher instead of @drawable/ic_notification
      // because vector drawables don't work in release builds for notifications
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        // Critical: This allows notifications to show in foreground on iOS
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin with callbacks
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        // CRITICAL: This handles foreground notifications on Android
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationTapped,
      );

      if (initialized == true) {
        _isInitialized = true;
        _log('Notification service initialized successfully');
      } else {
        _log('Failed to initialize notification service', isError: true);
      }
    } catch (e) {
      _log('Error initializing notification service: $e', isError: true);
      rethrow;
    }
  }

  /// Set timezone to device's local timezone
  void _setLocalTimezone() {
    try {
      // Try to get the device's timezone
      final String timeZoneName = DateTime.now().timeZoneName;
      _log('Device timezone: $timeZoneName');

      // Use a more robust timezone detection
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        _log('Timezone set to: $timeZoneName');
      } catch (e) {
        // Fallback to UTC if device timezone is not found
        _log('Failed to set device timezone, using UTC as fallback');
        tz.setLocalLocation(tz.UTC);
      }
    } catch (e) {
      _log('Error setting timezone: $e', isError: true);
      tz.setLocalLocation(tz.UTC);
    }
  }

  /// Create Android notification channel (required for Android 8.0+)
  Future<void> _createNotificationChannel() async {
    if (!Platform.isAndroid) return;

    try {
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
        _log('Android notification channel created: $_channelId');
      }
    } catch (e) {
      _log('Error creating notification channel: $e', isError: true);
    }
  }

  /// Handle notification tap (when app is in foreground or background)
  void _onNotificationTapped(NotificationResponse response) async {
    _log(
      'Notification tapped: ${response.payload}, action: ${response.actionId}',
    );

    try {
      // Parse payload
      if (response.payload == null || response.payload!.isEmpty) {
        _log('Empty payload, ignoring tap');
        return;
      }

      final Map<String, dynamic> payload = jsonDecode(response.payload!);
      final int medicineId = payload['medicineId'];
      final int scheduledSeconds = payload['scheduledSeconds'];

      // Get medicine log repository
      final medicineLogRepository = getIt<MedicineLogRepository>();

      // Convert scheduledSeconds to DateTime for today
      final scheduledDateTime = DateTimeUtils.secondsToDateTime(
        scheduledSeconds,
      );

      // Find or create today's log for this medicine at this time
      final todayLogs = await medicineLogRepository.getTodayLogs();
      MedicineLog? log = todayLogs.cast<MedicineLog?>().firstWhere(
        (l) =>
            l!.medicineId == medicineId &&
            l.scheduledTime.hour == scheduledDateTime.hour &&
            l.scheduledTime.minute == scheduledDateTime.minute,
        orElse: () => null,
      );

      // Handle different actions
      if (response.actionId == 'snooze') {
        // Snooze action
        await _handleSnoozeAction(medicineId, scheduledSeconds, log);
      } else if (response.actionId == 'skip') {
        // Skip action
        await _handleSkipAction(
          medicineId,
          scheduledSeconds,
          log,
          medicineLogRepository,
        );
      } else {
        // Default tap: Mark as taken and navigate to home
        await _handleTakenAction(
          medicineId,
          scheduledSeconds,
          log,
          medicineLogRepository,
        );

        // Navigate to home page (main navigation page)
        final context = NavigationService().context;
        if (context != null) {
          // Already on main navigation page, just refresh
          _log('Navigating to home page');
        }
      }
    } catch (e) {
      _log('Error handling notification tap: $e', isError: true);
    }
  }

  /// Handle background notification tap (static method required)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(
    NotificationResponse response,
  ) async {
    developer.log(
      'Background notification tapped: ${response.payload}, action: ${response.actionId}',
    );

    try {
      // Parse payload
      if (response.payload == null || response.payload!.isEmpty) {
        developer.log('Empty payload, ignoring tap');
        return;
      }

      final Map<String, dynamic> payload = jsonDecode(response.payload!);
      final int medicineId = payload['medicineId'];
      final int scheduledSeconds = payload['scheduledSeconds'];

      // Get medicine log repository
      final medicineLogRepository = getIt<MedicineLogRepository>();

      // Convert scheduledSeconds to DateTime for today
      final scheduledDateTime = DateTimeUtils.secondsToDateTime(
        scheduledSeconds,
      );

      // Find or create today's log for this medicine at this time
      final todayLogs = await medicineLogRepository.getTodayLogs();
      MedicineLog? log = todayLogs.cast<MedicineLog?>().firstWhere(
        (l) =>
            l!.medicineId == medicineId &&
            l.scheduledTime.hour == scheduledDateTime.hour &&
            l.scheduledTime.minute == scheduledDateTime.minute,
        orElse: () => null,
      );

      // Handle different actions
      if (response.actionId == 'snooze') {
        // Snooze action
        await NotificationService()._handleSnoozeAction(
          medicineId,
          scheduledSeconds,
          log,
        );
      } else if (response.actionId == 'skip') {
        // Skip action
        await NotificationService()._handleSkipAction(
          medicineId,
          scheduledSeconds,
          log,
          medicineLogRepository,
        );
      } else {
        // Default tap: Mark as taken (navigation will happen when app opens)
        await NotificationService()._handleTakenAction(
          medicineId,
          scheduledSeconds,
          log,
          medicineLogRepository,
        );
      }
    } catch (e) {
      developer.log('Error handling background notification tap: $e');
    }
  }

  /// Handle "Mark as Taken" action
  Future<void> _handleTakenAction(
    int medicineId,
    int scheduledSeconds,
    MedicineLog? log,
    MedicineLogRepository medicineLogRepository,
  ) async {
    try {
      if (log != null) {
        // Update existing log
        await medicineLogRepository.markAsTaken(log.id!);
        _log('Marked log ${log.id} as taken');
      } else {
        // Create new log and mark as taken
        // Get medicine to determine profileId
        final medicineRepository = getIt<MedicineRepository>();
        final medicine = await medicineRepository.getMedicineById(medicineId);

        if (medicine == null) {
          _log('Medicine not found: $medicineId', isError: true);
          return;
        }

        final scheduledDateTime = DateTimeUtils.secondsToDateTime(
          scheduledSeconds,
        );
        final newLog = MedicineLog(
          profileId: medicine.profileId,
          medicineId: medicineId,
          scheduledTime: scheduledDateTime,
          takenTime: DateTime.now(),
          status: MedicineLogStatus.taken,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await medicineLogRepository.addLog(newLog);
        _log('Created new log and marked as taken');
      }
    } catch (e) {
      _log('Error handling taken action: $e', isError: true);
    }
  }

  /// Handle "Snooze" action
  Future<void> _handleSnoozeAction(
    int medicineId,
    int scheduledSeconds,
    MedicineLog? log,
  ) async {
    try {
      // Snooze for 5 minutes as per user requirement
      final snoozeDuration = 5; // 5 minutes

      _log('Snoozing notification for $snoozeDuration minutes');

      // Schedule a one-time notification after snooze duration
      final snoozeTime = DateTime.now().add(Duration(minutes: snoozeDuration));
      final tzDateTime = tz.TZDateTime.from(snoozeTime, tz.local);

      // Get medicine name (we'll need to query it)
      // For now, use a generic message
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        // Custom notification sound
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        styleInformation: const BigTextStyleInformation(
          'Don\'t forget to take your medicine!',
        ),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'taken',
            'Mark as Taken',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'skip',
            'Skip',
            showsUserInterface: false,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Create payload
      final payload = jsonEncode({
        'medicineId': medicineId,
        'scheduledSeconds': scheduledSeconds,
        'isSnoozed': true,
      });

      // Generate unique ID for snoozed notification
      final snoozeNotificationId = _generateNotificationId(medicineId, 999);

      await _notifications.zonedSchedule(
        snoozeNotificationId,
        '💊 Reminder: Time to take your medicine',
        'Snoozed reminder',
        tzDateTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      _log('Snoozed notification scheduled for $snoozeTime');
    } catch (e) {
      _log('Error handling snooze action: $e', isError: true);
    }
  }

  /// Handle "Skip" action
  Future<void> _handleSkipAction(
    int medicineId,
    int scheduledSeconds,
    MedicineLog? log,
    MedicineLogRepository medicineLogRepository,
  ) async {
    try {
      if (log != null) {
        // Update existing log
        await medicineLogRepository.markAsSkipped(log.id!);
        _log('Marked log ${log.id} as skipped');
      } else {
        // Create new log and mark as skipped
        // Get medicine to determine profileId
        final medicineRepository = getIt<MedicineRepository>();
        final medicine = await medicineRepository.getMedicineById(medicineId);

        if (medicine == null) {
          _log('Medicine not found: $medicineId', isError: true);
          return;
        }

        final scheduledDateTime = DateTimeUtils.secondsToDateTime(
          scheduledSeconds,
        );
        final newLog = MedicineLog(
          profileId: medicine.profileId,
          medicineId: medicineId,
          scheduledTime: scheduledDateTime,
          takenTime: null,
          status: MedicineLogStatus.skipped,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await medicineLogRepository.addLog(newLog);
        _log('Created new log and marked as skipped');
      }
    } catch (e) {
      _log('Error handling skip action: $e', isError: true);
    }
  }

  /// Request notification permissions (handles Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    try {
      _log('Requesting notification permissions...');

      // Check current permission status
      if (await Permission.notification.isGranted) {
        _log('Notification permission already granted');
        return true;
      }

      // For Android 13+ (API 33+), we need to request POST_NOTIFICATIONS permission
      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();
        if (androidInfo >= 33) {
          _log(
            'Android 13+ detected, requesting POST_NOTIFICATIONS permission',
          );
          final status = await Permission.notification.request();
          _log('Permission status: $status');
          return status.isGranted;
        }
        // For Android < 13, notifications are enabled by default
        _log('Android < 13, notifications enabled by default');
        return true;
      }

      // For iOS, request permission
      if (Platform.isIOS) {
        _log('iOS detected, requesting notification permission');
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          _log('iOS permission granted: $granted');
          return granted ?? false;
        }
      }

      return false;
    } catch (e) {
      _log('Error requesting permissions: $e', isError: true);
      return false;
    }
  }

  /// Get Android SDK version
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      // This is a simplified version - you might need to use
      // device_info_plus package for more accurate detection
      return 33; // Assume Android 13+ for safety
    } catch (e) {
      return 33;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        return await Permission.notification.isGranted;
      } else if (Platform.isIOS) {
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
      return false;
    } catch (e) {
      _log('Error checking notification status: $e', isError: true);
      return false;
    }
  }

  /// Schedule daily notifications for a medicine
  Future<void> scheduleMedicineReminders(
    Medicine medicine, {
    String? profileName,
  }) async {
    if (!medicine.isActive) {
      _log('Medicine ${medicine.name} is inactive, skipping notifications');
      return;
    }

    _log('Scheduling reminders for medicine: ${medicine.name}${profileName != null ? " (Profile: $profileName)" : ""}');

    // Cancel existing notifications for this medicine
    await cancelMedicineReminders(medicine.id!);

    // Schedule notification for each reminder time
    for (int i = 0; i < medicine.reminderTimes.length; i++) {
      final seconds = medicine.reminderTimes[i];
      try {
        await _scheduleDailyNotification(
          medicineId: medicine.id!,
          timeIndex: i,
          seconds: seconds,
          medicineName: medicine.name,
          dosage: medicine.dosage,
          profileName: profileName,
        );
        _log(
          'Scheduled notification ${i + 1}/${medicine.reminderTimes.length} for ${medicine.name}${profileName != null ? " ($profileName)" : ""}',
        );
      } catch (e) {
        _log(
          'Error scheduling notification $i for ${medicine.name}: $e',
          isError: true,
        );
      }
    }
  }

  /// Schedule a single daily notification
  Future<void> _scheduleDailyNotification({
    required int medicineId,
    required int timeIndex,
    required int seconds,
    required String medicineName,
    required String dosage,
    String? profileName,
  }) async {
    try {
      // Generate unique notification ID
      final notificationId = _generateNotificationId(medicineId, timeIndex);

      // Convert seconds to DateTime
      final now = DateTime.now();
      final scheduledTime = DateTimeUtils.secondsToDateTime(seconds);

      // If time has passed today, schedule for tomorrow
      final scheduledDateTime = scheduledTime.isBefore(now)
          ? scheduledTime.add(const Duration(days: 1))
          : scheduledTime;

      // Convert to TZDateTime
      final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

      _log(
        'Scheduling notification ID $notificationId for $medicineName${profileName != null ? " ($profileName)" : ""} at ${DateTimeUtils.formatTime(scheduledDateTime)}',
      );

      // Build notification title and body with profile context
      final String notificationTitle = profileName != null
          ? '💊 Time for $profileName\'s medicine'
          : '💊 Time to take your medicine';

      final String notificationBody = profileName != null
          ? '$medicineName - $dosage • $profileName'
          : '$medicineName - $dosage';

      final String bigText = profileName != null
          ? 'It\'s time for $profileName to take $medicineName ($dosage). Don\'t forget your medicine!'
          : 'It\'s time to take $medicineName ($dosage). Don\'t forget your medicine!';

      // Android notification details with foreground presentation
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        // Custom notification sound
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        playSound: true,
        enableVibration: true,
        // Big text style for better readability
        styleInformation: BigTextStyleInformation(bigText),
        // Action buttons: Snooze (5 mins) and Skip
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'snooze',
            'Snooze (5 min)',
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            'skip',
            'Skip',
            showsUserInterface: false,
          ),
        ],
        // Full screen intent for critical reminders
        fullScreenIntent: true,
        // Show notification even when app is in foreground
        visibility: NotificationVisibility.public,
        ticker: profileName != null
            ? 'Time for $profileName: $medicineName'
            : 'Time to take $medicineName',
      );

      // iOS notification details with foreground presentation
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Custom notification sound (iOS uses the default sound in assets)
        sound: 'notification_sound.mp3',
        badgeNumber: 1,
        subtitle: profileName != null ? '$profileName\'s Medicine' : 'Medicine Reminder',
        // iOS 10+ allows notifications to show in foreground
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Create payload with medicineId and scheduled time
      final payload = jsonEncode({
        'medicineId': medicineId,
        'scheduledSeconds': seconds,
      });

      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        notificationTitle,
        notificationBody,
        tzDateTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: payload,
      );

      _log('Notification scheduled successfully: ID $notificationId');
    } catch (e) {
      _log('Error in _scheduleDailyNotification: $e', isError: true);
      rethrow;
    }
  }

  /// Cancel all reminders for a medicine
  Future<void> cancelMedicineReminders(int medicineId) async {
    try {
      _log('Canceling reminders for medicine ID: $medicineId');
      // Cancel all possible notification IDs for this medicine
      // Assuming max 10 reminder times per medicine
      for (int i = 0; i < 10; i++) {
        final notificationId = _generateNotificationId(medicineId, i);
        await _notifications.cancel(notificationId);
      }
      _log('Canceled reminders for medicine ID: $medicineId');
    } catch (e) {
      _log('Error canceling medicine reminders: $e', isError: true);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      _log('Canceling all notifications');
      await _notifications.cancelAll();
      _log('All notifications canceled');
    } catch (e) {
      _log('Error canceling all notifications: $e', isError: true);
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      _log('Found ${pending.length} pending notifications');
      return pending;
    } catch (e) {
      _log('Error getting pending notifications: $e', isError: true);
      return [];
    }
  }

  /// Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      _log('Showing immediate notification: $title');

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        // Custom notification sound
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        playSound: true,
        enableVibration: true,
        // Show notification even when app is in foreground
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.mp3',
        interruptionLevel: InterruptionLevel.active,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000, // Random ID
        title,
        body,
        details,
        payload: payload,
      );

      _log('Immediate notification shown successfully');
    } catch (e) {
      _log('Error showing immediate notification: $e', isError: true);
    }
  }

  /// Generate unique notification ID from medicine ID and time index
  int _generateNotificationId(int medicineId, int timeIndex) {
    // Combine medicine ID and time index to create unique ID
    // Format: medicineId * 100 + timeIndex
    // This allows up to 100 reminder times per medicine
    return (medicineId * 100) + timeIndex;
  }

  /// Get notification ID for a specific medicine and time
  int getNotificationId(int medicineId, int timeIndex) {
    return _generateNotificationId(medicineId, timeIndex);
  }

  /// Reschedule all active medicine reminders
  Future<void> rescheduleAllReminders(List<Medicine> medicines) async {
    try {
      _log('Rescheduling reminders for ${medicines.length} medicines');
      await cancelAllNotifications();

      int scheduled = 0;
      for (final medicine in medicines) {
        if (medicine.isActive) {
          await scheduleMedicineReminders(medicine);
          scheduled++;
        }
      }

      _log('Rescheduled reminders for $scheduled active medicines');
    } catch (e) {
      _log('Error rescheduling reminders: $e', isError: true);
    }
  }

  /// Log helper for debugging
  void _log(String message, {bool isError = false}) {
    if (isError) {
      developer.log(
        message,
        name: 'NotificationService',
        level: 1000, // Error level
      );
    } else {
      developer.log(
        message,
        name: 'NotificationService',
        level: 500, // Info level
      );
    }
  }

  /// Get notification statistics (for debugging)
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final pending = await getPendingNotifications();
      return {
        'isInitialized': _isInitialized,
        'pendingCount': pending.length,
        'pendingNotifications': pending
            .map(
              (n) => {
                'id': n.id,
                'title': n.title,
                'body': n.body,
                'payload': n.payload,
              },
            )
            .toList(),
        'timezone': tz.local.name,
      };
    } catch (e) {
      _log('Error getting notification stats: $e', isError: true);
      return {'error': e.toString()};
    }
  }
}
