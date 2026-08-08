import '../error/failure.dart';
import '../error/result.dart';
import 'reminder_strategy.dart';

/// The single entry point every dose-action surface routes through — in-app
/// button, standard notification, lock-screen action, home widget tap, Live
/// Activity tap. Exactly one place decides "is this dose due, and what
/// happens when acted on," regardless of which surface triggered it
/// (Section 12).
abstract class NotificationScheduler {
  Future<Result<void, NotificationSchedulingFailure>> schedule(
    ReminderStrategy strategy,
  );
  Future<Result<void, NotificationSchedulingFailure>> cancel(String medicineId);
}
