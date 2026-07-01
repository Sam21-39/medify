import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/features/onboarding/domain/entities/consent_record.dart';
import 'package:medify/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:medify/features/onboarding/presentation/cubit/consent_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      ConsentRecord(acceptedAt: DateTime(2026), version: consentVersion),
    );
  });

  late MockOnboardingRepository repository;

  setUp(() {
    repository = MockOnboardingRepository();
  });

  group('ConsentCubit', () {
    blocTest<ConsentCubit, ConsentState>(
      'emits ConsentGranted when the uid has already accepted consent',
      setUp: () {
        when(
          () => repository.hasAcceptedConsent('u1'),
        ).thenAnswer((_) async => true);
      },
      build: () => ConsentCubit(repository),
      act: (cubit) => cubit.checkConsent('u1'),
      expect: () => [const ConsentChecking(), const ConsentGranted()],
    );

    blocTest<ConsentCubit, ConsentState>(
      'emits ConsentRequired when the uid has not accepted consent',
      setUp: () {
        when(
          () => repository.hasAcceptedConsent('u1'),
        ).thenAnswer((_) async => false);
      },
      build: () => ConsentCubit(repository),
      act: (cubit) => cubit.checkConsent('u1'),
      expect: () => [const ConsentChecking(), const ConsentRequired()],
    );

    blocTest<ConsentCubit, ConsentState>(
      'emits ConsentGranted after accepting consent',
      setUp: () {
        when(
          () => repository.acceptConsent(any(), any()),
        ).thenAnswer((_) async {});
      },
      build: () => ConsentCubit(repository),
      act: (cubit) => cubit.acceptConsent('u1'),
      expect: () => [const ConsentGranted()],
      verify: (_) {
        verify(() => repository.acceptConsent('u1', any())).called(1);
      },
    );
  });
}
