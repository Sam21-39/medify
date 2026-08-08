import '../remote_config/feature_flags.dart';

/// Typed routes, declared centrally — no raw string paths scattered through
/// features (Section 8). Add one entry per screen as features land.
sealed class AppRoute {
  const AppRoute({
    required this.path,
    this.requiresAuth = false,
    this.featureFlag,
  });

  final String path;

  /// Only the specific routes that require it redirect to sign-in — never a
  /// blanket app-wide auth wall.
  final bool requiresAuth;

  /// If set and the flag is off, the feature-flag guard redirects away.
  final FeatureFlag? featureFlag;
}

class HomeRoute extends AppRoute {
  const HomeRoute() : super(path: '/');
}

class CaregiverRoute extends AppRoute {
  const CaregiverRoute()
    : super(
        path: '/caregiver',
        requiresAuth: true,
        featureFlag: FeatureFlag.caregiverAlerts,
      );
}

class AppointmentsRoute extends AppRoute {
  const AppointmentsRoute()
    : super(path: '/appointments', featureFlag: FeatureFlag.appointments);
}

class PrescriptionsRoute extends AppRoute {
  const PrescriptionsRoute()
    : super(path: '/prescriptions', featureFlag: FeatureFlag.prescriptions);
}
