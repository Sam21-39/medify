import 'package:objectbox/objectbox.dart';
import '../../domain/entities/user_profile.dart';

/// ObjectBox model for UserProfile entity
@Entity()
class UserProfileModel {
  @Id()
  int id;

  String name;
  String? avatarEmoji;
  int colorValue;
  String? relationship;

  @Property(type: PropertyType.date)
  DateTime? dateOfBirth;

  String? notes;
  bool isActive;
  bool isDefaultProfile;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  UserProfileModel({
    this.id = 0,
    required this.name,
    this.avatarEmoji,
    required this.colorValue,
    this.relationship,
    this.dateOfBirth,
    this.notes,
    this.isActive = true,
    this.isDefaultProfile = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create model from entity
  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      id: profile.id ?? 0,
      name: profile.name,
      avatarEmoji: profile.avatarEmoji,
      colorValue: profile.colorValue,
      relationship: profile.relationship,
      dateOfBirth: profile.dateOfBirth,
      notes: profile.notes,
      isActive: profile.isActive,
      isDefaultProfile: profile.isDefaultProfile,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  /// Convert to entity
  UserProfile toEntity() {
    return UserProfile(
      id: id,
      name: name,
      avatarEmoji: avatarEmoji,
      colorValue: colorValue,
      relationship: relationship,
      dateOfBirth: dateOfBirth,
      notes: notes,
      isActive: isActive,
      isDefaultProfile: isDefaultProfile,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

