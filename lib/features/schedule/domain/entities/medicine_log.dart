import 'package:equatable/equatable.dart';

/// Log entry status enum
enum MedicineLogStatus { pending, taken, missed, skipped, snoozed }

/// Medicine log entity representing the history of medicine intake
class MedicineLog extends Equatable {
  final int? id;
  final int profileId; // User profile this log belongs to
  final int medicineId;
  final int? scheduleId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final MedicineLogStatus status;
  final String? notes;
  final DateTime? snoozedUntil;
  final int actorProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicineLog({
    this.id,
    required this.profileId,
    required this.medicineId,
    this.scheduleId,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    this.notes,
    this.snoozedUntil,
    this.actorProfileId = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of MedicineLog with updated fields
  MedicineLog copyWith({
    int? id,
    int? profileId,
    int? medicineId,
    int? scheduleId,
    DateTime? scheduledTime,
    DateTime? takenTime,
    MedicineLogStatus? status,
    String? notes,
    DateTime? snoozedUntil,
    int? actorProfileId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicineLog(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      medicineId: medicineId ?? this.medicineId,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      actorProfileId: actorProfileId ?? this.actorProfileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if the log is for today
  bool get isToday {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }

  /// Check if the log is overdue
  bool get isOverdue {
    if (status == MedicineLogStatus.taken ||
        status == MedicineLogStatus.skipped) {
      return false;
    }
    return DateTime.now().isAfter(scheduledTime);
  }

  @override
  List<Object?> get props => [
    id,
    profileId,
    medicineId,
    scheduleId,
    scheduledTime,
    takenTime,
    status,
    notes,
    snoozedUntil,
    actorProfileId,
    createdAt,
    updatedAt,
  ];
}
