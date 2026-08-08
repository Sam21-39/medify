import 'package:injectable/injectable.dart';

/// Started when a dose becomes due, updated in place, ended automatically
/// on action or timeout — driven by the notification scheduler's event
/// stream, not a parallel timer (Section 12). iOS side needs ActivityKit
/// entitlements + a widget extension target; Android side is a foreground-
/// service-backed ongoing notification. Neither native target exists yet,
/// so this is a no-op stub.
abstract class LiveActivityService {
  Future<void> start({required String medicineId, required DateTime dueAt});
  Future<void> update({required String medicineId});
  Future<void> end({required String medicineId});
}

@LazySingleton(as: LiveActivityService)
class NoopLiveActivityService implements LiveActivityService {
  @override
  Future<void> start({
    required String medicineId,
    required DateTime dueAt,
  }) async {
    // TODO(live-activity): iOS ActivityKit bridge + Android foreground
    // service, gated behind `feature_live_activity` remote config flag.
  }

  @override
  Future<void> update({required String medicineId}) async {}

  @override
  Future<void> end({required String medicineId}) async {}
}
