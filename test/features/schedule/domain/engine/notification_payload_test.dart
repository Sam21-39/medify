import 'package:flutter_test/flutter_test.dart';
import 'package:medify/features/schedule/domain/engine/notification_payload.dart';

void main() {
  const local = 'install-A';

  test('valid payload round-trips', () {
    final raw = encodeNotificationPayload(
      installationId: local,
      occurrenceId: 42,
    );
    final decoded = decodeNotificationPayload(raw, localInstallationId: local);
    expect(decoded, isA<Valid>());
    expect((decoded as Valid).occurrenceId, 42);
  });

  test('null or empty payload is Missing', () {
    expect(
      decodeNotificationPayload(null, localInstallationId: local),
      isA<Missing>(),
    );
    expect(
      decodeNotificationPayload('', localInstallationId: local),
      isA<Missing>(),
    );
  });

  test('missing field is Malformed', () {
    expect(
      decodeNotificationPayload(
        '{"installationId":"install-A"}',
        localInstallationId: local,
      ),
      isA<Malformed>(),
    );
  });

  test('malformed JSON is Malformed', () {
    expect(
      decodeNotificationPayload('{not json', localInstallationId: local),
      isA<Malformed>(),
    );
    expect(
      decodeNotificationPayload('[1,2]', localInstallationId: local),
      isA<Malformed>(),
    );
  });

  test('wrong installationId is Mismatch', () {
    expect(
      decodeNotificationPayload(
        '{"installationId":"install-B","occurrenceId":7}',
        localInstallationId: local,
      ),
      isA<Mismatch>(),
    );
  });

  test('zero occurrenceId is Malformed', () {
    expect(
      decodeNotificationPayload(
        '{"installationId":"install-A","occurrenceId":0}',
        localInstallationId: local,
      ),
      isA<Malformed>(),
    );
  });

  test('empty installationId is Malformed', () {
    expect(
      decodeNotificationPayload(
        '{"installationId":"","occurrenceId":3}',
        localInstallationId: local,
      ),
      isA<Malformed>(),
    );
  });
}
