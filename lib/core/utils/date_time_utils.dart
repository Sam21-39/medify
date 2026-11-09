import 'package:intl/intl.dart';

/// Time period of the day
enum TimeOfDayPeriod {
  morning, // 5 AM - 12 PM
  afternoon, // 12 PM - 5 PM
  evening, // 5 PM - 9 PM
  night; // 9 PM - 5 AM

  String get label {
    switch (this) {
      case TimeOfDayPeriod.morning:
        return 'Morning';
      case TimeOfDayPeriod.afternoon:
        return 'Afternoon';
      case TimeOfDayPeriod.evening:
        return 'Evening';
      case TimeOfDayPeriod.night:
        return 'Night';
    }
  }

  String get emoji {
    switch (this) {
      case TimeOfDayPeriod.morning:
        return '☀️';
      case TimeOfDayPeriod.afternoon:
        return '🌤️';
      case TimeOfDayPeriod.evening:
        return '🌙';
      case TimeOfDayPeriod.night:
        return '🌃';
    }
  }

  String get timeRange {
    switch (this) {
      case TimeOfDayPeriod.morning:
        return '5 AM - 12 PM';
      case TimeOfDayPeriod.afternoon:
        return '12 PM - 5 PM';
      case TimeOfDayPeriod.evening:
        return '5 PM - 9 PM';
      case TimeOfDayPeriod.night:
        return '9 PM - 5 AM';
    }
  }
}

/// Utility class for date and time operations
class DateTimeUtils {
  DateTimeUtils._();

  /// Format date as "MMM dd, yyyy" (e.g., "Jan 15, 2024")
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format time as "hh:mm a" (e.g., "09:30 AM")
  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  /// Format date and time as "MMM dd, yyyy hh:mm a"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  /// Convert seconds since midnight to DateTime for today
  static DateTime secondsToDateTime(int seconds) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return startOfDay.add(Duration(seconds: seconds));
  }

  /// Convert DateTime to seconds since midnight
  static int dateTimeToSeconds(DateTime dateTime) {
    final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return dateTime.difference(startOfDay).inSeconds;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get relative date string (Today, Tomorrow, Yesterday, or formatted date)
  static String getRelativeDateString(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else {
      return formatDate(date);
    }
  }

  /// Get start of day
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get time of day string (Morning, Afternoon, Evening, Night)
  static String getTimeOfDayString(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) {
      return 'Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }

  /// Get time of day period enum
  static TimeOfDayPeriod getTimeOfDayPeriod(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) {
      return TimeOfDayPeriod.morning;
    } else if (hour >= 12 && hour < 17) {
      return TimeOfDayPeriod.afternoon;
    } else if (hour >= 17 && hour < 21) {
      return TimeOfDayPeriod.evening;
    } else {
      return TimeOfDayPeriod.night;
    }
  }

  /// Group items by time of day period
  static Map<TimeOfDayPeriod, List<T>> groupByTimeOfDay<T>(
    List<T> items,
    DateTime Function(T) getDateTime,
  ) {
    final Map<TimeOfDayPeriod, List<T>> grouped = {};

    for (final item in items) {
      final dateTime = getDateTime(item);
      final period = getTimeOfDayPeriod(dateTime);
      grouped.putIfAbsent(period, () => []);
      grouped[period]!.add(item);
    }

    return grouped;
  }
}
