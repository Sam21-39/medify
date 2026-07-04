import 'package:equatable/equatable.dart';

class HealthProfile extends Equatable {
  const HealthProfile({
    required this.uid,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.doctorName,
    this.doctorPhone,
    required this.updatedAt,
  });

  final String uid;
  final String fullName;
  final int age;
  final String gender;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? doctorName;
  final String? doctorPhone;
  final DateTime updatedAt;

  HealthProfile copyWith({
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
    return HealthProfile(
      uid: uid,
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
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    uid,
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
    updatedAt,
  ];
}
