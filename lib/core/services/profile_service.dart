import 'dart:developer' as developer;

import '../../data/datasources/objectbox_service.dart';
import '../../data/models/user_profile_model.dart';
import '../../domain/entities/user_profile.dart';
import '../../objectbox.g.dart';
import 'preferences_service.dart';

/// Service for managing user profiles and profile switching
///
/// Handles:
/// - Profile CRUD operations
/// - Active profile management
/// - Profile caching
/// - Data isolation per profile
class ProfileService {
  final ObjectBoxService _objectBoxService;
  final PreferencesService _preferencesService;

  // Key for storing active profile ID in SharedPreferences
  static const String _keyActiveProfileId = 'active_profile_id';

  // Cache for active profile to reduce database queries
  UserProfile? _activeProfile;

  ProfileService(this._objectBoxService, this._preferencesService);

  /// Get the box for UserProfileModel
  Box<UserProfileModel> get _profileBox =>
      _objectBoxService.store.box<UserProfileModel>();

  /// Initialize profile service
  ///
  /// Creates default profile if none exists and loads active profile.
  /// Should be called once during app startup.
  Future<void> initialize() async {
    try {
      final allProfiles = await getAllProfiles();

      if (allProfiles.isEmpty) {
        developer.log('No profiles found. Creating default profile.');
        await _createDefaultProfile();
      } else {
        await _loadActiveProfile(allProfiles);
      }

      developer.log(
        'ProfileService initialized. Active profile: ${_activeProfile?.name}',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize ProfileService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Creates the default "Me" profile
  Future<void> _createDefaultProfile() async {
    final now = DateTime.now();
    final defaultProfile = UserProfile(
      name: 'Me',
      avatarEmoji: '👤',
      colorValue: ProfileColors.defaultColor,
      relationship: 'Self',
      isActive: true,
      isDefaultProfile: true,
      createdAt: now,
      updatedAt: now,
    );

    final savedProfile = await createProfile(defaultProfile);
    await setActiveProfile(savedProfile.id!);
    developer.log('Default profile created with ID: ${savedProfile.id}');
  }

  /// Loads the active profile from preferences or sets first profile as active
  Future<void> _loadActiveProfile(List<UserProfile> allProfiles) async {
    final activeProfileId = await _preferencesService.getInt(
      _keyActiveProfileId,
    );

    if (activeProfileId != null) {
      _activeProfile = await getProfileById(activeProfileId);
    }

    // Fallback: If no active profile or profile not found, use first profile
    if (_activeProfile == null && allProfiles.isNotEmpty) {
      _activeProfile = allProfiles.first;
      await setActiveProfile(_activeProfile!.id!);
      developer.log(
        'No active profile found. Set first profile as active: ${_activeProfile!.name}',
      );
    }
  }

  /// Get currently active profile
  Future<UserProfile?> getActiveProfile() async {
    if (_activeProfile != null) {
      return _activeProfile;
    }

    final activeProfileId = await _preferencesService.getInt(
      _keyActiveProfileId,
    );
    if (activeProfileId != null) {
      _activeProfile = await getProfileById(activeProfileId);
    }

    return _activeProfile;
  }

  /// Get active profile ID
  Future<int?> getActiveProfileId() async {
    final profile = await getActiveProfile();
    return profile?.id;
  }

  /// Set active profile by ID
  ///
  /// Updates the isActive flag in the database for all profiles and
  /// stores the active profile ID in SharedPreferences.
  ///
  /// Throws [Exception] if profile with [profileId] doesn't exist
  Future<void> setActiveProfile(int profileId) async {
    final profile = await getProfileById(profileId);
    if (profile == null) {
      throw Exception('Profile with ID $profileId not found');
    }

    try {
      // 1. Set all profiles to inactive in database
      final allProfiles = await getAllProfiles();
      for (final p in allProfiles) {
        if (p.isActive && p.id != profileId) {
          final inactiveProfile = p.copyWith(
            isActive: false,
            updatedAt: DateTime.now(),
          );
          final model = UserProfileModel.fromEntity(inactiveProfile);
          _profileBox.put(model);
          developer.log('Set profile ${p.name} (ID: ${p.id}) to inactive');
        }
      }

      // 2. Set selected profile to active in database
      final activeProfile = profile.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );
      final activeModel = UserProfileModel.fromEntity(activeProfile);
      _profileBox.put(activeModel);

      // 3. Update cache and preferences
      _activeProfile = activeProfile;
      await _preferencesService.setInt(_keyActiveProfileId, profileId);

      developer.log('Active profile set to: ${profile.name} (ID: $profileId)');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to set active profile',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create a new profile
  ///
  /// Returns the created profile with assigned ID
  /// Throws [Exception] if profile creation fails
  Future<UserProfile> createProfile(UserProfile profile) async {
    try {
      final model = UserProfileModel.fromEntity(profile);
      final id = _profileBox.put(model);
      final createdProfile = await getProfileById(id);

      if (createdProfile == null) {
        throw Exception('Failed to retrieve created profile');
      }

      developer.log('Profile created: ${createdProfile.name} (ID: $id)');
      return createdProfile;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to create profile',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update an existing profile
  ///
  /// Throws [Exception] if profile ID is null or profile doesn't exist
  Future<UserProfile> updateProfile(UserProfile profile) async {
    if (profile.id == null) {
      throw Exception('Cannot update profile: ID is null');
    }

    // Verify profile exists
    final existingProfile = await getProfileById(profile.id!);
    if (existingProfile == null) {
      throw Exception('Profile with ID ${profile.id} not found');
    }

    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
      final model = UserProfileModel.fromEntity(updatedProfile);
      _profileBox.put(model);

      // Update cached active profile if it's the one being updated
      if (_activeProfile?.id == profile.id) {
        _activeProfile = updatedProfile;
      }

      developer.log(
        'Profile updated: ${updatedProfile.name} (ID: ${profile.id})',
      );
      return updatedProfile;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to update profile',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a profile by ID
  ///
  /// Automatically switches to another profile if deleting the active one.
  /// Throws [Exception] if:
  /// - Trying to delete the last profile
  /// - Profile doesn't exist
  Future<void> deleteProfile(int profileId) async {
    try {
      final allProfiles = await getAllProfiles();

      // Validate: Cannot delete last profile
      if (allProfiles.length <= 1) {
        throw Exception(
          'Cannot delete the last profile. At least one profile must exist.',
        );
      }

      // Verify profile exists
      final profile = await getProfileById(profileId);
      if (profile == null) {
        throw Exception('Profile with ID $profileId not found');
      }

      // If deleting active profile, switch to another one first
      if (_activeProfile?.id == profileId) {
        final otherProfile = allProfiles.firstWhere((p) => p.id != profileId);
        await setActiveProfile(otherProfile.id!);
        developer.log(
          'Deleting active profile. Switched to: ${otherProfile.name}',
        );
      }

      // Perform deletion
      final success = _profileBox.remove(profileId);
      if (!success) {
        throw Exception('Failed to delete profile from database');
      }

      developer.log('Profile deleted: ${profile.name} (ID: $profileId)');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete profile',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get a profile by ID
  Future<UserProfile?> getProfileById(int id) async {
    final model = _profileBox.get(id);
    return model?.toEntity();
  }

  /// Get all profiles
  Future<List<UserProfile>> getAllProfiles() async {
    final models = _profileBox.getAll();
    return models.map((model) => model.toEntity()).toList();
  }

  /// Get all active profiles
  Future<List<UserProfile>> getActiveProfiles() async {
    final query = _profileBox
        .query(UserProfileModel_.isActive.equals(true))
        .build();
    final models = query.find();
    query.close();
    return models.map((model) => model.toEntity()).toList();
  }

  /// Get profiles by relationship
  Future<List<UserProfile>> getProfilesByRelationship(
    String relationship,
  ) async {
    final query = _profileBox
        .query(UserProfileModel_.relationship.equals(relationship))
        .build();
    final models = query.find();
    query.close();
    return models.map((model) => model.toEntity()).toList();
  }

  /// Search profiles by name or relationship
  ///
  /// Case-insensitive search that matches partial text
  Future<List<UserProfile>> searchProfiles(String searchQuery) async {
    if (searchQuery.trim().isEmpty) {
      return getAllProfiles();
    }

    final allProfiles = await getAllProfiles();
    final lowercaseQuery = searchQuery.toLowerCase().trim();

    return allProfiles.where((profile) {
      final nameMatch = profile.name.toLowerCase().contains(lowercaseQuery);
      final relationshipMatch =
          profile.relationship?.toLowerCase().contains(lowercaseQuery) ?? false;
      return nameMatch || relationshipMatch;
    }).toList();
  }

  /// Get total count of profiles
  Future<int> getProfileCount() async {
    return _profileBox.count();
  }

  /// Check if a profile name already exists
  ///
  /// Case-insensitive comparison
  /// Use [excludeId] when updating a profile to exclude itself from the check
  Future<bool> isProfileNameExists(String name, {int? excludeId}) async {
    final trimmedName = name.trim().toLowerCase();

    if (trimmedName.isEmpty) {
      return false;
    }

    final allProfiles = await getAllProfiles();
    return allProfiles.any(
      (profile) =>
          profile.name.toLowerCase() == trimmedName && profile.id != excludeId,
    );
  }

  /// Toggle profile active/inactive status
  ///
  /// Note: This doesn't affect the "active profile" (currently selected).
  /// It's for marking profiles as enabled/disabled.
  Future<void> toggleProfileStatus(int profileId) async {
    final profile = await getProfileById(profileId);
    if (profile == null) {
      throw Exception('Profile with ID $profileId not found');
    }

    await updateProfile(profile.copyWith(isActive: !profile.isActive));
    developer.log(
      'Profile status toggled: ${profile.name} -> ${!profile.isActive}',
    );
  }

  /// Get profile statistics
  ///
  /// Returns medicine count, adherence, and other metrics for a profile.
  /// Currently returns placeholder data. Will be implemented with
  /// medicine/log repositories.
  Future<Map<String, dynamic>> getProfileStatistics(int profileId) async {
    // TODO: Implement with MedicineRepository and MedicineLogRepository
    return {
      'medicineCount': 0,
      'todayDoses': 0,
      'adherenceRate': 0.0,
      'currentStreak': 0,
    };
  }

  /// Clear the active profile cache
  ///
  /// Use when you need to force reload of active profile from storage.
  /// Generally not needed as cache is managed automatically.
  void clearCache() {
    _activeProfile = null;
    developer.log('Profile cache cleared');
  }
}
