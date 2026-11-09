import 'package:objectbox/objectbox.dart';
import '../../domain/entities/medicine_log.dart';

/// ObjectBox model for MedicineLog entity
@Entity()
class MedicineLogModel {
  @Id()
  int id;

  int profileId; // User profile this log belongs to
  int medicineId;

  @Property(type: PropertyType.date)
  DateTime scheduledTime;

  @Property(type: PropertyType.date)
  DateTime? takenTime;

  int status; // Store enum as int

  String? notes;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  MedicineLogModel({
    this.id = 0,
    required this.profileId,
    required this.medicineId,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert MedicineLog entity to MedicineLogModel
  factory MedicineLogModel.fromEntity(MedicineLog log) {
    return MedicineLogModel(
      id: log.id ?? 0,
      profileId: log.profileId,
      medicineId: log.medicineId,
      scheduledTime: log.scheduledTime,
      takenTime: log.takenTime,
      status: log.status.index,
      notes: log.notes,
      createdAt: log.createdAt,
      updatedAt: log.updatedAt,
    );
  }

  /// Convert MedicineLogModel to MedicineLog entity
  MedicineLog toEntity() {
    return MedicineLog(
      id: id == 0 ? null : id,
      profileId: profileId,
      medicineId: medicineId,
      scheduledTime: scheduledTime,
      takenTime: takenTime,
      status: MedicineLogStatus.values[status],
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

