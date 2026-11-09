# 🐛 Profile System Bugs Analysis

## Issues Identified

### **Issue 1: `isActive` Field Not Updated in Database** 🔴 CRITICAL

**Problem:**

- The `UserProfile.isActive` field in the database is **NEVER updated** when switching profiles
- `ProfileService.setActiveProfile()` only stores the active profile ID in SharedPreferences
- All profiles in the database have `isActive = true` (default from creation)
- The UI checks `profile.id == activeProfile?.id` instead of `profile.isActive`

**Evidence:**

```dart
// ProfileService.setActiveProfile() - Lines 124-133
Future<void> setActiveProfile(int profileId) async {
  final profile = await getProfileById(profileId);
  if (profile == null) {
    throw Exception('Profile with ID $profileId not found');
  }

  _activeProfile = profile;
  await _preferencesService.setInt(_keyActiveProfileId, profileId); // ← Only sets in prefs
  developer.log('Active profile set to: ${profile.name} (ID: $profileId)');
  // ❌ Missing: Update isActive flag in database for all profiles
}
```

**Current Database State:**

```
Profile 1: isActive = true  (created with default)
Profile 2: isActive = true  (created with default)
Profile 3: isActive = true  (created with default)
Active Profile ID in Prefs: 2
```

**Fix Needed:**

```dart
Future<void> setActiveProfile(int profileId) async {
  final profile = await getProfileById(profileId);
  if (profile == null) {
    throw Exception('Profile with ID $profileId not found');
  }

  // 1. Set all profiles to inactive
  final allProfiles = await getAllProfiles();
  for (final p in allProfiles) {
    if (p.isActive) {
      final inactive = UserProfileModel.fromEntity(
        p.copyWith(isActive: false, updatedAt: DateTime.now()),
      );
      _profileBox.put(inactive);
    }
  }

  // 2. Set selected profile to active
  final activeModel = UserProfileModel.fromEntity(
    profile.copyWith(isActive: true, updatedAt: DateTime.now()),
  );
  _profileBox.put(activeModel);

  // 3. Update cache and preferences
  _activeProfile = profile.copyWith(isActive: true);
  await _preferencesService.setInt(_keyActiveProfileId, profileId);

  developer.log('Active profile set to: ${profile.name} (ID: $profileId)');
}
```

---

### **Issue 2: ProfileCubit State Emission Order** 🟠 HIGH

**Problem:**

- `switchProfile()` emits `ActiveProfileChanged` **before** `loadProfiles()`
- Then `loadProfiles()` emits `ProfilesLoaded`, **overriding** the `ActiveProfileChanged` state
- UI listening to `ActiveProfileChanged` never receives it properly

**Evidence:**

```dart
// ProfileCubit.switchProfile() - Lines 155-175
Future<void> switchProfile(int profileId) async {
  try {
    await _userProfileRepository.setActiveProfile(profileId);
    final profile = await _userProfileRepository.getProfileById(profileId);

    if (profile != null) {
      emit(ActiveProfileChanged(profile));                    // ← Emitted first
      emit(const ProfileOperationSuccess('Profile switched')); // ← Then success
      _reloadAppData();                                        // ← Reload other cubits
      await loadProfiles();                                    // ← Then loadProfiles emits ProfilesLoaded, overriding ActiveProfileChanged!
    } else {
      emit(const ProfileError('Profile not found'));
    }
  } catch (e) {
    emit(ProfileError('Failed to switch profile: ${e.toString()}'));
  }
}
```

**Fix Needed:**

```dart
Future<void> switchProfile(int profileId) async {
  try {
    await _userProfileRepository.setActiveProfile(profileId);

    // Reload all profiles first (this will have correct active status)
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
```

---

### **Issue 3: ProfilesPage Switch Doesn't Refresh** 🟡 MEDIUM

**Problem:**

- When switching profile from the bottom sheet in `ProfilesPage`
- It calls `getIt<ProfileCubit>().switchProfile()` which is a **different instance**
- The page's `_profileCubit` instance doesn't receive state updates
- UI doesn't refresh, active tag doesn't change

**Evidence:**

```dart
// profiles_page.dart - Lines 380-385
onTap: () {
  Navigator.pop(sheetContext);
  if (!isActive && profile.id != null) {
    getIt<ProfileCubit>().switchProfile(profile.id!); // ← Different cubit instance!
  }
},
```

**Fix Needed:**

```dart
// Pass the cubit instance to the method
void _showProfileOptions(
  BuildContext context,
  UserProfile profile,
  bool isActive,
) {
  showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.switch_account),
            title: const Text('Switch to this profile'),
            enabled: !isActive,
            onTap: () {
              Navigator.pop(sheetContext);
              if (!isActive && profile.id != null) {
                // Use the cubit from context, not getIt
                getIt<ProfileCubit>().switchProfile(profile.id!);
              }
            },
          ),
          // ...
        ],
      ),
    ),
  );
}
```

---

### **Issue 4: ProfileSwitcher Creates New BlocProvider** 🟡 MEDIUM

**Problem:**

- `ProfileSwitcher` widget creates a **new** `BlocProvider` each time it's built
- This new provider has its own cubit instance
- State changes from other parts of the app don't reach this widget
- Widget shows stale/outdated profile info

**Evidence:**

```dart
// profile_switcher.dart - Lines 16-22
@override
Widget build(BuildContext context) {
  return BlocProvider(
    create: (_) => getIt<ProfileCubit>()..loadActiveProfiles(), // ← New provider!
    child: const _ProfileSwitcherContent(),
  );
}
```

**Fix Needed:**

```dart
@override
Widget build(BuildContext context) {
  // Use BlocProvider.value to share existing cubit
  return BlocProvider.value(
    value: getIt<ProfileCubit>(),
    child: BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        // Load profiles if not loaded
        if (state is ProfileInitial) {
          getIt<ProfileCubit>().loadActiveProfiles();
        }
        return const _ProfileSwitcherContent();
      },
    ),
  );
}
```

---

## Root Causes Summary

1. **Database Inconsistency**: `isActive` field never updated in ObjectBox
2. **State Management**: Multiple cubit instances instead of single shared instance
3. **State Emission Order**: Wrong order causes UI to miss important state changes
4. **Widget Architecture**: Creating new providers instead of sharing existing ones

---

## Impact

- ✅ **Data is saved correctly** (profiles, medicines, logs)
- ❌ **UI doesn't reflect changes** immediately
- ❌ **Active indicator doesn't update** after switching
- ❌ **Multiple cubit instances** cause synchronization issues
- ❌ **Page doesn't refresh** after operations

---

## Fixes Priority

1. **🔴 Critical**: Fix `ProfileService.setActiveProfile()` to update database
2. **🟠 High**: Fix `ProfileCubit.switchProfile()` state emission order
3. **🟡 Medium**: Fix `ProfilesPage` to use context cubit
4. **🟡 Medium**: Fix `ProfileSwitcher` to use shared cubit instance

---

## Testing Checklist After Fixes

- [ ] Create new profile → Active tag appears immediately
- [ ] Switch profile → Active tag moves to new profile
- [ ] Edit profile → Changes appear immediately
- [ ] Delete profile → Active profile switches, UI updates
- [ ] Restart app → Correct profile is active
- [ ] ProfileSwitcher shows correct active profile
- [ ] ProfilesPage shows correct active indicator
- [ ] Medicines filter by active profile immediately after switch
- [ ] Logs filter by active profile immediately after switch
