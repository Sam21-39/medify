import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:medify/core/di/injection_container.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/preferences/preferences_service.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:medify/core/database/objectbox_service.dart';
import 'package:medify/features/medicines/data/models/medicine_model.dart';
import 'package:medify/objectbox.g.dart';

/// Implementation of MedicineRepository using ObjectBox
class MedicineRepositoryImpl implements MedicineRepository {
  final ObjectBoxService _objectBoxService;
  final _medicineStreamController =
      StreamController<List<Medicine>>.broadcast();

  MedicineRepositoryImpl(this._objectBoxService);

  @override
  Future<Either<Failure, List<Medicine>>> getAllMedicines() async {
    try {
      final models = _objectBoxService.medicineBox.getAll();
      return Right(
        _forActive(models.map((model) => model.toEntity()).toList()),
      );
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Medicine>>> getActiveMedicines() async {
    try {
      final query = _objectBoxService.medicineBox
          .query(MedicineModel_.isActive.equals(true))
          .build();
      final models = query.find();
      query.close();
      return Right(
        _forActive(models.map((model) => model.toEntity()).toList()),
      );
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  List<Medicine> _forActive(List<Medicine> medicines) {
    final id = getIt<PreferencesService>().actingPatientId;
    if (id == null) return medicines;
    return medicines.where((medicine) => medicine.profileId == id).toList();
  }

  @override
  Future<Either<Failure, Medicine?>> getMedicineById(int id) async {
    try {
      final model = _objectBoxService.medicineBox.get(id);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Medicine>> addMedicine(Medicine medicine) async {
    try {
      final model = MedicineModel.fromEntity(medicine);
      final id = _objectBoxService.medicineBox.put(model);
      model.id = id;
      _notifyListeners();
      return Right(model.toEntity());
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Medicine>> updateMedicine(Medicine medicine) async {
    try {
      if (medicine.id == null) {
        return const Left(Failure('Medicine ID cannot be null for update'));
      }
      final model = MedicineModel.fromEntity(medicine);
      _objectBoxService.medicineBox.put(model);
      _notifyListeners();
      return Right(model.toEntity());
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMedicine(int id) async {
    try {
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
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Medicine>> toggleMedicineStatus(int id) async {
    try {
      final model = _objectBoxService.medicineBox.get(id);
      if (model == null) return const Left(Failure('Medicine not found'));
      model.isActive = !model.isActive;
      model.updatedAt = DateTime.now();
      _objectBoxService.medicineBox.put(model);
      _notifyListeners();
      return Right(model.toEntity());
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Stream<List<Medicine>> watchAllMedicines() {
    getAllMedicines().then((result) {
      result.fold((_) {}, (medicines) {
        if (!_medicineStreamController.isClosed) {
          _medicineStreamController.add(medicines);
        }
      });
    });
    return _medicineStreamController.stream;
  }

  @override
  Stream<List<Medicine>> watchActiveMedicines() {
    // For simplicity, filter the main stream
    return watchAllMedicines().map(
      (medicines) => medicines.where((medicine) => medicine.isActive).toList(),
    );
  }

  void _notifyListeners() {
    getAllMedicines().then((result) {
      result.fold((_) {}, (medicines) {
        if (!_medicineStreamController.isClosed) {
          _medicineStreamController.add(medicines);
        }
      });
    });
  }

  void dispose() {
    _medicineStreamController.close();
  }
}
