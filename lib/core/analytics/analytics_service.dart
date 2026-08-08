import 'package:injectable/injectable.dart';

/// Event tracking wrapper. No-op until an analytics backend is chosen;
/// features should depend on this interface now so wiring a real backend
/// later doesn't touch call sites. Gating by a dedicated remote config flag
/// can be added once a backend (and a flag for it) is chosen.
abstract class AnalyticsService {
  void logEvent(String name, {Map<String, Object?> parameters});
}

@LazySingleton(as: AnalyticsService)
class NoopAnalyticsService implements AnalyticsService {
  @override
  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    // TODO(analytics): forward to the chosen analytics backend.
  }
}
