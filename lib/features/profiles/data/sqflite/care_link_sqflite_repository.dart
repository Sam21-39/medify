import 'package:medify/features/profiles/data/sqflite/profile_exceptions.dart';
import 'package:sqflite/sqflite.dart';

/// sqflite-backed care links: a caregiver may act for a patient.
///
/// Unlike the legacy repo, [link] rejects a duplicate pair instead of
/// returning silently (per P2b guidelines).
class CareLinkSqfliteRepository {
  CareLinkSqfliteRepository(this._db);

  final Database _db;

  Future<bool> canActFor({
    required int caregiverId,
    required int patientId,
  }) async {
    if (caregiverId == patientId) return true;
    return await _find(caregiverId: caregiverId, patientId: patientId) != null;
  }

  Future<void> link({required int caregiverId, required int patientId}) async {
    if (caregiverId == patientId) {
      throw const InvalidProfileException('a profile cannot link to itself');
    }
    await _db.transaction((txn) async {
      for (final id in [caregiverId, patientId]) {
        final rows = await txn.query(
          'profiles',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (rows.isEmpty) throw ProfileNotFoundException(id);
      }
      if (await _find(
            caregiverId: caregiverId,
            patientId: patientId,
            db: txn,
          ) !=
          null) {
        throw const InvalidProfileException('care link already exists');
      }
      await txn.insert('care_links', {
        'patient_profile_id': patientId,
        'caregiver_profile_id': caregiverId,
        'created_at_utc': DateTime.now().toUtc().millisecondsSinceEpoch,
      });
    });
  }

  Future<Map<String, Object?>?> _find({
    required int caregiverId,
    required int patientId,
    DatabaseExecutor? db,
  }) async {
    final rows = await (db ?? _db).query(
      'care_links',
      where: 'patient_profile_id = ? AND caregiver_profile_id = ?',
      whereArgs: [patientId, caregiverId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  }
}
