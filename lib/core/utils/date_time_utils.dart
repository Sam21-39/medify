import 'package:intl/intl.dart';
import '../utils/constants.dart';

enum TimeGroup { morning, afternoon, evening, night }

class DateTimeUtils {
  // Private constructor
  DateTimeUtils._();

  // Format date to full format (e.g., "Monday, November 29, 2024")
  static String formatDateFull(DateTime date) {
    return DateFormat(AppConstants.dateFormatFull).format(date);
  }

  // Format date to short format (e.g., "Nov 29, 2024")
  static String formatDateShort(DateTime date) {
    return DateFormat(AppConstants.dateFormatShort).format(date);
  }

  // Format time to 12-hour format (e.g., "8:00 AM")
  static String formatTime12Hour(DateTime time) {
    return DateFormat(AppConstants.timeFormat12Hour).format(time);
  }

  // Format time to 24-hour format (e.g., "08:00")
  static String formatTime24Hour(DateTime time) {
    return DateFormat(AppConstants.timeFormat24Hour).format(time);
  }

  // Get relative time (e.g., "Today", "Yesterday", "2 days ago")
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return formatDateShort(date);
    }
  }

  // Get time group (Morning, Afternoon, Evening, Night)
  static TimeGroup getTimeGroup(int hour) {
    if (hour >= AppConstants.morningStart && hour < AppConstants.morningEnd) {
      return TimeGroup.morning;
    } else if (hour >= AppConstants.afternoonStart && hour < AppConstants.afternoonEnd) {
      return TimeGroup.afternoon;
    } else if (hour >= AppConstants.eveningStart && hour < AppConstants.eveningEnd) {
      return TimeGroup.evening;
    } else {
      return TimeGroup.night;
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // Check if date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  // Get start of day
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // Get days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Format duration (e.g., "2h 30m", "15m")
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // Get time until (e.g., "In 2 hours", "In 30 minutes")
  static String getTimeUntil(DateTime future) {
    final now = DateTime.now();
    final difference = future.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    }

    if (difference.inDays > 0) {
      return 'In ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Now';
    }
  }

  // Get time ago (e.g., "2 hours ago", "30 minutes ago")
  static String getTimeAgo(DateTime past) {
    final now = DateTime.now();
    final difference = now.difference(past);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Combine date and time
  static DateTime combineDateAndTime(DateTime date, int hour, int minute) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  // Get week start (Monday)
  static DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  // Get week end (Sunday)
  static DateTime getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  // Get month start
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get month end
  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // Check if time is within quiet hours
  static bool isWithinQuietHours(
    DateTime time,
    int? quietStartHour,
    int? quietStartMinute,
    int? quietEndHour,
    int? quietEndMinute,
  ) {
    if (quietStartHour == null || quietEndHour == null) {
      return false;
    }

    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = quietStartHour * 60 + (quietStartMinute ?? 0);
    final endMinutes = quietEndHour * 60 + (quietEndMinute ?? 0);

    if (startMinutes < endMinutes) {
      // Same day quiet hours
      return timeMinutes >= startMinutes && timeMinutes < endMinutes;
    } else {
      // Overnight quiet hours
      return timeMinutes >= startMinutes || timeMinutes < endMinutes;
    }
  }

  // Get next occurrence of time
  static DateTime getNextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);

    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }
}
