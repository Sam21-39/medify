class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final double dosage;
  final String unit;
  final String? colorTag;
  final DateTime startDate;
  final DateTime? endDate;
  final MedicationFrequency frequency;
  final List<MedicationTime> times;
  final String? instructions;
  final int? quantity;
  final int? refillThreshold;
  final MedicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.unit,
    this.colorTag,
    required this.startDate,
    this.endDate,
    required this.frequency,
    required this.times,
    this.instructions,
    this.quantity,
    this.refillThreshold,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'colorTag': colorTag,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'frequency': frequency.toJson(),
      'times': times.map((t) => t.toJson()).toList(),
      'instructions': instructions,
      'quantity': quantity,
      'refillThreshold': refillThreshold,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON (Firestore)
  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      dosage: (json['dosage'] as num).toDouble(),
      unit: json['unit'],
      colorTag: json['colorTag'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      frequency: MedicationFrequency.fromJson(json['frequency']),
      times: (json['times'] as List).map((t) => MedicationTime.fromJson(t)).toList(),
      instructions: json['instructions'],
      quantity: json['quantity'],
      refillThreshold: json['refillThreshold'],
      status: MedicationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      synced: json['synced'] ?? false,
    );
  }

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'color_tag': colorTag,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'frequency': frequency.toJsonString(),
      'times': MedicationTime.listToJsonString(times),
      'instructions': instructions,
      'quantity': quantity,
      'refill_threshold': refillThreshold,
      'status': status.toString().split('.').last,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'synced': synced ? 1 : 0,
    };
  }

  // Create from SQLite Map
  factory MedicationModel.fromMap(Map<String, dynamic> map) {
    return MedicationModel(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      dosage: (map['dosage'] as num).toDouble(),
      unit: map['unit'],
      colorTag: map['color_tag'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date']),
      endDate: map['end_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_date'])
          : null,
      frequency: MedicationFrequency.fromJsonString(map['frequency']),
      times: MedicationTime.listFromJsonString(map['times']),
      instructions: map['instructions'],
      quantity: map['quantity'],
      refillThreshold: map['refill_threshold'],
      status: MedicationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      synced: map['synced'] == 1,
    );
  }

  // Copy with method for updates
  MedicationModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? dosage,
    String? unit,
    String? colorTag,
    DateTime? startDate,
    DateTime? endDate,
    MedicationFrequency? frequency,
    List<MedicationTime>? times,
    String? instructions,
    int? quantity,
    int? refillThreshold,
    MedicationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      colorTag: colorTag ?? this.colorTag,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      instructions: instructions ?? this.instructions,
      quantity: quantity ?? this.quantity,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}

// Medication Status Enum
enum MedicationStatus { active, paused, completed }

// Medication Frequency Class
class MedicationFrequency {
  final FrequencyType type;
  final List<int>? specificDays; // 1-7 for Mon-Sun
  final int? intervalDays; // For custom interval

  MedicationFrequency({required this.type, this.specificDays, this.intervalDays});

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'specificDays': specificDays,
      'intervalDays': intervalDays,
    };
  }

  factory MedicationFrequency.fromJson(Map<String, dynamic> json) {
    return MedicationFrequency(
      type: FrequencyType.values.firstWhere((e) => e.toString().split('.').last == json['type']),
      specificDays: json['specificDays'] != null ? List<int>.from(json['specificDays']) : null,
      intervalDays: json['intervalDays'],
    );
  }

  String toJsonString() {
    return '${type.toString().split('.').last}|${specificDays?.join(',') ?? ''}|$intervalDays';
  }

  factory MedicationFrequency.fromJsonString(String str) {
    final parts = str.split('|');
    return MedicationFrequency(
      type: FrequencyType.values.firstWhere((e) => e.toString().split('.').last == parts[0]),
      specificDays: parts.length > 1 && parts[1].isNotEmpty && parts[1] != 'null'
          ? parts[1].split(',').map((e) => int.parse(e)).toList()
          : null,
      intervalDays: parts.length > 2 && parts[2] != 'null' ? int.parse(parts[2]) : null,
    );
  }
}

enum FrequencyType { daily, specificDays, customInterval }

// Medication Time Class
class MedicationTime {
  final int hour; // 0-23
  final int minute; // 0-59

  MedicationTime({required this.hour, required this.minute});

  Map<String, dynamic> toJson() {
    return {'hour': hour, 'minute': minute};
  }

  factory MedicationTime.fromJson(Map<String, dynamic> json) {
    return MedicationTime(hour: json['hour'], minute: json['minute']);
  }

  static String listToJsonString(List<MedicationTime> times) {
    if (times.isEmpty) return '';
    return times.map((t) => '${t.hour}:${t.minute}').join(',');
  }

  static List<MedicationTime> listFromJsonString(String str) {
    if (str.isEmpty) return [];
    return str.split(',').map((timeStr) {
      final parts = timeStr.split(':');
      return MedicationTime(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();
  }

  String toTimeString() {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }
}
