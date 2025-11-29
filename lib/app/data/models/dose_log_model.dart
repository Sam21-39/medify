class DoseLogModel {
  final String id;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledTime;
  final DateTime? actualTime;
  final DoseStatus status;
  final String? reason; // For skipped doses
  final String? note; // Optional user note
  final DateTime createdAt;
  final bool synced;

  DoseLogModel({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    this.actualTime,
    required this.status,
    this.reason,
    this.note,
    required this.createdAt,
    this.synced = false,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'actualTime': actualTime?.toIso8601String(),
      'status': status.toString().split('.').last,
      'reason': reason,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON (Firestore)
  factory DoseLogModel.fromJson(Map<String, dynamic> json) {
    return DoseLogModel(
      id: json['id'],
      medicationId: json['medicationId'],
      medicationName: json['medicationName'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      actualTime: json['actualTime'] != null 
          ? DateTime.parse(json['actualTime']) 
          : null,
      status: DoseStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      reason: json['reason'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
      synced: json['synced'] ?? false,
    );
  }

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'medication_name': medicationName,
      'scheduled_time': scheduledTime.millisecondsSinceEpoch,
      'actual_time': actualTime?.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
      'reason': reason,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
      'synced': synced ? 1 : 0,
    };
  }

  // Create from SQLite Map
  factory DoseLogModel.fromMap(Map<String, dynamic> map) {
    return DoseLogModel(
      id: map['id'],
      medicationId: map['medication_id'],
      medicationName: map['medication_name'],
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduled_time']),
      actualTime: map['actual_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['actual_time']) 
          : null,
      status: DoseStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
      reason: map['reason'],
      note: map['note'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      synced: map['synced'] == 1,
    );
  }

  // Copy with method for updates
  DoseLogModel copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    DateTime? scheduledTime,
    DateTime? actualTime,
    DoseStatus? status,
    String? reason,
    String? note,
    DateTime? createdAt,
    bool? synced,
  }) {
    return DoseLogModel(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  // Helper to check if dose was taken late
  bool get isTakenLate {
    if (status == DoseStatus.taken && actualTime != null) {
      return actualTime!.isAfter(scheduledTime.add(const Duration(minutes: 15)));
    }
    return false;
  }

  // Get delay duration if taken late
  Duration? get delayDuration {
    if (isTakenLate && actualTime != null) {
      return actualTime!.difference(scheduledTime);
    }
    return null;
  }
}

// Dose Status Enum
enum DoseStatus {
  taken,
  skipped,
  snoozed,
  pending,
}

// Skip Reasons
class SkipReason {
  static const String alreadyTook = 'Already took it';
  static const String feelingBetter = 'Feeling better';
  static const String forgot = 'Forgot to take it';
  static const String sideEffects = 'Side effects';
  static const String outOfMedication = 'Out of medication';
  static const String other = 'Other';

  static List<String> get all => [
    alreadyTook,
    feelingBetter,
    forgot,
    sideEffects,
    outOfMedication,
    other,
  ];
}
