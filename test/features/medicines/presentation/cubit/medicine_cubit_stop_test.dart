import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medify/core/error/failure.dart';
import 'package:medify/core/notifications/notification_service.dart';
import 'package:medify/features/medicines/domain/entities/medicine.dart';
import 'package:medify/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_cubit.dart';
import 'package:medify/features/medicines/presentation/cubit/medicine_state.dart';

/// Records every call into [events] so tests can assert ordering.
class _FakeNotifications extends Fake implements NotificationService {
  _FakeNotifications(this.events, {this.failCancel = false});

  final List<String> events;
  final bool failCancel;

  @override
  Future<void> cancelMedicineReminders(int medicineId) async {
    events.add('cancel');
    if (failCancel) throw StateError('cancel failed');
  }

  @override
  Future<void> rescheduleUpcoming() async => events.add('reschedule');
}

class _FakeRepo extends Fake implements MedicineRepository {
  _FakeRepo(this.events, this.medicine);

  final List<String> events;
  final Medicine medicine;

  @override
  Future<Either<Failure, Medicine?>> getMedicineById(int id) async =>
      Right(medicine);

  @override
  Future<Either<Failure, void>> stopMedicine(int id, {String? reason}) async {
    events.add('stop');
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Medicine>>> getAllMedicines() async =>
      const Right([]);
}

void main() {
  final medicine = Medicine(
    id: 1,
    profileId: 1,
    name: 'Aspirin',
    dosage: '1 tablet',
    reminderTimes: const [28800],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  test('stop cancels reminders before the repo stop write', () async {
    final events = <String>[];
    final cubit = MedicineCubit(
      _FakeRepo(events, medicine),
      notifications: _FakeNotifications(events),
    );
    addTearDown(cubit.close);

    await cubit.stopMedicine(1, reason: 'course_finished');

    expect(events, contains('stop'));
    expect(events.indexOf('cancel'), lessThan(events.indexOf('stop')));
  });

  test('failed cancel aborts stop before the DB write', () async {
    final events = <String>[];
    final cubit = MedicineCubit(
      _FakeRepo(events, medicine),
      notifications: _FakeNotifications(events, failCancel: true),
    );
    addTearDown(cubit.close);

    await cubit.stopMedicine(1);

    expect(events, isNot(contains('stop')));
    expect(events, contains('reschedule'));
    expect(cubit.state, isA<MedicineError>());
  });
}
