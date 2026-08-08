import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../remote_config/remote_config_service.dart';
import 'app_route.dart';
import 'auth_session_status.dart';

/// Redirects to a sign-in prompt only for routes that declare
/// `requiresAuth: true` — never a blanket app-wide auth wall (Section 8).
@injectable
class AuthGuard {
  AuthGuard(this._sessionStatus);

  final AuthSessionStatus _sessionStatus;

  String? redirect(AppRoute route, GoRouterState state) {
    if (route.requiresAuth && !_sessionStatus.isAuthenticated) {
      return '/sign-in?redirect=${Uri.encodeComponent(state.uri.toString())}';
    }
    return null;
  }
}

/// Redirects away from (or hides entry points to) any route gated by a
/// Remote Config flag that's currently off, so an unfinished screen can
/// exist in the codebase safely ahead of its flag flip (Section 8).
@injectable
class FeatureFlagGuard {
  FeatureFlagGuard(this._remoteConfig);

  final RemoteConfigService _remoteConfig;

  String? redirect(AppRoute route) {
    final flag = route.featureFlag;
    if (flag != null && !_remoteConfig.isEnabled(flag)) {
      return '/';
    }
    return null;
  }
}
