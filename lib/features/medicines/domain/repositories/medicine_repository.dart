import 'package:dartz/dartz.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';

abstract class MedicineRepository {
  Future<Either<Failure, List<Medicine>>> getAllMedicines();
  Future<Either<Failure, List<Medicine>>> getActiveMedicines();
  Future<Either<Failure, Medicine?>> getMedicineById(int id);
  Future<Either<Failure, Medicine>> addMedicine(Medicine medicine);
  Future<Either<Failure, Medicine>> updateMedicine(Medicine medicine);
  Future<Either<Failure, void>> deleteMedicine(int id);
  Future<Either<Failure, Medicine>> toggleMedicineStatus(int id);
  Stream<List<Medicine>> watchAllMedicines();
  Stream<List<Medicine>> watchActiveMedicines();
}
