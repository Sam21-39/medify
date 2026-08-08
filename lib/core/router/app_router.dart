import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../widgets/placeholder_home_screen.dart';
import 'app_route.dart';
import 'route_guards.dart';

/// Single navigation system: deep links (notification taps, widget taps,
/// Live Activity taps) resolve through this same route table — no separate
/// ad-hoc handler per entry surface (Section 8).
@lazySingleton
class AppRouter {
  AppRouter(this._authGuard, this._featureFlagGuard);

  final AuthGuard _authGuard;
  final FeatureFlagGuard _featureFlagGuard;

  static final _routesByPath = <String, AppRoute>{
    const HomeRoute().path: const HomeRoute(),
    const CaregiverRoute().path: const CaregiverRoute(),
    const AppointmentsRoute().path: const AppointmentsRoute(),
    const PrescriptionsRoute().path: const PrescriptionsRoute(),
  };

  late final router = GoRouter(
    initialLocation: const HomeRoute().path,
    redirect: (context, state) {
      final route = _routesByPath[state.matchedLocation];
      if (route == null) return null;

      final authRedirect = _authGuard.redirect(route, state);
      if (authRedirect != null) return authRedirect;

      return _featureFlagGuard.redirect(route);
    },
    routes: [
      GoRoute(
        path: const HomeRoute().path,
        builder: (context, state) => const PlaceholderHomeScreen(),
      ),
      // TODO(router): register real feature routes (caregiver/,
      // appointments/, prescriptions/, ...) as those presentation layers
      // land, replacing the placeholder builder above for `/`.
    ],
  );
}
