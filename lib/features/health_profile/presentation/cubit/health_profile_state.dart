import 'package:equatable/equatable.dart';

/// Draft form data accumulated across the 3-step wizard before final submit.
class HealthProfileDraft extends Equatable {
  const HealthProfileDraft({
    this.fullName = '',
    this.age,
    this.gender = '',
    this.bloodGroup = '',
    this.allergies = const [],
    this.chronicConditions = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.doctorName,
    this.doctorPhone,
  });

  final String fullName;
  final int? age;
  final String gender;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? doctorName;
  final String? doctorPhone;

  bool get hasValidBasicInfo =>
      fullName.trim().isNotEmpty &&
      age != null &&
      age! > 0 &&
      bloodGroup.isNotEmpty;

  HealthProfileDraft copyWith({
    String? fullName,
    int? age,
    String? gender,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? doctorName,
    String? doctorPhone,
  }) {
    return HealthProfileDraft(
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      doctorName: doctorName ?? this.doctorName,
      doctorPhone: doctorPhone ?? this.doctorPhone,
    );
  }

  @override
  List<Object?> get props => [
    fullName,
    age,
    gender,
    bloodGroup,
    allergies,
    chronicConditions,
    emergencyContactName,
    emergencyContactPhone,
    doctorName,
    doctorPhone,
  ];
}

sealed class HealthProfileState extends Equatable {
  const HealthProfileState(this.draft);

  final HealthProfileDraft draft;

  @override
  List<Object?> get props => [draft];
}

class WizardStep1Basic extends HealthProfileState {
  const WizardStep1Basic(super.draft);
}

class WizardStep2Conditions extends HealthProfileState {
  const WizardStep2Conditions(super.draft);
}

class WizardStep3Emergency extends HealthProfileState {
  const WizardStep3Emergency(super.draft);
}

class WizardSubmitting extends HealthProfileState {
  const WizardSubmitting(super.draft);
}

class WizardComplete extends HealthProfileState {
  const WizardComplete(super.draft);
}

class WizardError extends HealthProfileState {
  const WizardError(super.draft, this.message);

  final String message;

  @override
  List<Object?> get props => [draft, message];
}
