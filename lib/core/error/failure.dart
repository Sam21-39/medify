import 'package:equatable/equatable.dart';

/// Base type for all domain-facing errors. Every repository method returns
/// `Future<Result<T, Failure>>` instead of throwing, so callers always get a
/// typed error they can branch on (see Section 10 of the architecture doc).
sealed class Failure extends Equatable {
  const Failure({required this.userMessage, this.technicalMessage});

  /// Safe to show directly in the UI.
  final String userMessage;

  /// Raw/technical detail — sent to Crashlytics only, never rendered.
  final String? technicalMessage;

  @override
  List<Object?> get props => [userMessage, technicalMessage];
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.userMessage =
        "You're offline — this will sync once you're back online.",
    super.technicalMessage,
  });
}

class AuthFailure extends Failure {
  const AuthFailure({
    super.userMessage =
        'We could not verify your account. Please sign in again.',
    super.technicalMessage,
  });
}

class SyncConflictFailure extends Failure {
  const SyncConflictFailure({
    super.userMessage = 'Some changes could not be merged automatically.',
    super.technicalMessage,
  });
}

class EncryptionFailure extends Failure {
  const EncryptionFailure({
    super.userMessage = 'Something went wrong protecting your data.',
    super.technicalMessage,
  });
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.userMessage = 'Something went wrong reading your data.',
    super.technicalMessage,
  });
}

class NotificationSchedulingFailure extends Failure {
  const NotificationSchedulingFailure({
    super.userMessage = 'We could not schedule this reminder.',
    super.technicalMessage,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.userMessage = 'Something went wrong — your data is safe locally.',
    super.technicalMessage,
  });
}
