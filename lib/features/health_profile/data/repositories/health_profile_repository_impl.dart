import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/health_profile.dart';
import '../../domain/repositories/health_profile_repository.dart';
import '../local/profile_dao.dart';

@LazySingleton(as: HealthProfileRepository)
class HealthProfileRepositoryImpl implements HealthProfileRepository {
  HealthProfileRepositoryImpl(this._dao, this._firestore);

  final ProfileDao _dao;
  final FirebaseFirestore _firestore;

  HealthProfile _toEntity(ProfileRow row) => HealthProfile(
    uid: row.uid,
    fullName: row.fullName,
    age: row.age,
    gender: row.gender,
    bloodGroup: row.bloodGroup,
    allergies: row.allergies.isEmpty ? [] : row.allergies.split(','),
    chronicConditions: row.chronicConditions.isEmpty
        ? []
        : row.chronicConditions.split(','),
    emergencyContactName: row.emergencyContactName,
    emergencyContactPhone: row.emergencyContactPhone,
    doctorName: row.doctorName,
    doctorPhone: row.doctorPhone,
    updatedAt: row.updatedAt,
  );

  ProfileTableCompanion _toRow(HealthProfile profile) => ProfileTableCompanion(
    uid: Value(profile.uid),
    fullName: Value(profile.fullName),
    age: Value(profile.age),
    gender: Value(profile.gender),
    bloodGroup: Value(profile.bloodGroup),
    allergies: Value(profile.allergies.join(',')),
    chronicConditions: Value(profile.chronicConditions.join(',')),
    emergencyContactName: Value(profile.emergencyContactName),
    emergencyContactPhone: Value(profile.emergencyContactPhone),
    doctorName: Value(profile.doctorName),
    doctorPhone: Value(profile.doctorPhone),
    updatedAt: Value(profile.updatedAt),
  );

  @override
  Stream<HealthProfile?> watchProfile(String uid) {
    return _dao
        .watchProfile(uid)
        .map((row) => row == null ? null : _toEntity(row));
  }

  @override
  Future<HealthProfile?> getProfile(String uid) async {
    final row = await _dao.getProfile(uid);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> saveProfile(HealthProfile profile) async {
    await _dao.upsertProfile(_toRow(profile));

    // Best-effort one-shot mirror to Firestore - not the full sync/conflict
    // engine (that's Phase 1.6), just enough for later phases to build on.
    unawaited(
      _firestore
          .collection('users')
          .doc(profile.uid)
          .collection('profile')
          .doc('data')
          .set({
            'fullName': profile.fullName,
            'age': profile.age,
            'gender': profile.gender,
            'bloodGroup': profile.bloodGroup,
            'allergies': profile.allergies,
            'chronicConditions': profile.chronicConditions,
            'emergencyContactName': profile.emergencyContactName,
            'emergencyContactPhone': profile.emergencyContactPhone,
            'doctorName': profile.doctorName,
            'doctorPhone': profile.doctorPhone,
            'updatedAt': profile.updatedAt.toIso8601String(),
          }),
    );
  }
}
