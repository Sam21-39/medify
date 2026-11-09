import '../../core/services/profile_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';

/// Implementation of UserProfileRepository using ProfileService
class UserProfileRepositoryImpl implements UserProfileRepository {
  final ProfileService _profileService;

  UserProfileRepositoryImpl(this._profileService);

  @override
  Future<List<UserProfile>> getAllProfiles() {
    return _profileService.getAllProfiles();
  }

  @override
  Future<UserProfile?> getProfileById(int id) {
    return _profileService.getProfileById(id);
  }

  @override
  Future<List<UserProfile>> getActiveProfiles() {
    return _profileService.getActiveProfiles();
  }

  @override
  Future<UserProfile> createProfile(UserProfile profile) {
    return _profileService.createProfile(profile);
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) {
    return _profileService.updateProfile(profile);
  }

  @override
  Future<void> deleteProfile(int id) {
    return _profileService.deleteProfile(id);
  }

  @override
  Future<UserProfile?> getActiveProfile() {
    return _profileService.getActiveProfile();
  }

  @override
  Future<void> setActiveProfile(int profileId) {
    return _profileService.setActiveProfile(profileId);
  }

  @override
  Future<List<UserProfile>> searchProfiles(String query) {
    return _profileService.searchProfiles(query);
  }

  @override
  Future<int> getProfileCount() {
    return _profileService.getProfileCount();
  }

  @override
  Future<bool> isProfileNameExists(String name, {int? excludeId}) {
    return _profileService.isProfileNameExists(name, excludeId: excludeId);
  }
}

