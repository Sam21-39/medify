import 'dart:async';
import '../../domain/entities/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../datasources/objectbox_service.dart';
import '../models/medicine_model.dart';
import '../../objectbox.g.dart';

/// Implementation of MedicineRepository using ObjectBox
class MedicineRepositoryImpl implements MedicineRepository {
  final ObjectBoxService _objectBoxService;
  final _medicineStreamController =
      StreamController<List<Medicine>>.broadcast();

  MedicineRepositoryImpl(this._objectBoxService);

  @override
  Future<List<Medicine>> getAllMedicines() async {
    final models = _objectBoxService.medicineBox.getAll();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Medicine>> getActiveMedicines() async {
    final query = _objectBoxService.medicineBox
        .query(MedicineModel_.isActive.equals(true))
        .build();
    final models = query.find();
    query.close();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Medicine?> getMedicineById(int id) async {
    final model = _objectBoxService.medicineBox.get(id);
    return model?.toEntity();
  }

  @override
  Future<Medicine> addMedicine(Medicine medicine) async {
    final model = MedicineModel.fromEntity(medicine);
    final id = _objectBoxService.medicineBox.put(model);
    model.id = id;
    _notifyListeners();
    return model.toEntity();
  }

  @override
  Future<Medicine> updateMedicine(Medicine medicine) async {
    if (medicine.id == null) {
      throw Exception('Medicine ID cannot be null for update');
    }
    final model = MedicineModel.fromEntity(medicine);
    _objectBoxService.medicineBox.put(model);
    _notifyListeners();
    return model.toEntity();
  }

  @override
  Future<void> deleteMedicine(int id) async {
    // CRITICAL FIX: Delete all logs associated with this medicine first
    // to prevent orphaned logs in database
    final logsQuery = _objectBoxService.medicineLogBox
        .query(MedicineLogModel_.medicineId.equals(id))
        .build();
    final logs = logsQuery.find();
    logsQuery.close();
    
    // Delete all logs for this medicine
    for (final log in logs) {
      _objectBoxService.medicineLogBox.remove(log.id);
    }
    
    // Now delete the medicine itself
    _objectBoxService.medicineBox.remove(id);
    _notifyListeners();
  }

  @override
  Future<Medicine> toggleMedicineStatus(int id) async {
    final model = _objectBoxService.medicineBox.get(id);
    if (model == null) {
      throw Exception('Medicine not found');
    }
    model.isActive = !model.isActive;
    model.updatedAt = DateTime.now();
    _objectBoxService.medicineBox.put(model);
    _notifyListeners();
    return model.toEntity();
  }

  @override
  Stream<List<Medicine>> watchAllMedicines() {
    // Initial data
    getAllMedicines().then((medicines) {
      if (!_medicineStreamController.isClosed) {
        _medicineStreamController.add(medicines);
      }
    });
    return _medicineStreamController.stream;
  }

  @override
  Stream<List<Medicine>> watchActiveMedicines() {
    // For simplicity, filter the main stream
    return watchAllMedicines().map((medicines) =>
        medicines.where((medicine) => medicine.isActive).toList());
  }

  void _notifyListeners() {
    getAllMedicines().then((medicines) {
      if (!_medicineStreamController.isClosed) {
        _medicineStreamController.add(medicines);
      }
    });
  }

  void dispose() {
    _medicineStreamController.close();
  }
}
