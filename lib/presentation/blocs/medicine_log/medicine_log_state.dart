import 'package:equatable/equatable.dart';
import '../../../domain/entities/medicine_log.dart';

/// Base state for MedicineLog operations
abstract class MedicineLogState extends Equatable {
  const MedicineLogState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MedicineLogInitial extends MedicineLogState {}

/// Loading state
class MedicineLogLoading extends MedicineLogState {}

/// Loaded state with logs list
class MedicineLogLoaded extends MedicineLogState {
  final List<MedicineLog> logs;

  const MedicineLogLoaded(this.logs);

  @override
  List<Object?> get props => [logs];
}

/// Error state
class MedicineLogError extends MedicineLogState {
  final String message;

  const MedicineLogError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Operation success state
class MedicineLogOperationSuccess extends MedicineLogState {
  final String message;

  const MedicineLogOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

