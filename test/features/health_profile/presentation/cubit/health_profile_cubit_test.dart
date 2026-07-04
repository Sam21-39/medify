import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/features/health_profile/domain/entities/health_profile.dart';
import 'package:medify/features/health_profile/domain/repositories/health_profile_repository.dart';
import 'package:medify/features/health_profile/presentation/cubit/health_profile_cubit.dart';
import 'package:medify/features/health_profile/presentation/cubit/health_profile_state.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthProfileRepository extends Mock
    implements HealthProfileRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      HealthProfile(
        uid: 'fallback',
        fullName: 'fallback',
        age: 0,
        gender: 'fallback',
        bloodGroup: 'fallback',
        updatedAt: DateTime(2026),
      ),
    );
  });

  late MockHealthProfileRepository repository;

  setUp(() {
    repository = MockHealthProfileRepository();
  });

  group('HealthProfileCubit', () {
    blocTest<HealthProfileCubit, HealthProfileState>(
      'goToConditionsStep does nothing when basic info is invalid',
      build: () => HealthProfileCubit(repository),
      act: (cubit) => cubit.goToConditionsStep(),
      expect: () => <HealthProfileState>[],
    );

    blocTest<HealthProfileCubit, HealthProfileState>(
      'advances step1 -> step2 -> step3 with valid data',
      build: () => HealthProfileCubit(repository),
      act: (cubit) {
        cubit.updateBasicInfo(
          fullName: 'Arun Sharma',
          age: 54,
          gender: 'Male',
          bloodGroup: 'O+',
        );
        cubit.goToConditionsStep();
        cubit.updateConditions(
          allergies: ['Penicillin'],
          chronicConditions: ['Hypertension'],
        );
        cubit.goToEmergencyStep();
      },
      expect: () => [
        isA<WizardStep1Basic>(),
        isA<WizardStep2Conditions>(),
        isA<WizardStep2Conditions>(),
        isA<WizardStep3Emergency>(),
      ],
    );

    blocTest<HealthProfileCubit, HealthProfileState>(
      'submit emits [WizardSubmitting, WizardComplete] on success',
      setUp: () {
        when(() => repository.saveProfile(any())).thenAnswer((_) async {});
      },
      build: () => HealthProfileCubit(repository),
      seed: () => WizardStep3Emergency(
        const HealthProfileDraft(
          fullName: 'Arun Sharma',
          age: 54,
          gender: 'Male',
          bloodGroup: 'O+',
        ),
      ),
      act: (cubit) => cubit.submit('u1'),
      expect: () => [isA<WizardSubmitting>(), isA<WizardComplete>()],
      verify: (_) {
        verify(() => repository.saveProfile(any())).called(1);
      },
    );

    blocTest<HealthProfileCubit, HealthProfileState>(
      'submit emits [WizardSubmitting, WizardError] on failure',
      setUp: () {
        when(
          () => repository.saveProfile(any()),
        ).thenThrow(Exception('write failed'));
      },
      build: () => HealthProfileCubit(repository),
      seed: () => WizardStep3Emergency(
        const HealthProfileDraft(
          fullName: 'Arun Sharma',
          age: 54,
          gender: 'Male',
          bloodGroup: 'O+',
        ),
      ),
      act: (cubit) => cubit.submit('u1'),
      expect: () => [isA<WizardSubmitting>(), isA<WizardError>()],
    );
  });
}
