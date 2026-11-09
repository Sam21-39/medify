# Profile Testing Guide

## Overview

This guide helps you test the Family/Caregiver Mode functionality to ensure everything works correctly.

## Recent Fixes

✅ **Auto-refresh on profile operations** - UI now updates immediately when switching, creating, updating, or deleting profiles
✅ **Active indicator positioning** - Badge properly aligned with profile name

---

## Testing Checklist

### 1. Profile Creation ✓

**Test: Create a new profile**

1. Open Settings → Family Profiles
2. Tap the (+) button
3. Select an avatar emoji
4. Choose a color
5. Enter name: "Mom"
6. Select relationship: "Mom"
7. Set date of birth (optional)
8. Tap "Create Profile"

**Expected Result:**

- ✅ Profile created successfully
- ✅ Toast shows "Profile created successfully"
- ✅ Profile appears in list
- ✅ Profile has correct avatar, color, and name
- ✅ **NEW: UI refreshes automatically**

---

### 2. Profile Switching ✓

**Test: Switch between profiles**

1. In Family Profiles page, tap on a profile
2. Select "Switch to this profile"
3. Observe the active indicator moves
4. Go back to home screen
5. Check medicines displayed

**Expected Result:**

- ✅ Toast shows "Switched to [Name]'s profile"
- ✅ Active indicator updates immediately
- ✅ **NEW: Home screen medicines refresh automatically**
- ✅ **NEW: No manual refresh needed**
- ✅ Only medicines for active profile shown

**Critical Test:**

```
1. Create Profile A with Medicine X
2. Create Profile B with Medicine Y
3. Switch to Profile A → Should see only Medicine X
4. Switch to Profile B → Should see only Medicine Y
5. Switch back to Profile A → Should see only Medicine X again
```

---

### 3. Profile Update ✓

**Test: Edit existing profile**

1. Tap on a profile card
2. Select "Edit profile"
3. Change name from "Mom" to "Mother"
4. Change color
5. Tap "Update Profile"

**Expected Result:**

- ✅ Toast shows "Profile updated successfully"
- ✅ Profile list updates immediately
- ✅ New name and color visible
- ✅ **NEW: If active profile, home screen reflects changes**

---

### 4. Profile Deletion ✓

**Test: Delete a profile**

1. Tap on a non-default profile
2. Select "Delete profile"
3. Confirm deletion in dialog

**Expected Result:**

- ✅ Confirmation dialog appears
- ✅ Profile deleted after confirmation
- ✅ Profile removed from list
- ✅ If deleted profile was active, switches to another
- ✅ **NEW: Home screen updates with new active profile's data**
- ✅ Cannot delete last profile
- ✅ Cannot delete default profile if only one exists

---

### 5. Active Indicator ✓

**Test: Visual indicator positioning**

1. Open Family Profiles
2. Look at profile cards
3. Find the active profile (should have green "Active" badge)

**Expected Result:**

- ✅ Badge is green with white text
- ✅ **NEW: Badge properly aligned (not floating above)**
- ✅ Badge positioned to the right of profile name
- ✅ Badge size is appropriate (not too large)
- ✅ Only one profile shows "Active" badge

**Visual Check:**

```
✓ GOOD:
   Name ─────────> [Active]

✗ BAD (OLD):
   Name
   ───────> [Active]  (floating above)
```

---

### 6. Data Isolation ✓

**Test: Medicines are profile-specific**

**Setup:**

1. Create 3 profiles: "Self", "Mom", "Dad"
2. Switch to "Self" → Add "Aspirin 100mg"
3. Switch to "Mom" → Add "Vitamin D 2000IU"
4. Switch to "Dad" → Add "Blood Pressure Med 10mg"

**Test:**

1. Switch to "Self" profile
   - ✅ Should see only "Aspirin"
   - ✅ **NEW: Updates immediately without refresh**
2. Switch to "Mom" profile
   - ✅ Should see only "Vitamin D"
   - ✅ **NEW: Updates immediately without refresh**
3. Switch to "Dad" profile
   - ✅ Should see only "Blood Pressure Med"
   - ✅ **NEW: Updates immediately without refresh**

---

### 7. Logs Isolation ✓

**Test: Logs are profile-specific**

**Setup:**

1. For "Self" → Take Aspirin at 9 AM
2. For "Mom" → Take Vitamin D at 10 AM
3. For "Dad" → Take BP Med at 11 AM

**Test:**

1. Switch to "Self"
   - ✅ History shows only Aspirin log
   - ✅ **NEW: Updates immediately**
2. Switch to "Mom"
   - ✅ History shows only Vitamin D log
   - ✅ **NEW: Updates immediately**
3. Switch to "Dad"
   - ✅ History shows only BP Med log
   - ✅ **NEW: Updates immediately**

---

### 8. Persistence ✓

**Test: Active profile persists**

1. Switch to "Mom" profile
2. Close app completely (force quit)
3. Reopen app

**Expected Result:**

- ✅ App opens with "Mom" still active
- ✅ Shows Mom's medicines
- ✅ Shows Mom's logs
- ✅ Settings → Family Profiles shows Mom as active

---

### 9. Edge Cases ✓

**Test: Duplicate names**

1. Create profile "John"
2. Try to create another "John"

**Expected Result:**

- ✅ Error: "A profile with this name already exists"
- ✅ Form validation prevents submission

**Test: Last profile deletion**

1. Create only 1 profile
2. Try to delete it

**Expected Result:**

- ✅ Delete option should be disabled
- ✅ Or error message if attempted

**Test: Rapid switching**

1. Quickly switch between 5 profiles
2. Check if UI updates correctly

**Expected Result:**

- ✅ No crashes
- ✅ Each switch loads correct data
- ✅ **NEW: All updates happen smoothly**
- ✅ No stale data shown

---

## Performance Testing

### Stress Test: Many Profiles

1. Create 10 profiles
2. Add 5 medicines to each
3. Switch between profiles rapidly

**Expected Result:**

- ✅ No lag or freezing
- ✅ Smooth transitions
- ✅ **NEW: Fast data refresh**
- ✅ All data correct

---

## Known Issues (None! ✓)

All reported issues have been fixed:

- ✅ ~~UI not updating on profile switch~~ → FIXED
- ✅ ~~Active indicator positioning off~~ → FIXED

---

## Developer Testing Commands

```bash
# Run the app on device
fvm flutter run --debug -d <device-id>

# Check for errors
fvm flutter analyze

# Check logs during testing
adb logcat | grep -i profile  # Android
# or
# Xcode console for iOS

# Test ObjectBox database
# Check profiles table
# Verify profileId in medicines and logs
```

---

## Testing Scenarios

### Scenario 1: Family Caregiver

**User**: Sarah (caregiver for elderly parents)

**Flow:**

1. Create "Self" profile
2. Add own medicines
3. Create "Mom" profile → Add Mom's 6 medications
4. Create "Dad" profile → Add Dad's 4 medications
5. Throughout day:
   - Switch to Mom → Mark morning meds taken
   - Switch to Dad → Mark breakfast meds taken
   - Switch to Self → Mark own meds taken
6. Check history for each profile

**Success Criteria:**

- ✅ Quick switching between profiles
- ✅ Correct medicines for each person
- ✅ **NEW: Instant UI updates**
- ✅ No confusion about whose meds

---

### Scenario 2: Multi-Child Family

**User**: Parent with 3 kids

**Flow:**

1. Create "Tommy (7)" → Daily vitamin
2. Create "Sarah (10)" → Asthma inhaler
3. Create "Baby Mike (2)" → Fever medicine (as needed)
4. Different colors/avatars for each
5. Use visual identification to quickly switch

**Success Criteria:**

- ✅ Easy visual distinction
- ✅ Quick profile switching
- ✅ **NEW: Immediate updates**
- ✅ Kid-friendly avatars

---

## Regression Testing

After any code changes, re-test:

1. ✅ Profile creation
2. ✅ Profile switching
3. ✅ **NEW: Auto-refresh functionality**
4. ✅ Medicine isolation
5. ✅ Log isolation
6. ✅ Persistence

---

## Conclusion

The Family/Caregiver Mode is fully functional and tested. All critical issues have been resolved:

✅ **UI Auto-Refresh**: Switching profiles instantly updates all screens
✅ **Active Indicator**: Properly positioned and sized
✅ **Data Isolation**: Complete separation between profiles
✅ **User Experience**: Smooth and intuitive

Ready for production! 🚀
