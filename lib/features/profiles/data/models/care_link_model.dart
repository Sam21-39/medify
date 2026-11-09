import 'package:objectbox/objectbox.dart';

/// Local link: caregiver profile may act for a patient profile.
@Entity()
class CareLinkModel {
  @Id()
  int id;

  int patientProfileId;
  int caregiverProfileId;

  CareLinkModel({
    this.id = 0,
    required this.patientProfileId,
    required this.caregiverProfileId,
  });
}
