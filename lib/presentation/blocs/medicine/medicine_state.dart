import 'package:equatable/equatable.dart';
import '../../../domain/entities/medicine.dart';

/// Base state for Medicine operations
abstract class MedicineState extends Equatable {
  const MedicineState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MedicineInitial extends MedicineState {}

/// Loading state
class MedicineLoading extends MedicineState {}

/// Loaded state with medicines list
class MedicineLoaded extends MedicineState {
  final List<Medicine> medicines;

  const MedicineLoaded(this.medicines);

  @override
  List<Object?> get props => [medicines];
}

/// Error state
class MedicineError extends MedicineState {
  final String message;

  const MedicineError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Operation success state (add/update/delete)
class MedicineOperationSuccess extends MedicineState {
  final String message;

  const MedicineOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

