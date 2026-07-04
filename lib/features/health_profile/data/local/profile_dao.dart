import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import 'profile_table.dart';

part 'profile_dao.g.dart';

@lazySingleton
@DriftAccessor(tables: [ProfileTable])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  Stream<ProfileRow?> watchProfile(String uid) {
    return (select(
      profileTable,
    )..where((t) => t.uid.equals(uid))).watchSingleOrNull();
  }

  Future<ProfileRow?> getProfile(String uid) {
    return (select(
      profileTable,
    )..where((t) => t.uid.equals(uid))).getSingleOrNull();
  }

  Future<void> upsertProfile(ProfileTableCompanion row) {
    return into(profileTable).insertOnConflictUpdate(row);
  }
}
