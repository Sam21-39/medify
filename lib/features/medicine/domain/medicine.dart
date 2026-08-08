import 'package:equatable/equatable.dart';

import 'schedule.dart';

class Medicine extends Equatable {
  const Medicine({
    required this.id,
    required this.profileId,
    required this.name,
    required this.dosageAmount,
    required this.dosageUnit,
    required this.form,
    required this.schedule,
    this.pillsRemaining = 0,
    this.expiryDate,
    this.isPaused = false,
  });

  final String id;
  final String profileId;
  final String name;
  final double dosageAmount;
  final String dosageUnit;
  final String form;
  final Schedule schedule;
  final int pillsRemaining;
  final DateTime? expiryDate;
  final bool isPaused;

  @override
  List<Object?> get props => [
    id,
    profileId,
    name,
    dosageAmount,
    dosageUnit,
    form,
    schedule,
    pillsRemaining,
    expiryDate,
    isPaused,
  ];
}
