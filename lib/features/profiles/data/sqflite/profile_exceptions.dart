/// Thrown by plain-value profile and care-link methods when input breaks a rule
/// (unknown role, self-link, duplicate link, empty ID on update).
class InvalidProfileException implements Exception {
  const InvalidProfileException(this.message);

  final String message;

  @override
  String toString() => 'InvalidProfileException: $message';
}

/// Thrown when a referenced profile does not exist.
class ProfileNotFoundException implements Exception {
  const ProfileNotFoundException(this.profileId);

  final int profileId;

  @override
  String toString() => 'ProfileNotFoundException: profile $profileId';
}
