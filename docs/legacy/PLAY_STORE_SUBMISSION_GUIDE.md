# Play Store Submission - Step-by-Step Guide

**Date Started:** October 16, 2025  
**Target:** Google Play Store Launch

---

## 🚀 Phase 1: Pre-Submission Setup (30-60 minutes)

### ✅ Step 1: Update Android Configuration

#### 1.1 Update Package Name & Version

Open `android/app/build.gradle` and update:

```gradle
android {
    namespace "com.sumit.medify"  // Update this
    compileSdk 34                // Update from 33 to 34

    defaultConfig {
        applicationId "com.sumit.medify"  // Update this
        minSdkVersion 21
        targetSdkVersion 34  // Update from 33 to 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

**Current Status:** ⏳ Needs update

---

#### 1.2 Update Root build.gradle (Android SDK)

Open `android/build.gradle` and ensure:

```gradle
buildscript {
    ext.kotlin_version = '1.9.0'  // or latest stable
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'  // or latest
    }
}
```

**Current Status:** ⏳ Needs verification

---

### ✅ Step 2: Generate App Signing Key

**CRITICAL:** This keystore is needed to sign your app. Never lose it!

#### 2.1 Generate Keystore

Run this command in terminal:

```bash
keytool -genkey -v -keystore ~/medify-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias medify-upload
```

**You'll be asked:**

- Password: Choose a STRONG password (save it securely!)
- Name: Your name
- Organization: Medify or your organization
- Location: Your city
- State: Your state
- Country Code: Your 2-letter country code (e.g., IN for India, US for USA)

**Save these securely:**

- Keystore password: **\*\***\_\_\_**\*\***
- Key alias: `medify-upload`
- Keystore location: `~/medify-upload-keystore.jks`

#### 2.2 Create key.properties File

Create file: `android/key.properties`

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEYSTORE_PASSWORD
keyAlias=medify-upload
storeFile=/Users/sumitpal/medify-upload-keystore.jks
```

**⚠️ IMPORTANT:** Add this to `.gitignore` - never commit passwords!

#### 2.3 Update android/app/build.gradle for Signing

Add this BEFORE `android {`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ... other release config ...
        }
    }
}
```

**Current Status:** ⏳ Needs setup

---

### ✅ Step 3: Build Release App Bundle

#### 3.1 Clean Build

```bash
fvm flutter clean
fvm flutter pub get
```

#### 3.2 Build App Bundle

```bash
fvm flutter build appbundle --release
```

**Output location:** `build/app/outputs/bundle/release/app-release.aab`

**Check file size:**

```bash
ls -lh build/app/outputs/bundle/release/app-release.aab
```

Target: < 50MB ✅

#### 3.3 Test Release Build (Optional but Recommended)

```bash
fvm flutter build apk --release
fvm flutter install --release
```

Test all features on physical device!

**Current Status:** ⏳ Needs execution

---

### ✅ Step 4: Verify Privacy Policy is Live

Check: https://sumit-piston.github.io/medify/PRIVACY_POLICY

**Status:** ⏳ Needs verification

If not live:

1. Go to: https://github.com/Sumit-Piston/medify/settings/pages
2. Enable GitHub Pages (main branch, root folder)
3. Wait 2-3 minutes

---

## 🎨 Phase 2: Create Store Assets (60-90 minutes)

### ✅ Step 5: Create Required Graphics

#### 5.1 High-Res App Icon (512x512 PNG)

**Requirements:**

- Size: 512x512 pixels
- Format: PNG (32-bit)
- No transparency
- Full bleed (no padding)

**Tool:** Use Figma, Canva, or PhotoShop
**Source:** Your app icon from `assets/icons/app_icon.png` (resize to 512x512)

**Save as:** `store-assets/icon-512x512.png`

---

#### 5.2 Feature Graphic (1024x500 PNG/JPG)

**Requirements:**

- Size: 1024x500 pixels
- Format: PNG or JPG
- Showcases app key feature
- Text-free or minimal text

**Design Ideas:**

- Medicine reminder concept
- App screenshots with overlay
- Gradient background with app name and tagline

**Template suggestion:**

```
[Medify Logo] + "Never Miss Your Medicine"
+ Phone mockup showing the app
+ Teal gradient background (#14B8A6)
```

**Save as:** `store-assets/feature-graphic-1024x500.png`

---

#### 5.3 Screenshots (Minimum 2, Maximum 8)

**Requirements:**

- Size: 1080x1920 (Portrait) or 1920x1080 (Landscape)
- Format: PNG or JPG
- Show key features
- Can include device frames

**Recommended Screenshots:**

1. **Home Screen / Medicine List**

   - Show medicines with schedules
   - Today's summary card visible

2. **Add Medicine Screen**

   - Form with filled information
   - Shows ease of use

3. **Today's Schedule**

   - Show timeline/grouped by time
   - Progress indicators

4. **Statistics/Progress**

   - Charts and adherence tracking
   - Streak information

5. **Notification Example**

   - Screenshot of notification
   - Or mockup showing notification

6. **Settings & Theme**
   - Show dark/light mode toggle
   - Settings options

**How to capture:**

```bash
# Connect device and run app
fvm flutter run --release

# Take screenshots using Android Studio Device Manager
# Or use: adb shell screencap -p /sdcard/screenshot.png
```

**Save as:** `store-assets/screenshot-1.png`, `screenshot-2.png`, etc.

---

## 🏪 Phase 3: Play Console Setup (30-45 minutes)

### ✅ Step 6: Create Play Console Account

#### 6.1 Sign Up

1. Go to: https://play.google.com/console
2. Sign in with Google Account
3. Pay **$25 USD** one-time registration fee
4. Accept Developer Distribution Agreement
5. Complete developer profile

**Account Info:**

- Developer name: Sumit Pal (or your preferred name)
- Email: sumit.piston@gmail.com (public-facing)
- Website: https://github.com/Sumit-Piston/medify (optional)

---

#### 6.2 Create New App

1. Click **"Create app"**
2. Fill in details:
   - **App name:** Medify
   - **Default language:** English (United States)
   - **App or game:** App
   - **Free or paid:** Free
   - **Declarations:**
     - ✅ Developer Program Policies
     - ✅ US export laws

---

### ✅ Step 7: Complete Dashboard Setup Tasks

#### 7.1 App Access

- **All functionality available without special access:** Yes
- **Are there any restrictions?** No

---

#### 7.2 Ads

- **Does your app contain ads?** No

---

#### 7.3 Content Rating

Fill out questionnaire:

**App Category:** Health & Fitness or Medical

**Questions (General):**

- Violence: No
- Sexual content: No
- Language: No
- Controlled substances: No (medication management, not promotion)
- User interaction: No
- User-generated content: No
- Shares location: No
- Personal information: No

**Expected Rating:** Everyone or PEGI 3

---

#### 7.4 Target Audience & Content

**Age range:** 13+ or 18+ (recommended for medication management)

**Appeal to children:** No

---

#### 7.5 News Apps

**Is this a news app?** No

---

#### 7.6 COVID-19 Contact Tracing

**Is this a COVID-19 contact tracing or status app?** No

---

#### 7.7 Data Safety

This is CRITICAL. Fill carefully:

**Data Collection:**

- **Do you collect or share user data?** No

**Data types NOT collected:**

- ✅ Location
- ✅ Personal info (name, email, etc.)
- ✅ Financial info
- ✅ Health & fitness data (stored locally only!)
- ✅ Messages
- ✅ Photos/videos
- ✅ Audio
- ✅ Files
- ✅ App activity
- ✅ Web browsing
- ✅ App info and performance
- ✅ Device or other IDs

**Security practices:**

- ✅ Data is encrypted in transit (HTTPS if used)
- ✅ Users can request data deletion (uninstall app)
- ✅ Data is NOT encrypted at rest (ObjectBox local storage)

**Privacy Policy:** https://sumit-piston.github.io/medify/PRIVACY_POLICY

---

#### 7.8 Government Apps

**Is this an official government app?** No

---

#### 7.9 Financial Features

**Does your app sell financial products?** No

---

#### 7.10 Health Apps

**Is this a health app?** Yes - Medication reminder/tracker

**Does it have sensitive health features?** No (just reminders, no diagnosis)

---

### ✅ Step 8: Store Presence - Main Store Listing

#### 8.1 App Details

**App name:** Medify

**Short description (80 characters max):**

```
Never miss your medicine. Smart reminders & progress tracking.
```

**Full description (4000 characters max):**

```
Medify - Your Personal Medicine Reminder & Tracker

Never miss a dose again! Medify helps you stay on track with your medications through smart reminders and comprehensive progress tracking.

KEY FEATURES:

💊 MEDICINE MANAGEMENT
• Add unlimited medicines with custom schedules
• Set multiple daily reminders per medicine
• Add dosage, timing instructions, and notes
• Edit or pause medicines anytime

⏰ SMART REMINDERS
• Reliable notifications that you won't miss
• Snooze for 15, 30, or 60 minutes
• Mark medicines as taken with one tap
• Track missed doses automatically

📊 PROGRESS TRACKING
• View today's medicine schedule at a glance
• Monitor your adherence with statistics
• See your current and best streaks
• Review complete medicine history

🎨 BEAUTIFUL & EASY TO USE
• Clean, modern Material Design interface
• Dark mode for comfortable night viewing
• Simple onboarding for quick setup
• Intuitive navigation

🔔 NOTIFICATION FEATURES
• Time-based grouping (Morning, Afternoon, Evening, Night)
• Persistent notifications until action taken
• Works even when app is closed
• Respects Do Not Disturb settings

🔒 PRIVACY FIRST
• All data stored locally on your device
• No account required
• No ads or tracking
• Your health data stays private

PERFECT FOR:
• Managing multiple medications
• Chronic condition management
• Post-surgery recovery
• Vitamin and supplement tracking
• Elderly care support
• Medication adherence

COMING SOON:
• Backup & restore
• Medication refill reminders
• Doctor appointment tracking
• Share reports with healthcare providers

Download Medify today and take control of your medication routine!

Note: Medify is a reminder tool and should not replace professional medical advice. Always consult your healthcare provider for medical decisions.
```

---

#### 8.2 Graphics Assets

**Upload in Play Console:**

1. App icon (512x512) - from `store-assets/icon-512x512.png`
2. Feature graphic (1024x500) - from `store-assets/feature-graphic-1024x500.png`
3. Phone screenshots (2-8) - from `store-assets/screenshot-*.png`

---

#### 8.3 Categorization

**App category:** Medical (or Health & Fitness)

**Tags (optional):**

- medicine reminder
- medication tracker
- pill reminder
- health tracker

---

#### 8.4 Contact Details

**Email:** sumit.piston@gmail.com
**Website:** https://github.com/Sumit-Piston/medify (optional)
**Phone:** (optional)
**Physical address:** (required for paid apps or in-app purchases)

---

#### 8.5 Privacy Policy

**URL:** https://sumit-piston.github.io/medify/PRIVACY_POLICY

---

### ✅ Step 9: Set Up Release

#### 9.1 Select Countries

**Distribution:** Choose countries

- Recommended: Start with your country (India, USA, etc.)
- Or select "All countries"

---

#### 9.2 Production Track

1. Go to **Production** → **Create new release**
2. Upload `app-release.aab` from `build/app/outputs/bundle/release/`
3. **Release name:** 1.0.0 (Initial Release)

**Release notes:**

```
🎉 Initial Release - v1.0.0

Welcome to Medify! Your complete medicine reminder solution.

✨ Features:
• Unlimited medicine tracking with custom schedules
• Smart reminders & notifications (foreground & background)
• Progress statistics & adherence tracking
• Multiple reminder times per medicine
• Snooze functionality (15, 30, 60 minutes)
• Dark mode support
• Beautiful, easy-to-use interface
• 100% offline - all data stored locally
• No ads, no tracking, complete privacy

We're excited to help you never miss a dose again!

For support: sumit.piston@gmail.com
```

---

#### 9.3 Review & Submit

1. **Review all sections** - ensure all have green checkmarks
2. Click **"Send X countries for review"**
3. Wait for Google's review (typically 3-7 days)

---

## 📋 Pre-Submission Checklist

Before clicking submit, verify:

- [ ] App bundle builds successfully
- [ ] App tested on physical device
- [ ] All core features working
- [ ] Privacy policy live and accessible
- [ ] All store assets uploaded (icon, feature graphic, screenshots)
- [ ] Store listing complete (descriptions, contact info)
- [ ] Content rating obtained
- [ ] Data safety section completed
- [ ] Countries selected for distribution
- [ ] Release notes written

---

## 🎉 After Submission

### During Review (3-7 days)

- Check Play Console daily for status updates
- Respond quickly to any Google requests
- Don't make changes to production track

### If Approved ✅

1. **Monitor Crash Reports:**

   - Play Console → Quality → Crashes & ANRs
   - Fix critical issues immediately

2. **Respond to Reviews:**

   - Reply within 24-48 hours
   - Be professional and helpful

3. **Track Metrics:**
   - Installs
   - Ratings
   - User retention

### If Rejected ❌

1. Read rejection reason carefully
2. Fix all policy violations
3. Update app if needed
4. Resubmit with detailed response

---

## 🔧 Common Issues & Solutions

### Build Issues

**Problem:** Build fails
**Solution:** Run `flutter clean` and rebuild

**Problem:** Signing fails
**Solution:** Verify `key.properties` paths and passwords

### Review Rejection

**Problem:** Privacy policy not accessible
**Solution:** Ensure GitHub Pages is enabled and URL works

**Problem:** Data safety concerns
**Solution:** Clarify local-only data storage in description

**Problem:** Misleading claims
**Solution:** Remove any health claims, emphasize "reminder tool"

---

## 📞 Support Resources

- Play Console: https://play.google.com/console
- Developer Policies: https://play.google.com/about/developer-content-policy/
- Data Safety Help: https://support.google.com/googleplay/android-developer/answer/10787469
- Flutter Release Guide: https://docs.flutter.dev/deployment/android

---

**Good luck with your submission! 🚀**

You've built an amazing app - time to share it with the world!
