import 'package:medify/core/database/settings_store.dart';
import 'package:medify/core/security/field_cipher.dart';
import 'package:medify/features/profiles/data/sqflite/profile_exceptions.dart';
import 'package:medify/features/profiles/data/sqflite/profile_row_mapper.dart';
import 'package:medify/features/profiles/domain/entities/user_profile.dart';
import 'package:medify/features/profiles/domain/repositories/user_profile_repository.dart';
import 'package:sqflite/sqflite.dart';

/// sqflite-backed [UserProfileRepository].
///
/// The active profile ID is stored in `settings` under [_activeKey]; the
/// `profiles` table has no column for it.
class ProfileSqfliteRepository implements UserProfileRepository {
  ProfileSqfliteRepository(this._db, this._cipher)
    : _settings = SettingsStore(_db);

  static const _activeKey = 'active_profile_id';

  final Database _db;
  final FieldCipher _cipher;
  final SettingsStore _settings;

  @override
  Future<List<UserProfile>> getAllProfiles() => _list();

  @override
  Future<UserProfile?> getProfileById(int id) => _byId(_db, id);

  @override
  Future<List<UserProfile>> getActiveProfiles() =>
      _list(where: 'is_archived = 0');

  @override
  Future<UserProfile> createProfile(UserProfile profile) async {
    return _db.transaction<UserProfile>((txn) async {
      // Encrypted columns need the row id as AAD, so insert, then re-seal.
      final id = await txn.insert(
        'profiles',
        await ProfileRowMapper.toRow(profile, _cipher, id: 0),
      );
      await txn.update(
        'profiles',
        await ProfileRowMapper.toRow(profile, _cipher, id: id),
        where: 'id = ?',
        whereArgs: [id],
      );
      return (await _byId(txn, id))!;
    });
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final id = profile.id;
    if (id == null) throw const InvalidProfileException('update needs an id');
    return _db.transaction<UserProfile>((txn) async {
      if (await _byId(txn, id) == null) throw ProfileNotFoundException(id);
      await txn.update(
        'profiles',
        await ProfileRowMapper.toRow(profile, _cipher, id: id),
        where: 'id = ?',
        whereArgs: [id],
      );
      return (await _byId(txn, id))!;
    });
  }

  /// Hard-deletes when nothing references the profile. Otherwise archives it
  /// (`is_archived = 1`). Medicines, occurrences (as patient or actor) and
  /// achievements all block a hard delete.
  @override
  Future<void> deleteProfile(int id) async {
    await _db.transaction<void>((txn) async {
      if (await _byId(txn, id) == null) throw ProfileNotFoundException(id);
      final refs = Sqflite.firstIntValue(
        await txn.rawQuery(
          '''
          SELECT (SELECT COUNT(*) FROM medicines WHERE profile_id = ?1)
               + (SELECT COUNT(*) FROM occurrences
                    WHERE profile_id = ?1 OR actor_profile_id = ?1)
               + (SELECT COUNT(*) FROM achievements WHERE profile_id = ?1)
          ''',
          [id],
        ),
      )!;
      if (refs == 0) {
        await txn.delete('profiles', where: 'id = ?', whereArgs: [id]);
      } else {
        await txn.update(
          'profiles',
          {
            'is_archived': 1,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
    // Runs after the transaction: SettingsStore writes through _db.
    if (await _settings.getInt(_activeKey, defaultValue: 0) == id) {
      await _settings.setInt(_activeKey, 0);
    }
  }

  @override
  Future<UserProfile?> getActiveProfile() async {
    final id = await _settings.getInt(_activeKey, defaultValue: 0);
    return id == 0 ? null : _byId(_db, id);
  }

  @override
  Future<void> setActiveProfile(int profileId) async {
    final profile = await _byId(_db, profileId);
    if (profile == null) throw ProfileNotFoundException(profileId);
    if (!profile.isActive) {
      throw const InvalidProfileException('profile is archived');
    }
    await _settings.setInt(_activeKey, profileId);
  }

  @override
  /// Names are encrypted, so matching runs in Dart. Case-insensitive
  /// substring match on name or relation, as the former LIKE query did.
  @override
  Future<List<UserProfile>> searchProfiles(String query) async {
    final needle = query.toLowerCase();
    final active = await _list(where: 'is_archived = 0');
    return active
        .where(
          (p) =>
              p.name.toLowerCase().contains(needle) ||
              (p.relationship ?? '').toLowerCase().contains(needle),
        )
        .toList();
  }

  @override
  Future<int> getProfileCount() async {
    return Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COUNT(*) FROM profiles WHERE is_archived = 0',
          ),
        ) ??
        0;
  }

  @override
  /// Names are encrypted, so the comparison runs in Dart over active rows.
  @override
  Future<bool> isProfileNameExists(String name, {int? excludeId}) async {
    final others = await _list(
      where: 'is_archived = 0 AND id != ?',
      whereArgs: [excludeId ?? -1],
    );
    return others.any((p) => p.name == name);
  }

  Future<List<UserProfile>> _list({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final rows = await _db.query(
      'profiles',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'id ASC',
    );
    return [
      for (final row in rows) await ProfileRowMapper.fromRow(row, _cipher),
    ];
  }

  Future<UserProfile?> _byId(DatabaseExecutor db, int id) async {
    final rows = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty
        ? null
        : await ProfileRowMapper.fromRow(rows.single, _cipher);
  }
}
