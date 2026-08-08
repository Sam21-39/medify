import 'package:drift/drift.dart';

/// Table definitions from Section 5.1 of the architecture doc. `pendingSync`
/// (plus [SyncQueue]) drives `core/sync/` — every write is local-first and
/// independently queued for sync, never blocked on it.

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get relation => text()();
  TextColumn get avatarRef => text().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Medicines extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get name => text()();
  RealColumn get dosageAmount => real()();
  TextColumn get dosageUnit => text()();
  TextColumn get form => text()();
  TextColumn get scheduleType => text()();
  TextColumn get scheduleConfigJson => text()();
  IntColumn get pillsRemaining => integer().withDefault(const Constant(0))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Where a dose action originated — five surfaces (in-app, standard
/// notification, lock-screen action, home widget, Live Activity) all
/// resolve to the same `markTaken`/`snoozeDose`/`skipDose` use cases;
/// recording the source is purely for per-surface reliability debugging,
/// not behavioral branching (Section 5.1).
class DoseLogs extends Table {
  TextColumn get id => text()();
  TextColumn get medicineId => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get status => text()();
  DateTimeColumn get actionAt => dateTime().nullable()();
  TextColumn get actionSource => text().nullable()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Appointments extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get doctorName => text()();
  TextColumn get hospital => text().nullable()();
  DateTimeColumn get appointmentAt => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get teleLink => text().nullable()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Prescriptions extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get encryptedFileRef => text()();
  DateTimeColumn get uploadedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get linkedMedicineIdsJson =>
      text().withDefault(const Constant('[]'))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Phase 4.
class HealthMetrics extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get type => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  DateTimeColumn get recordedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Achievements extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get type => text()();
  DateTimeColumn get unlockedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityTable => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
