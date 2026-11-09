import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_profile.dart';

/// Base state for profile management
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProfileInitial extends ProfileState {}

/// Loading state
class ProfileLoading extends ProfileState {}

/// Profiles loaded successfully
class ProfilesLoaded extends ProfileState {
  final List<UserProfile> profiles;
  final UserProfile? activeProfile;

  const ProfilesLoaded(this.profiles, {this.activeProfile});

  @override
  List<Object?> get props => [profiles, activeProfile];
}

/// Single profile loaded
class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Profile operation successful (create, update, delete, switch)
class ProfileOperationSuccess extends ProfileState {
  final String message;
  final UserProfile? profile;

  const ProfileOperationSuccess(this.message, {this.profile});

  @override
  List<Object?> get props => [message, profile];
}

/// Active profile changed
class ActiveProfileChanged extends ProfileState {
  final UserProfile profile;

  const ActiveProfileChanged(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Error state
class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

