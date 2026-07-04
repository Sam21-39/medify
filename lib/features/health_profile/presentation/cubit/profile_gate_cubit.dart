import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/health_profile_repository.dart';

/// Router-gating concern, separate from [HealthProfileCubit]'s wizard state
/// machine: "does this uid already have a saved profile?" - mirrors
/// ConsentCubit's Initial/Checking/Required/Granted pattern.
sealed class ProfileGateState extends Equatable {
  const ProfileGateState();

  @override
  List<Object?> get props => [];
}

class ProfileGateInitial extends ProfileGateState {
  const ProfileGateInitial();
}

class ProfileGateChecking extends ProfileGateState {
  const ProfileGateChecking();
}

class ProfileGateRequired extends ProfileGateState {
  const ProfileGateRequired();
}

class ProfileGateComplete extends ProfileGateState {
  const ProfileGateComplete();
}

@lazySingleton
class ProfileGateCubit extends Cubit<ProfileGateState> {
  ProfileGateCubit(this._repository) : super(const ProfileGateInitial());

  final HealthProfileRepository _repository;

  Future<void> checkProfile(String uid) async {
    emit(const ProfileGateChecking());
    try {
      final profile = await _repository.getProfile(uid);
      emit(
        profile == null
            ? const ProfileGateRequired()
            : const ProfileGateComplete(),
      );
    } catch (e, st) {
      // Non-fatal: fall back to ProfileGateRequired instead of hanging in
      // ProfileGateChecking forever or letting this surface as unhandled.
      await FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
      emit(const ProfileGateRequired());
    }
  }

  /// Called after the wizard successfully saves a profile, so the router
  /// re-evaluates without needing another repository round-trip.
  void markComplete() => emit(const ProfileGateComplete());
}
