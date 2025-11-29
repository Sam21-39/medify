class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final bool emailVerified;
  final UserPreferences preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.emailVerified,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'preferences': preferences.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON (Firestore)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      emailVerified: json['emailVerified'] ?? false,
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    bool? emailVerified,
    UserPreferences? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// User Preferences Class
class UserPreferences {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int reminderAdvanceMinutes; // Minutes before scheduled time
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  final String theme; // 'light', 'dark', 'system'

  UserPreferences({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.reminderAdvanceMinutes = 0,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.theme = 'system',
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'reminderAdvanceMinutes': reminderAdvanceMinutes,
      'quietHoursStart': quietHoursStart != null 
          ? '${quietHoursStart!.hour}:${quietHoursStart!.minute}' 
          : null,
      'quietHoursEnd': quietHoursEnd != null 
          ? '${quietHoursEnd!.hour}:${quietHoursEnd!.minute}' 
          : null,
      'theme': theme,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      reminderAdvanceMinutes: json['reminderAdvanceMinutes'] ?? 0,
      quietHoursStart: json['quietHoursStart'] != null 
          ? _parseTimeOfDay(json['quietHoursStart']) 
          : null,
      quietHoursEnd: json['quietHoursEnd'] != null 
          ? _parseTimeOfDay(json['quietHoursEnd']) 
          : null,
      theme: json['theme'] ?? 'system',
    );
  }

  static TimeOfDay _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  UserPreferences copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? reminderAdvanceMinutes,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    String? theme,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      reminderAdvanceMinutes: reminderAdvanceMinutes ?? this.reminderAdvanceMinutes,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      theme: theme ?? this.theme,
    );
  }
}

// TimeOfDay class for preferences (simple implementation)
class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});
}
