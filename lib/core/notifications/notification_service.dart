import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:medify/core/database/enums.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/ui/app_messenger.dart';
import 'package:medify/core/utils/date_time_utils.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:medify/features/schedule/domain/engine/notification_payload.dart';
import 'package:medify/features/schedule/domain/entities/medicine_log.dart';
import 'package:medify/features/schedule/domain/repositories/medicine_log_repository.dart';

/// Service for managing local notifications
/// Handles foreground, background, and terminated app states
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _installationId;
  Future<String>? _installationIdLoad;
  Future<void> _rescheduleChain = Future.value();

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
        requestCriticalPermission: true,
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
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        // CRITICAL: This handles foreground notifications on Android
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationTapped,
      );

      if (initialized == true) {
        _isInitialized = true;
        if (Platform.isAndroid) {
          final androidPlugin = _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          await androidPlugin?.requestFullScreenIntentPermission();
        }
        _log('Notification service initialized successfully');
      } else {
        _log('Failed to initialize notification service', isError: true);
      }
    } catch (e) {
      _log('Error initializing notification service: $e', isError: true);
      rethrow;
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
        importance: Importance.max,
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
        const priorChannel = AndroidNotificationChannel(
          'medify_prior',
          'Upcoming dose',
          description: '15 minutes before a dose',
          importance: Importance.low,
        );
        await androidPlugin.createNotificationChannel(priorChannel);
        _log('Android notification channel created: $_channelId');
      }
    } catch (e) {
      _log('Error creating notification channel: $e', isError: true);
    }
  }

  /// Handle notification tap (foreground and background). Only a well-formed
  /// payload for this installation is acted on.
  void _onNotificationTapped(NotificationResponse response) =>
      _handleResponse(response);

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) =>
      NotificationService()._handleResponse(response);

  Future<void> _handleResponse(NotificationResponse response) async {
    _log(
      'Notification tapped: ${response.payload}, action: ${response.actionId}',
    );
    try {
      final decoded = decodeNotificationPayload(
        response.payload,
        localInstallationId: await _installationIdFor(),
      );
      final occurrenceId = switch (decoded) {
        Valid(:final occurrenceId) => occurrenceId,
        _ => null,
      };
      if (occurrenceId == null) {
        _log('Ignoring notification tap: ${decoded.runtimeType}');
        return;
      }

      final logRepository = getIt<MedicineLogRepository>();
      final log = await logRepository.getLogById(occurrenceId);
      if (log == null) {
        _log('Occurrence $occurrenceId not found, ignoring tap', isError: true);
        return;
      }

      if (response.actionId == 'snooze') {
        await _handleSnoozeAction(log);
      } else if (response.actionId == 'skip') {
        final result = await logRepository.markAsSkipped(occurrenceId);
        result.fold(
          (failure) => _log(
            'Skip failed for occurrence $occurrenceId: ${failure.message}',
            isError: true,
          ),
          (_) => _log('Marked occurrence $occurrenceId as skipped'),
        );
      } else {
        final seconds = DateTimeUtils.dateTimeToSeconds(log.scheduledTime);
        getIt<AppMessenger>().go(
          '/alarm?medicineId=${log.medicineId}&seconds=$seconds',
        );
      }
    } catch (e) {
      _log('Error handling notification tap: $e', isError: true);
    }
  }

  /// Handle "Snooze" action: one-off reminder in 5 minutes for the same occurrence
  Future<void> _handleSnoozeAction(MedicineLog log) async {
    try {
      final when = DateTime.now().add(const Duration(minutes: 5));
      final payload = encodeNotificationPayload(
        installationId: await _installationIdFor(),
        occurrenceId: log.id!,
      );
      await _notifications.zonedSchedule(
        id: _snoozeId(log.id!),
        title: '💊 Reminder: Time to take your medicine',
        body: 'Snoozed reminder',
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: _reminderDetails(
          bigText: 'Don\'t forget to take your medicine!',
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      _log('Snoozed notification scheduled for $when');
    } catch (e) {
      _log('Error handling snooze action: $e', isError: true);
    }
  }

  /// Installation ID: random, created once, stored in installation_metadata.
  /// Concurrent callers share one in-flight load.
  Future<String> _installationIdFor() async {
    final cached = _installationId;
    if (cached != null) return cached;
    final load = _installationIdLoad ??= _loadInstallationId();
    try {
      return await load;
    } finally {
      _installationIdLoad = null;
    }
  }

  Future<String> _loadInstallationId() async {
    final db = getIt<Database>();
    final rows = await db.query(
      'installation_metadata',
      columns: ['installation_id'],
      where: 'id = 1',
    );
    final id = rows.isNotEmpty
        ? rows.first['installation_id']! as String
        : await _createInstallationRow(db);
    _installationId = id;
    return id;
  }

  Future<String> _createInstallationRow(Database db) async {
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await db.insert('installation_metadata', {
      'id': 1,
      'installation_id': id,
      'lifecycle': LifecycleState.complete.name,
      'created_at_utc': DateTime.now().toUtc().millisecondsSinceEpoch,
    });
    return id;
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
            critical: true,
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
            critical: true,
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

  /// Schedule one-off reminders for the pending occurrences of [medicine]
  Future<void> scheduleMedicineReminders(
    Medicine medicine, {
    String? profileName,
  }) async {
    if (!medicine.isActive) {
      _log('Medicine ${medicine.name} is inactive, skipping notifications');
      return;
    }
    _log('Scheduling reminders for medicine: ${medicine.name}');

    final now = DateTime.now();
    final logs = await getIt<MedicineLogRepository>().getLogsByMedicineId(
      medicine.id!,
    );
    await _cancelForReschedule(logs);
    for (final log in logs) {
      if (log.id == null ||
          log.status != MedicineLogStatus.pending ||
          !log.scheduledTime.isAfter(now)) {
        continue;
      }
      try {
        await _scheduleOccurrence(
          log: log,
          medicineName: medicine.name,
          dosage: medicine.dosage,
          profileName: profileName,
        );
      } catch (e) {
        _log('Error scheduling occurrence ${log.id}: $e', isError: true);
      }
    }
  }

  /// Schedule the reminder and the 15-minute prior notice for one occurrence
  Future<void> _scheduleOccurrence({
    required MedicineLog log,
    required String medicineName,
    required String dosage,
    String? profileName,
  }) async {
    final occurrenceId = log.id!;
    final when = tz.TZDateTime.from(log.scheduledTime, tz.local);
    final payload = encodeNotificationPayload(
      installationId: await _installationIdFor(),
      occurrenceId: occurrenceId,
    );
    final title = profileName != null
        ? '💊 Time for $profileName\'s medicine'
        : '💊 Time to take your medicine';
    final body = profileName != null
        ? '$medicineName - $dosage • $profileName'
        : '$medicineName - $dosage';
    final bigText = profileName != null
        ? 'It\'s time for $profileName to take $medicineName ($dosage). Don\'t forget your medicine!'
        : 'It\'s time to take $medicineName ($dosage). Don\'t forget your medicine!';

    await _notifications.zonedSchedule(
      id: _mainId(occurrenceId),
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: _reminderDetails(bigText: bigText),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    final prior = when.subtract(const Duration(minutes: 15));
    if (!prior.isAfter(tz.TZDateTime.now(tz.local))) return;
    final timeLabel = DateTimeUtils.formatTime(when);
    final androidDetails = AndroidNotificationDetails(
      'medify_prior',
      'Upcoming dose',
      channelDescription: '15 minutes before a dose',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      chronometerCountDown: true,
      when: when.millisecondsSinceEpoch,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    await _notifications.zonedSchedule(
      id: _priorId(occurrenceId),
      title: 'Medicine $medicineName at $timeLabel.',
      body: 'In 15 minutes',
      scheduledDate: prior,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    _log('Scheduled occurrence $occurrenceId at $timeLabel');
  }

  NotificationDetails _reminderDetails({required String bigText}) {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      icon: '@mipmap/ic_launcher',
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(bigText),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'snooze',
          'Snooze (5 min)',
          showsUserInterface: true,
        ),
        AndroidNotificationAction('skip', 'Skip', showsUserInterface: true),
      ],
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.mp3',
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.critical,
    );
    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Cancel only what is about to be rescheduled: reminder and prior notice for
  /// pending occurrences. A snooze stays scheduled while its occurrence is
  /// pending; it is cancelled once the occurrence leaves pending.
  Future<void> _cancelForReschedule(List<MedicineLog> logs) async {
    for (final log in logs) {
      if (log.id == null) continue;
      if (log.status == MedicineLogStatus.pending) {
        await _notifications.cancel(id: _mainId(log.id!));
        await _notifications.cancel(id: _priorId(log.id!));
      } else {
        await _notifications.cancel(id: _snoozeId(log.id!));
      }
    }
  }

  /// Cancel the reminder, prior notice and snooze for every occurrence of a medicine
  Future<void> cancelMedicineReminders(int medicineId) async {
    try {
      _log('Canceling reminders for medicine ID $medicineId');
      final logs = await getIt<MedicineLogRepository>().getLogsByMedicineId(
        medicineId,
      );
      for (final log in logs) {
        if (log.id == null) continue;
        await _notifications.cancel(id: _mainId(log.id!));
        await _notifications.cancel(id: _priorId(log.id!));
        await _notifications.cancel(id: _snoozeId(log.id!));
      }
      _log('Canceled reminders for medicine ID $medicineId');
    } catch (e) {
      _log('Error canceling medicine reminders $e', isError: true);
    }
  }

  /// Cancel all reminders, then schedule pending occurrences of active medicines.
  /// Run after the occurrence window is generated (startup, resume).
  /// Runs are queued, so overlapping calls never interleave.
  Future<void> rescheduleUpcoming() {
    final next = _rescheduleChain.then((_) => _rescheduleOnce());
    _rescheduleChain = next;
    return next;
  }

  Future<void> _rescheduleOnce() async {
    try {
      final medicines = (await getIt<MedicineRepository>().getActiveMedicines())
          .unwrap();
      for (final medicine in medicines) {
        await scheduleMedicineReminders(medicine);
      }
      _log('Rescheduled reminders for ${medicines.length} active medicines');
    } catch (e) {
      _log('Error rescheduling reminders $e', isError: true);
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
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
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
        id: 0x40000000 + (DateTime.now().millisecondsSinceEpoch % 0x0FFFFFFF),
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );

      _log('Immediate notification shown successfully');
    } catch (e) {
      _log('Error showing immediate notification: $e', isError: true);
    }
  }

  // Notification IDs derive from the occurrence ID: reminder, prior, snooze.
  static int _mainId(int occurrenceId) => occurrenceId * 4;
  static int _priorId(int occurrenceId) => occurrenceId * 4 + 1;
  static int _snoozeId(int occurrenceId) => occurrenceId * 4 + 2;

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
