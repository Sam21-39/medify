import 'package:flutter_test/flutter_test.dart';

import 'package:medify/core/transition/legacy_reset.dart';
import 'package:medify/features/transition/presentation/reset_gate_cubit.dart';

void main() {
  // Nothing exists under these paths, so no reset is needed and start()
  // goes straight to onComplete.
  LegacyReset missingReset() => LegacyReset(
    documentsDir: '/nonexistent_medify_docs',
    legacyDocumentsDir: '/nonexistent_medify_legacy',
    v2DatabasePath: '/nonexistent_medify_v2.db',
    cancelReminders: () async {},
  );

  test('onComplete failure surfaces as ResetGateFailed', () async {
    final cubit = ResetGateCubit(
      reset: missingReset(),
      onComplete: () async => throw StateError('launch failed'),
    );
    await cubit.start();
    expect(cubit.state.value, isA<ResetGateFailed>());
  });

  test('onComplete is awaited before start completes', () async {
    var completed = false;
    final cubit = ResetGateCubit(
      reset: missingReset(),
      onComplete: () async {
        await Future<void>.delayed(Duration.zero);
        completed = true;
      },
    );
    await cubit.start();
    expect(completed, isTrue);
  });
}
