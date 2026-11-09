/// Thrown by plain-value log methods (`addLog`, `updateLog`) when a row with the
/// same (schedule_id, scheduled_at_utc) already exists.
class OccurrenceConflictException implements Exception {
  const OccurrenceConflictException(this.message);

  final String message;

  @override
  String toString() => 'OccurrenceConflictException: $message';
}

/// Thrown by `addLog` when the log's profile or schedule does not match its
/// medicine (the occurrence guard trigger). Kept separate from a duplicate key
/// so callers can tell a bad link from a repeat.
class InvalidOccurrenceException implements Exception {
  const InvalidOccurrenceException(this.message);

  final String message;

  @override
  String toString() => 'InvalidOccurrenceException: $message';
}

/// Thrown by plain-value log methods (`markAsMissed`, `updateLog`) when the current status
/// does not allow the transition.
class InvalidTransitionException implements Exception {
  const InvalidTransitionException(this.message);

  final String message;

  @override
  String toString() => 'InvalidTransitionException: $message';
}
