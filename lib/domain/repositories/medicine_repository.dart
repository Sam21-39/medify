import '../entities/medicine.dart';

/// Repository interface for Medicine operations
abstract class MedicineRepository {
  /// Get all medicines
  Future<List<Medicine>> getAllMedicines();

  /// Get active medicines only
  Future<List<Medicine>> getActiveMedicines();

  /// Get medicine by ID
  Future<Medicine?> getMedicineById(int id);

  /// Add a new medicine
  Future<Medicine> addMedicine(Medicine medicine);

  /// Update an existing medicine
  Future<Medicine> updateMedicine(Medicine medicine);

  /// Delete a medicine
  Future<void> deleteMedicine(int id);

  /// Toggle medicine active status
  Future<Medicine> toggleMedicineStatus(int id);

  /// Stream of all medicines
  Stream<List<Medicine>> watchAllMedicines();

  /// Stream of active medicines
  Stream<List<Medicine>> watchActiveMedicines();
}

