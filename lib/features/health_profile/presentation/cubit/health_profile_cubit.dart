import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/health_profile.dart';
import '../../domain/repositories/health_profile_repository.dart';
import 'health_profile_state.dart';

@lazySingleton
class HealthProfileCubit extends Cubit<HealthProfileState> {
  HealthProfileCubit(this._repository)
    : super(const WizardStep1Basic(HealthProfileDraft()));

  final HealthProfileRepository _repository;

  void updateBasicInfo({
    required String fullName,
    required int age,
    required String gender,
    required String bloodGroup,
  }) {
    emit(
      WizardStep1Basic(
        state.draft.copyWith(
          fullName: fullName,
          age: age,
          gender: gender,
          bloodGroup: bloodGroup,
        ),
      ),
    );
  }

  void goToConditionsStep() {
    if (!state.draft.hasValidBasicInfo) return;
    emit(WizardStep2Conditions(state.draft));
  }

  void updateConditions({
    required List<String> allergies,
    required List<String> chronicConditions,
  }) {
    emit(
      WizardStep2Conditions(
        state.draft.copyWith(
          allergies: allergies,
          chronicConditions: chronicConditions,
        ),
      ),
    );
  }

  void goToEmergencyStep() {
    emit(WizardStep3Emergency(state.draft));
  }

  void backToBasicInfo() => emit(WizardStep1Basic(state.draft));

  void backToConditions() => emit(WizardStep2Conditions(state.draft));

  Future<void> submit(
    String uid, {
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? doctorName,
    String? doctorPhone,
  }) async {
    final draft = state.draft.copyWith(
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      doctorName: doctorName,
      doctorPhone: doctorPhone,
    );
    emit(WizardSubmitting(draft));
    try {
      await _repository.saveProfile(
        HealthProfile(
          uid: uid,
          fullName: draft.fullName,
          age: draft.age!,
          gender: draft.gender,
          bloodGroup: draft.bloodGroup,
          allergies: draft.allergies,
          chronicConditions: draft.chronicConditions,
          emergencyContactName: draft.emergencyContactName,
          emergencyContactPhone: draft.emergencyContactPhone,
          doctorName: draft.doctorName,
          doctorPhone: draft.doctorPhone,
          updatedAt: DateTime.now(),
        ),
      );
      emit(WizardComplete(draft));
    } catch (e) {
      emit(WizardError(draft, e.toString()));
    }
  }
}
