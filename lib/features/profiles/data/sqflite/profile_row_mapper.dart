import 'package:medify/core/database/enums.dart';
import 'package:medify/features/profiles/data/sqflite/profile_exceptions.dart';
import 'package:medify/features/profiles/domain/entities/user_profile.dart';

/// Maps `profiles` rows to [UserProfile].
///
/// Domain `role` is an int (0 patient, 1 caregiver); the column stores
/// [ProfileRole] by name. `isActive` is the inverse of `is_archived`.
class ProfileRowMapper {
  ProfileRowMapper._();

  static Map<String, Object?> toRow(UserProfile p) {
    if (p.role < 0 || p.role >= ProfileRole.values.length) {
      throw InvalidProfileException('unknown role ${p.role}');
    }
    return {
      'name': p.name,
      'relation': p.relationship,
      'date_of_birth': p.dateOfBirth?.millisecondsSinceEpoch,
      'role': ProfileRole.values[p.role].name,
      'color_value': p.colorValue,
      'avatar_emoji': p.avatarEmoji,
      'notes': p.notes,
      'is_default': p.isDefaultProfile ? 1 : 0,
      'is_archived': p.isActive ? 0 : 1,
      'created_at': p.createdAt.millisecondsSinceEpoch,
      'updated_at': p.updatedAt.millisecondsSinceEpoch,
    };
  }

  static UserProfile fromRow(Map<String, Object?> row) {
    final roleName = row['role'] as String;
    final role = ProfileRole.values
        .where((r) => r.name == roleName)
        .firstOrNull;
    if (role == null) {
      throw StateError('Unknown profiles.role value: $roleName');
    }
    final dob = row['date_of_birth'] as int?;
    return UserProfile(
      id: row['id'] as int,
      name: row['name'] as String,
      relationship: row['relation'] as String?,
      dateOfBirth: dob == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dob),
      role: role.index,
      colorValue: row['color_value'] as int,
      avatarEmoji: row['avatar_emoji'] as String?,
      notes: row['notes'] as String?,
      isDefaultProfile: row['is_default'] == 1,
      isActive: row['is_archived'] == 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}
