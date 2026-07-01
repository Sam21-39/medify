import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial()) {
    _authSub = _repository.authStateChanges.listen((user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else if (state is! AuthOtpSending && state is! AuthOtpSent) {
        emit(const AuthUnauthenticated());
      }
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription _authSub;

  Future<void> sendOtp(String phoneNumber) async {
    emit(AuthOtpSending(phoneNumber));
    try {
      final request = await _repository.sendOtp(phoneNumber);
      emit(
        AuthOtpSent(
          phoneNumber: phoneNumber,
          verificationId: request.verificationId,
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyOtp(String smsCode) async {
    final current = state;
    if (current is! AuthOtpSent) return;

    emit(const AuthVerifying());
    try {
      final user = await _repository.verifyOtp(
        verificationId: current.verificationId,
        smsCode: smsCode,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() => _repository.signOut();

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
