import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOtpSending extends AuthState {
  const AuthOtpSending(this.phoneNumber);

  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthOtpSent extends AuthState {
  const AuthOtpSent({required this.phoneNumber, required this.verificationId});

  final String phoneNumber;
  final String verificationId;

  @override
  List<Object?> get props => [phoneNumber, verificationId];
}

class AuthVerifying extends AuthState {
  const AuthVerifying();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
