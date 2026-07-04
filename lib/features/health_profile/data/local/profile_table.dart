import 'package:drift/drift.dart';

@DataClassName('ProfileRow')
class ProfileTable extends Table {
  TextColumn get uid => text()();
  TextColumn get fullName => text()();
  IntColumn get age => integer()();
  TextColumn get gender => text()();
  TextColumn get bloodGroup => text()();
  // Stored as a comma-joined list - simple values (allergy/condition names),
  // no commas expected; a real multi-value column type isn't worth the
  // complexity for this MVP field.
  TextColumn get allergies => text().withDefault(const Constant(''))();
  TextColumn get chronicConditions => text().withDefault(const Constant(''))();
  TextColumn get emergencyContactName => text().nullable()();
  TextColumn get emergencyContactPhone => text().nullable()();
  TextColumn get doctorName => text().nullable()();
  TextColumn get doctorPhone => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {uid};
}
