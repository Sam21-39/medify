import 'package:objectbox/objectbox.dart';
import '../../domain/entities/medicine.dart';

/// ObjectBox model for Medicine entity
@Entity()
class MedicineModel {
  @Id()
  int id;

  int profileId; // User profile this medicine belongs to
  String name;
  int medicineType; // Store as int (enum index) - tablet, syrup, etc.
  double dosageAmount; // Numeric amount (e.g., 1, 2, 500)
  String dosage; // Full dosage string (e.g., "2 tablets", "500 ml")
  List<int> reminderTimes; // Stored as seconds since midnight
  int intakeTiming; // Store as int (enum index)
  bool isActive;
  String? notes;

  // Refill tracking fields
  double? totalQuantity; // Total quantity in bottle (supports decimals for ml)
  double? currentQuantity; // Current remaining quantity
  int? refillRemindDays; // Notify when X days of medicine left

  @Property(type: PropertyType.date)
  DateTime? lastRefillDate; // Last time medicine was refilled

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  MedicineModel({
    this.id = 0,
    required this.profileId,
    required this.name,
    this.medicineType = 0, // Default to tablet (index 0)
    this.dosageAmount = 1.0, // Default to 1
    required this.dosage,
    required this.reminderTimes,
    this.intakeTiming = 4, // Default to anytime (index 4)
    this.isActive = true,
    this.notes,
    this.totalQuantity,
    this.currentQuantity,
    this.refillRemindDays,
    this.lastRefillDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert Medicine entity to MedicineModel
  factory MedicineModel.fromEntity(Medicine medicine) {
    return MedicineModel(
      id: medicine.id ?? 0,
      profileId: medicine.profileId,
      name: medicine.name,
      medicineType: medicine.medicineType.index,
      dosageAmount: medicine.dosageAmount,
      dosage: medicine.dosage,
      reminderTimes: medicine.reminderTimes,
      intakeTiming: medicine.intakeTiming.index,
      isActive: medicine.isActive,
      notes: medicine.notes,
      totalQuantity: medicine.totalQuantity,
      currentQuantity: medicine.currentQuantity,
      refillRemindDays: medicine.refillRemindDays,
      lastRefillDate: medicine.lastRefillDate,
      createdAt: medicine.createdAt,
      updatedAt: medicine.updatedAt,
    );
  }

  /// Convert MedicineModel to Medicine entity
  Medicine toEntity() {
    return Medicine(
      id: id == 0 ? null : id,
      profileId: profileId,
      name: name,
      medicineType: MedicineType.values[medicineType],
      dosageAmount: dosageAmount,
      dosage: dosage,
      reminderTimes: reminderTimes,
      intakeTiming: MedicineIntakeTiming.values[intakeTiming],
      isActive: isActive,
      notes: notes,
      totalQuantity: totalQuantity,
      currentQuantity: currentQuantity,
      refillRemindDays: refillRemindDays,
      lastRefillDate: lastRefillDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
