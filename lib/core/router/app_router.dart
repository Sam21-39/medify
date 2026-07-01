import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/app_shell/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/otp_verify_page.dart';
import '../../features/auth/presentation/pages/phone_entry_page.dart';
import '../../features/home/presentation/pages/home_placeholder_page.dart';
import '../../features/onboarding/presentation/cubit/consent_cubit.dart';
import '../../features/onboarding/presentation/pages/consent_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_carousel_page.dart';
import '../di/injection.dart';
import 'go_router_refresh_stream.dart';

GoRouter buildAppRouter() {
  final authCubit = getIt<AuthCubit>();
  final consentCubit = getIt<ConsentCubit>();

  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(authCubit.stream),
      GoRouterRefreshStream(consentCubit.stream),
    ]),
    redirect: (context, state) {
      final path = state.matchedLocation;
      final authState = authCubit.state;
      const publicOnboardingAuthPaths = {
        '/onboarding',
        '/auth/phone',
        '/auth/otp',
      };

      if (authState is AuthInitial) {
        return path == '/' ? null : '/';
      }

      if (authState is! AuthAuthenticated) {
        return publicOnboardingAuthPaths.contains(path) ? null : '/onboarding';
      }

      // Authenticated from here on.
      final consentState = consentCubit.state;
      if (consentState is ConsentInitial) {
        consentCubit.checkConsent(authState.user.uid);
        return path == '/' ? null : '/';
      }
      if (consentState is ConsentChecking) {
        return path == '/' ? null : '/';
      }
      if (consentState is ConsentRequired) {
        return path == '/onboarding/consent' ? null : '/onboarding/consent';
      }

      // ConsentGranted.
      if (path == '/home') return null;
      return '/home';
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingCarouselPage(),
      ),
      GoRoute(
        path: '/onboarding/consent',
        builder: (context, state) {
          final authState = authCubit.state;
          final uid = authState is AuthAuthenticated ? authState.user.uid : '';
          return ConsentPage(uid: uid);
        },
      ),
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneEntryPage(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) =>
            OtpVerifyPage(otpSent: state.extra! as AuthOtpSent),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePlaceholderPage(),
      ),
    ],
  );
}
