import 'package:equatable/equatable.dart';
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
    final accepted = await _repository.hasAcceptedConsent(uid);
    emit(accepted ? const ConsentGranted() : const ConsentRequired());
  }

  Future<void> acceptConsent(String uid) async {
    await _repository.acceptConsent(
      uid,
      ConsentRecord(acceptedAt: DateTime.now(), version: consentVersion),
    );
    emit(const ConsentGranted());
  }
}
