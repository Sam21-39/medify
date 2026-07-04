import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/di/injection.dart';
import 'package:medify/core/router/app_router.dart';
import 'package:medify/features/auth/domain/repositories/auth_repository.dart';
import 'package:medify/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:medify/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:medify/features/onboarding/presentation/cubit/consent_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  setUp(() async {
    await getIt.reset();

    final authRepository = MockAuthRepository();
    when(
      () => authRepository.authStateChanges,
    ).thenAnswer((_) => Stream.value(null));

    final onboardingRepository = MockOnboardingRepository();

    getIt.registerLazySingleton<AuthCubit>(() => AuthCubit(authRepository));
    getIt.registerLazySingleton<ConsentCubit>(
      () => ConsentCubit(onboardingRepository),
    );
  });

  testWidgets('unauthenticated access to /home redirects to /onboarding', (
    tester,
  ) async {
    final router = buildAppRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go('/home');
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/onboarding',
    );
  });
}
