import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/features/auth/domain/entities/app_user.dart';
import 'package:medify/features/auth/domain/repositories/auth_repository.dart';
import 'package:medify/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:medify/features/auth/presentation/cubit/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(
      () => repository.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());
  });

  group('AuthCubit', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthOtpSending, AuthOtpSent] when sendOtp succeeds',
      setUp: () {
        when(
          () => repository.sendOtp('+911234567890'),
        ).thenAnswer((_) async => const OtpRequest(verificationId: 'vid-1'));
      },
      build: () => AuthCubit(repository),
      act: (cubit) => cubit.sendOtp('+911234567890'),
      expect: () => [
        const AuthOtpSending('+911234567890'),
        const AuthOtpSent(
          phoneNumber: '+911234567890',
          verificationId: 'vid-1',
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthOtpSending, AuthError] when sendOtp fails',
      setUp: () {
        when(
          () => repository.sendOtp('+911234567890'),
        ).thenThrow(Exception('network down'));
      },
      build: () => AuthCubit(repository),
      act: (cubit) => cubit.sendOtp('+911234567890'),
      expect: () => [const AuthOtpSending('+911234567890'), isA<AuthError>()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthVerifying, AuthAuthenticated] when verifyOtp succeeds',
      seed: () => const AuthOtpSent(
        phoneNumber: '+911234567890',
        verificationId: 'vid-1',
      ),
      setUp: () {
        when(
          () =>
              repository.verifyOtp(verificationId: 'vid-1', smsCode: '123456'),
        ).thenAnswer(
          (_) async => const AppUser(uid: 'u1', phoneNumber: '+911234567890'),
        );
      },
      build: () => AuthCubit(repository),
      act: (cubit) => cubit.verifyOtp('123456'),
      expect: () => [
        const AuthVerifying(),
        const AuthAuthenticated(
          AppUser(uid: 'u1', phoneNumber: '+911234567890'),
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthVerifying, AuthError] when verifyOtp fails',
      seed: () => const AuthOtpSent(
        phoneNumber: '+911234567890',
        verificationId: 'vid-1',
      ),
      setUp: () {
        when(
          () =>
              repository.verifyOtp(verificationId: 'vid-1', smsCode: '000000'),
        ).thenThrow(Exception('invalid code'));
      },
      build: () => AuthCubit(repository),
      act: (cubit) => cubit.verifyOtp('000000'),
      expect: () => [const AuthVerifying(), isA<AuthError>()],
    );

    blocTest<AuthCubit, AuthState>(
      'does nothing when verifyOtp called without a pending OTP request',
      build: () => AuthCubit(repository),
      act: (cubit) => cubit.verifyOtp('123456'),
      expect: () => <AuthState>[],
    );

    blocTest<AuthCubit, AuthState>(
      'calls repository.signOut',
      setUp: () {
        when(() => repository.signOut()).thenAnswer((_) async {});
      },
      build: () => AuthCubit(repository),
      act: (cubit) => cubit.signOut(),
      verify: (_) {
        verify(() => repository.signOut()).called(1);
      },
    );
  });
}
