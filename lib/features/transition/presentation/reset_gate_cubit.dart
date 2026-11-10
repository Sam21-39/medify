import 'package:flutter/foundation.dart';

import 'package:medify/core/transition/legacy_reset.dart';

sealed class ResetGateState {
  const ResetGateState();
}

final class ResetGateChecking extends ResetGateState {
  const ResetGateChecking();
}

final class ResetGateNotice extends ResetGateState {
  const ResetGateNotice();
}

final class ResetGateDeclined extends ResetGateState {
  const ResetGateDeclined();
}

final class ResetGateRunning extends ResetGateState {
  const ResetGateRunning();
}

final class ResetGateFailed extends ResetGateState {
  const ResetGateFailed(this.error, this.retry);

  final Object error;
  final Future<void> Function() retry;
}

/// Drives the reset notice. Plain ValueNotifier, no BLoC.
class ResetGateCubit {
  ResetGateCubit({required this.reset, required this.onComplete});

  final LegacyReset reset;
  final Future<void> Function() onComplete;
  final ValueNotifier<ResetGateState> state = ValueNotifier(
    const ResetGateChecking(),
  );

  Future<void> start() async {
    state.value = const ResetGateChecking();
    try {
      if (await reset.needsReset()) {
        state.value = const ResetGateNotice();
      } else {
        await onComplete();
      }
    } catch (error) {
      state.value = ResetGateFailed(error, start);
    }
  }

  Future<void> continueReset() async {
    state.value = const ResetGateRunning();
    try {
      await reset.run();
      await onComplete();
    } catch (error) {
      state.value = ResetGateFailed(error, continueReset);
    }
  }

  void notNow() => state.value = const ResetGateDeclined();

  void reconsider() => state.value = const ResetGateNotice();
}
