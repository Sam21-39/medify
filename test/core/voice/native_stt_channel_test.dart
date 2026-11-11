import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/voice/native_stt_channel.dart';

void main() {
  test('gate accepts events only while a session is open', () {
    final gate = SttSessionGate();
    expect(gate.accepting, isFalse);

    gate.open();
    expect(gate.accepting, isTrue);

    // Cancel or timeout: a late final must be dropped.
    gate.close();
    expect(gate.accepting, isFalse);

    // A new session accepts events again.
    gate.open();
    expect(gate.accepting, isTrue);
  });
}
