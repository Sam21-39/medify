import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/user_profile_repository.dart';
import '../medicine/medicine_cubit.dart';
import '../medicine_log/medicine_log_cubit.dart';
import 'profile_state.dart';

/// Cubit for managing user profile state
class ProfileCubit extends Cubit<ProfileState> {
  final UserProfileRepository _userProfileRepository;

  ProfileCubit(this._userProfileRepository) : super(ProfileInitial());

  /// Load all profiles
  Future<void> loadProfiles() async {
    try {
      emit(ProfileLoading());
      final profiles = await _userProfileRepository.getAllProfiles();
      final activeProfile = await _userProfileRepository.getActiveProfile();
      emit(ProfilesLoaded(profiles, activeProfile: activeProfile));
    } catch (e) {
      emit(ProfileError('Failed to load profiles: ${e.toString()}'));
    }
  }

  /// Load active profiles only
  Future<void> loadActiveProfiles() async {
    try {
      emit(ProfileLoading());
      final profiles = await _userProfileRepository.getActiveProfiles();
      final activeProfile = await _userProfileRepository.getActiveProfile();
      emit(ProfilesLoaded(profiles, activeProfile: activeProfile));
    } catch (e) {
      emit(ProfileError('Failed to load active profiles: ${e.toString()}'));
    }
  }

  /// Load a specific profile by ID
  Future<void> loadProfile(int id) async {
    try {
      emit(ProfileLoading());
      final profile = await _userProfileRepository.getProfileById(id);
      if (profile != null) {
        emit(ProfileLoaded(profile));
      } else {
        emit(const ProfileError('Profile not found'));
      }
    } catch (e) {
      emit(ProfileError('Failed to load profile: ${e.toString()}'));
    }
  }

  /// Get currently active profile
  Future<void> loadActiveProfile() async {
    try {
      final profile = await _userProfileRepository.getActiveProfile();
      if (profile != null) {
        emit(ActiveProfileChanged(profile));
      } else {
        emit(const ProfileError('No active profile found'));
      }
    } catch (e) {
      emit(ProfileError('Failed to load active profile: ${e.toString()}'));
    }
  }

  /// Create a new profile
  Future<void> createProfile(UserProfile profile) async {
    try {
      emit(ProfileLoading());

      // Check if name already exists
      final nameExists = await _userProfileRepository.isProfileNameExists(
        profile.name,
      );
      if (nameExists) {
        emit(const ProfileError('A profile with this name already exists'));
        return;
      }

      final createdProfile = await _userProfileRepository.createProfile(
        profile,
      );
      emit(
        ProfileOperationSuccess(
          'Profile created successfully',
          profile: createdProfile,
        ),
      );

      // Reload all profiles
      await loadProfiles();

      // Reload app data in case active profile changed
      _reloadAppData();
    } catch (e) {
      emit(ProfileError('Failed to create profile: ${e.toString()}'));
    }
  }

  /// Update an existing profile
  Future<void> updateProfile(UserProfile profile) async {
    try {
      emit(ProfileLoading());

      // Check if name already exists (excluding current profile)
      final nameExists = await _userProfileRepository.isProfileNameExists(
        profile.name,
        excludeId: profile.id,
      );
      if (nameExists) {
        emit(const ProfileError('A profile with this name already exists'));
        return;
      }

      final updatedProfile = await _userProfileRepository.updateProfile(
        profile,
      );
      emit(
        ProfileOperationSuccess(
          'Profile updated successfully',
          profile: updatedProfile,
        ),
      );

      // Reload all profiles
      await loadProfiles();

      // Reload app data to reflect any profile changes
      _reloadAppData();
    } catch (e) {
      emit(ProfileError('Failed to update profile: ${e.toString()}'));
    }
  }

  /// Delete a profile
  Future<void> deleteProfile(int id) async {
    try {
      emit(ProfileLoading());
      await _userProfileRepository.deleteProfile(id);
      emit(const ProfileOperationSuccess('Profile deleted successfully'));

      // Reload all profiles
      await loadProfiles();

      // Reload app data as active profile might have changed
      _reloadAppData();
    } catch (e) {
      emit(ProfileError('Failed to delete profile: ${e.toString()}'));
    }
  }

  /// Switch to a different profile
  Future<void> switchProfile(int profileId) async {
    try {
      // Set active profile in repository (updates database)
      await _userProfileRepository.setActiveProfile(profileId);

      // Reload all profiles first (this will have correct isActive flags)
      await loadProfiles();

      // Then emit success message
      final profile = await _userProfileRepository.getProfileById(profileId);
      if (profile != null) {
        emit(const ProfileOperationSuccess('Profile switched successfully'));

        // Reload medicines and logs for the new profile
        _reloadAppData();
      } else {
        emit(const ProfileError('Profile not found'));
      }
    } catch (e) {
      emit(ProfileError('Failed to switch profile: ${e.toString()}'));
    }
  }

  /// Reload medicines and logs after profile operations
  void _reloadAppData() {
    try {
      // Reload medicines for new profile
      getIt<MedicineCubit>().loadMedicines();

      // Reload today's logs for new profile
      getIt<MedicineLogCubit>().loadTodayLogs();
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Search profiles
  Future<void> searchProfiles(String query) async {
    try {
      emit(ProfileLoading());
      final profiles = await _userProfileRepository.searchProfiles(query);
      final activeProfile = await _userProfileRepository.getActiveProfile();
      emit(ProfilesLoaded(profiles, activeProfile: activeProfile));
    } catch (e) {
      emit(ProfileError('Failed to search profiles: ${e.toString()}'));
    }
  }

  /// Get profile count
  Future<int> getProfileCount() async {
    try {
      return await _userProfileRepository.getProfileCount();
    } catch (e) {
      return 0;
    }
  }
}
