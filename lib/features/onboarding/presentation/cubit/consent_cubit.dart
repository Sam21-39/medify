import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/consent_record.dart';
import '../../domain/repositories/onboarding_repository.dart';

sealed class ConsentState extends Equatable {
  const ConsentState();

  @override
  List<Object?> get props => [];
}

class ConsentInitial extends ConsentState {
  const ConsentInitial();
}

class ConsentChecking extends ConsentState {
  const ConsentChecking();
}

class ConsentRequired extends ConsentState {
  const ConsentRequired();
}

class ConsentGranted extends ConsentState {
  const ConsentGranted();
}

@lazySingleton
class ConsentCubit extends Cubit<ConsentState> {
  ConsentCubit(this._repository) : super(const ConsentInitial());

  final OnboardingRepository _repository;

  Future<void> checkConsent(String uid) async {
    emit(const ConsentChecking());
    try {
      final accepted = await _repository.hasAcceptedConsent(uid);
      emit(accepted ? const ConsentGranted() : const ConsentRequired());
    } catch (e, st) {
      // Non-fatal: e.g. Firestore rules not yet deployed. Fall back to
      // ConsentRequired instead of hanging in ConsentChecking forever or
      // letting this surface as an unhandled (and misleadingly "fatal")
      // async error via PlatformDispatcher.onError.
      await FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
      emit(const ConsentRequired());
    }
  }

  Future<void> acceptConsent(String uid) async {
    try {
      await _repository.acceptConsent(
        uid,
        ConsentRecord(acceptedAt: DateTime.now(), version: consentVersion),
      );
      emit(const ConsentGranted());
    } catch (e, st) {
      await FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
    }
  }
}
