import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/features/health_profile/domain/entities/health_profile.dart';
import 'package:medify/features/health_profile/domain/repositories/health_profile_repository.dart';
import 'package:medify/features/health_profile/presentation/cubit/profile_gate_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthProfileRepository extends Mock
    implements HealthProfileRepository {}

void main() {
  late MockHealthProfileRepository repository;

  setUp(() {
    repository = MockHealthProfileRepository();
  });

  group('ProfileGateCubit', () {
    blocTest<ProfileGateCubit, ProfileGateState>(
      'emits ProfileGateRequired when no profile exists',
      setUp: () {
        when(() => repository.getProfile('u1')).thenAnswer((_) async => null);
      },
      build: () => ProfileGateCubit(repository),
      act: (cubit) => cubit.checkProfile('u1'),
      expect: () => [const ProfileGateChecking(), const ProfileGateRequired()],
    );

    blocTest<ProfileGateCubit, ProfileGateState>(
      'emits ProfileGateComplete when a profile already exists',
      setUp: () {
        when(() => repository.getProfile('u1')).thenAnswer(
          (_) async => HealthProfile(
            uid: 'u1',
            fullName: 'Arun Sharma',
            age: 54,
            gender: 'Male',
            bloodGroup: 'O+',
            updatedAt: DateTime(2026),
          ),
        );
      },
      build: () => ProfileGateCubit(repository),
      act: (cubit) => cubit.checkProfile('u1'),
      expect: () => [const ProfileGateChecking(), const ProfileGateComplete()],
    );

    blocTest<ProfileGateCubit, ProfileGateState>(
      'markComplete emits ProfileGateComplete directly',
      build: () => ProfileGateCubit(repository),
      act: (cubit) => cubit.markComplete(),
      expect: () => [const ProfileGateComplete()],
    );
  });
}
