import '../entities/user_profile.dart';

/// Abstract repository interface for UserProfile operations
abstract class UserProfileRepository {
  /// Get all user profiles
  Future<List<UserProfile>> getAllProfiles();

  /// Get a user profile by ID
  Future<UserProfile?> getProfileById(int id);

  /// Get active profiles only
  Future<List<UserProfile>> getActiveProfiles();

  /// Create a new user profile
  Future<UserProfile> createProfile(UserProfile profile);

  /// Update an existing user profile
  Future<UserProfile> updateProfile(UserProfile profile);

  /// Delete a user profile
  Future<void> deleteProfile(int id);

  /// Get currently active profile
  Future<UserProfile?> getActiveProfile();

  /// Set active profile
  Future<void> setActiveProfile(int profileId);

  /// Search profiles by name or relationship
  Future<List<UserProfile>> searchProfiles(String query);

  /// Get profile count
  Future<int> getProfileCount();

  /// Check if profile name exists
  Future<bool> isProfileNameExists(String name, {int? excludeId});
}

