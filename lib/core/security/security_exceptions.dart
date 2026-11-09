/// The secure store could not be read or written. Never treated as "no key".
class KeyStoreUnavailable implements Exception {
  const KeyStoreUnavailable(this.message);

  final String message;

  @override
  String toString() => 'KeyStoreUnavailable: $message';
}

/// The database holds encrypted rows but the key is missing. The key is
/// never regenerated automatically.
class KeyMismatch implements Exception {
  const KeyMismatch(this.message);

  final String message;

  @override
  String toString() => 'KeyMismatch: $message';
}

/// A stored encrypted value failed the format or authentication check.
class CorruptField implements Exception {
  const CorruptField(this.message);

  final String message;

  @override
  String toString() => 'CorruptField: $message';
}
