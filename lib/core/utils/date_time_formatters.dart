/// Shared date/time formatting — features format dose times, appointment
/// times, etc. through here so display format stays consistent app-wide.
class DateTimeFormatters {
  const DateTimeFormatters._();

  static String time24h(DateTime dateTime) =>
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  static String isoDate(DateTime dateTime) =>
      '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}
