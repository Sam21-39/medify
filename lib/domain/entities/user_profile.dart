import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// User profile entity for multi-user support
class UserProfile extends Equatable {
  final int? id;
  final String name;
  final String? avatarEmoji; // Emoji avatar (e.g., 👨, 👩, 👴, 👵, 👦, 👧)
  final int colorValue; // Color for profile identification
  final String? relationship; // Mom, Dad, Self, Grandma, etc.
  final DateTime? dateOfBirth;
  final String? notes;
  final bool isActive;
  final bool isDefaultProfile;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    this.id,
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

  /// Get color from colorValue
  Color get color => Color(colorValue);

  /// Get age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Get display name with relationship
  String get displayName {
    if (relationship != null && relationship!.isNotEmpty) {
      return '$name ($relationship)';
    }
    return name;
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    int? id,
    String? name,
    String? avatarEmoji,
    int? colorValue,
    String? relationship,
    DateTime? dateOfBirth,
    String? notes,
    bool? isActive,
    bool? isDefaultProfile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      colorValue: colorValue ?? this.colorValue,
      relationship: relationship ?? this.relationship,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      isDefaultProfile: isDefaultProfile ?? this.isDefaultProfile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatarEmoji,
        colorValue,
        relationship,
        dateOfBirth,
        notes,
        isActive,
        isDefaultProfile,
        createdAt,
        updatedAt,
      ];
}

/// Predefined avatar emojis for quick selection
class ProfileAvatars {
  static const List<String> all = [
    '👨', // Man
    '👩', // Woman
    '👴', // Old man
    '👵', // Old woman
    '👦', // Boy
    '👧', // Girl
    '🧑', // Person
    '👶', // Baby
    '🧔', // Bearded person
    '👨‍🦳', // Man: White hair
    '👩‍🦳', // Woman: White hair
    '👨‍🦱', // Man: Curly hair
    '👩‍🦱', // Woman: Curly hair
    '🧓', // Older person
  ];

  static const String defaultAvatar = '👤';
}

/// Predefined profile colors
class ProfileColors {
  static const List<int> all = [
    0xFF14B8A6, // Teal
    0xFFEF4444, // Red
    0xFF3B82F6, // Blue
    0xFF10B981, // Green
    0xFFF59E0B, // Amber
    0xFF9C27B0, // Purple
    0xFFFF6B6B, // Pink
    0xFF4ECDC4, // Cyan
    0xFFFFBE0B, // Yellow
    0xFFFF006E, // Magenta
    0xFF8338EC, // Violet
    0xFFFF8500, // Orange
  ];

  static const int defaultColor = 0xFF14B8A6; // Teal
}

/// Predefined relationship types
class ProfileRelationships {
  static const List<String> all = [
    'Self',
    'Mom',
    'Dad',
    'Grandma',
    'Grandpa',
    'Spouse',
    'Partner',
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Uncle',
    'Aunt',
    'Friend',
    'Other',
  ];
}

