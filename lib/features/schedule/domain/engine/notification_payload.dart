import 'dart:convert';

/// Notification payload `{"installationId": String, "occurrenceId": int}`.
String encodeNotificationPayload({
  required String installationId,
  required int occurrenceId,
}) {
  if (installationId.isEmpty) {
    throw ArgumentError.value(
      installationId,
      'installationId',
      'must be non-empty',
    );
  }
  if (occurrenceId <= 0) {
    throw ArgumentError.value(occurrenceId, 'occurrenceId', 'must be positive');
  }
  return jsonEncode({
    'installationId': installationId,
    'occurrenceId': occurrenceId,
  });
}

sealed class DecodedNotificationPayload {
  const DecodedNotificationPayload();
}

/// Well-formed payload for this installation.
final class Valid extends DecodedNotificationPayload {
  const Valid(this.occurrenceId);
  final int occurrenceId;
}

/// No payload at all (null or empty).
final class Missing extends DecodedNotificationPayload {
  const Missing();
}

/// Not JSON, not an object, or a field missing/of the wrong type/out of range.
final class Malformed extends DecodedNotificationPayload {
  const Malformed();
}

/// Well-formed but for a different installation.
final class Mismatch extends DecodedNotificationPayload {
  const Mismatch();
}

DecodedNotificationPayload decodeNotificationPayload(
  String? raw, {
  required String localInstallationId,
}) {
  if (raw == null || raw.isEmpty) return const Missing();
  final Object? json;
  try {
    json = jsonDecode(raw);
  } on FormatException {
    return const Malformed();
  }
  if (json is! Map<String, Object?>) return const Malformed();
  final installationId = json['installationId'];
  final occurrenceId = json['occurrenceId'];
  if (installationId is! String || installationId.isEmpty) {
    return const Malformed();
  }
  if (occurrenceId is! int || occurrenceId <= 0) return const Malformed();
  if (installationId != localInstallationId) return const Mismatch();
  return Valid(occurrenceId);
}
