# Play Store Launch Checklist

## 📱 App Information

- **App Name:** Medify
- **Package Name:** com.sumit.medify (update in `android/app/build.gradle`)
- **Version:** 1.0.0 (Version Code: 1)
- **Category:** Medical / Health & Fitness
- **Target Audience:** 18+
- **Content Rating:** Everyone

---

## ✅ Pre-Launch Checklist

### 1. App Configuration ✅

#### Android Configuration

- [x] App name set to "Medify"
- [x] App icon configured
- [x] Splash screen implemented
- [ ] Update package name in `android/app/build.gradle`
  ```gradle
  applicationId "com.sumit.medify"  // Change from default
  ```
- [ ] Set proper version code and version name
  ```gradle
  versionCode 1
  versionName "1.0.0"
  ```
- [x] Minimum SDK: 21 (Android 5.0)
- [ ] Target SDK: 34 (Android 14) - Update in `build.gradle`
- [ ] Compile SDK: 34 - Update in `build.gradle`

#### App Permissions

- [x] Notification permissions (POST_NOTIFICATIONS)
- [x] Exact alarm permissions (SCHEDULE_EXACT_ALARM, USE_EXACT_ALARM)
- [ ] Review and remove unused permissions

### 2. App Signing 🔐

- [ ] Generate upload keystore
  ```bash
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] Create `android/key.properties` file:
  ```properties
  storePassword=<password>
  keyPassword=<password>
  keyAlias=upload
  storeFile=<path to upload-keystore.jks>
  ```
- [ ] Update `android/app/build.gradle` with signing config
- [ ] Test release build signs correctly
- [ ] Keep keystore backup in secure location

### 3. Build & Testing 🔨

#### Release Build

- [x] Generate release APK successfully
  ```bash
  flutter build apk --release
  ```
- [ ] Generate App Bundle (recommended for Play Store)
  ```bash
  flutter build appbundle --release
  ```
- [ ] Test release build on physical device
- [ ] Verify app size (target: < 50MB)
- [x] Run flutter analyze (0 errors)

#### Testing Checklist

- [ ] Test on multiple Android versions (5.0 to 14)
- [ ] Test on different screen sizes (phone/tablet)
- [ ] Test all core features:
  - [ ] Add medicine
  - [ ] Edit medicine
  - [ ] Delete medicine
  - [ ] Receive notifications
  - [ ] Mark as taken
  - [ ] Snooze functionality
  - [ ] Statistics display
  - [ ] Theme switching
  - [ ] Settings changes
- [ ] Test app after device restart
- [ ] Test with no internet connection
- [ ] Test notification permissions flow
- [ ] Verify onboarding experience

### 4. Legal & Privacy 📄

- [ ] Create Privacy Policy (see PRIVACY_POLICY.md)
- [ ] Host privacy policy on GitHub Pages
- [ ] Get privacy policy URL
- [ ] Create Terms of Service (optional but recommended)
- [ ] Ensure compliance with GDPR (if EU users)
- [ ] Review data collection practices
- [ ] Add privacy policy link in app (Settings → About)

### 5. Store Listing Assets 🎨

#### App Icon

- [ ] 512x512 PNG (high-res icon)
- [ ] Transparent background or solid color
- [ ] Clear and recognizable at small sizes

#### Feature Graphic

- [ ] 1024x500 PNG or JPG
- [ ] Showcases app functionality
- [ ] No important content in edges (safe area)

#### Screenshots (REQUIRED - Minimum 2)

- [ ] Phone Screenshots (minimum 2, max 8)
  - Recommended: 1080x1920 or 1440x2560
  - Show key features:
    1. Medicine list/home screen
    2. Add medicine screen
    3. Today's schedule
    4. Statistics/progress
    5. Notification example
- [ ] 7-inch Tablet (optional)
- [ ] 10-inch Tablet (optional)

#### Promotional Assets (Optional)

- [ ] Promo Graphic: 180x120 PNG or JPG
- [ ] TV Banner: 1280x720 PNG or JPG (if TV support)
- [ ] 360 degree video (if applicable)

### 6. Store Listing Content 📝

#### Short Description (80 characters max)

```
Never miss your medicine. Smart reminders & progress tracking.
```

#### Full Description (4000 characters max)

```markdown
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

#### What's New (500 characters)

```
🎉 Initial Release - v1.0.0

Welcome to Medify! Your complete medicine reminder solution.

✨ Features:
• Unlimited medicine tracking
• Smart reminders & notifications
• Progress statistics & streaks
• Dark mode support
• Beautiful, easy-to-use interface

We're excited to help you never miss a dose again!
```

#### App Category

- Primary: Medical OR Health & Fitness
- (Choose based on Play Store guidelines)

#### Tags/Keywords

```
medicine reminder, medication tracker, pill reminder, health tracker,
medicine alarm, medication schedule, dose reminder, prescription tracker,
medication manager, health app, pill organizer, medicine notification
```

#### Content Rating

- [ ] Fill out content rating questionnaire
- Target rating: Everyone or Teen
- Answer honestly about:
  - Violence: None
  - Sexual content: None
  - Language: None
  - Substance use: Medication management (not drug abuse)

#### Contact Information

- [ ] Developer name
- [ ] Developer email (public-facing)
- [ ] Website URL (GitHub Pages or custom)
- [ ] Phone number (optional)
- [ ] Physical address (required for some countries)

### 7. Pricing & Distribution 💰

- [x] Free app (no in-app purchases currently)
- [ ] Select countries for distribution (recommend: Start with your country)
- [ ] Primarily distributed countries: All or selected
- [ ] Content rating certificate obtained
- [ ] Ads: No (clean experience)

### 8. App Content Declaration 🏷️

#### Data Safety Section

- [ ] Fill out Data Safety form:
  - Data collected: None
  - Data shared: None
  - Security practices: Data is encrypted in transit and at rest
  - Data can be deleted: Yes (user can clear all data)

#### App Access

- [ ] All core features available without account: Yes
- [ ] Special access requirements: None

### 9. Pre-Launch Testing 🧪

#### Internal Testing (Recommended first step)

- [ ] Create internal testing track
- [ ] Upload app bundle
- [ ] Add internal testers (email addresses)
- [ ] Test for 1-2 weeks
- [ ] Collect feedback and fix issues

#### Closed Testing (Optional)

- [ ] Create closed testing track
- [ ] Invite beta testers
- [ ] Gather feedback
- [ ] Iterate on issues

#### Open Testing (Optional)

- [ ] Create open testing track
- [ ] Public beta testing
- [ ] Monitor crash reports
- [ ] Review user feedback

### 10. Final Checks Before Production ✨

#### Technical

- [x] All critical bugs fixed
- [x] App doesn't crash on startup
- [x] All features working as expected
- [x] Notifications working reliably
- [ ] Performance optimized (smooth scrolling, fast loading)
- [ ] Battery usage acceptable
- [ ] Memory usage reasonable

#### Content

- [ ] All text free of typos
- [ ] All images high quality
- [ ] No placeholder content
- [ ] Proper error messages
- [ ] Loading states implemented

#### Legal

- [ ] Privacy policy live and accessible
- [ ] Correct package name
- [ ] Proper app permissions
- [ ] Content rating appropriate
- [ ] No copyright violations

#### Store Listing

- [ ] Screenshots representative of current version
- [ ] Description accurate and compelling
- [ ] Feature graphic professional
- [ ] Icon clear at all sizes
- [ ] All required fields completed

---

## 🚀 Launch Steps

### Step 1: Create Play Console Account

1. Go to https://play.google.com/console
2. Sign up for developer account ($25 one-time fee)
3. Verify identity and payment
4. Accept Developer Distribution Agreement

### Step 2: Create App

1. Click "Create app"
2. Fill in app details:
   - App name: Medify
   - Default language: English (United States)
   - App or game: App
   - Free or paid: Free
3. Declare if app is primarily for children: No

### Step 3: Complete All Dashboard Tasks

1. ✅ App access
2. ✅ Ads (declare: No ads)
3. ✅ Content rating (fill questionnaire)
4. ✅ Target audience
5. ✅ News apps (declare: No)
6. ✅ COVID-19 contact tracing/status apps (declare: No)
7. ✅ Data safety
8. ✅ Government apps (declare: No)
9. ✅ Financial features (declare: No)
10. ✅ Health/wellness apps (declare: Yes - medication management)

### Step 4: Upload Build

1. Go to Production → Create new release
2. Upload app bundle (.aab file)
3. Add release notes
4. Review release details
5. Save (don't submit yet)

### Step 5: Complete Store Listing

1. Go to Store presence → Main store listing
2. Upload all assets (icon, screenshots, graphics)
3. Fill in description
4. Set category and tags
5. Add contact information
6. Save

### Step 6: Set Pricing & Distribution

1. Go to Pricing & distribution
2. Confirm free app
3. Select countries
4. Declare if available on Android TV/Wear OS
5. Accept content guidelines
6. Save

### Step 7: Review & Submit

1. Review all sections (green checkmarks)
2. Click "Send for review"
3. Wait for Google's review (typically 3-7 days)
4. Monitor status in Play Console

---

## 📊 Post-Launch Checklist

### Week 1

- [ ] Monitor crash reports daily
- [ ] Respond to user reviews
- [ ] Track install numbers
- [ ] Check performance metrics
- [ ] Fix critical bugs immediately

### Week 2-4

- [ ] Analyze user feedback
- [ ] Plan updates based on feedback
- [ ] Monitor app health (crashes, ANRs)
- [ ] Update screenshots if needed
- [ ] Consider running ads/promotion

### Ongoing

- [ ] Regular updates (every 2-4 weeks initially)
- [ ] Respond to all reviews (24-48 hours)
- [ ] Monitor Play Console for policy updates
- [ ] Track analytics and user behavior
- [ ] Plan feature roadmap

---

## 🎯 Success Metrics

### Technical Health

- Crash-free rate: > 99.5%
- ANR rate: < 0.5%
- Average rating: > 4.0
- App size: < 50MB

### User Engagement

- Day 1 retention: > 40%
- Day 7 retention: > 20%
- Day 30 retention: > 10%
- Average session length: > 2 minutes

### Reviews

- Response rate: 100%
- Response time: < 48 hours
- Rating: 4+ stars

---

## 📞 Support Resources

- Play Console: https://play.google.com/console
- Developer Policy: https://play.google.com/about/developer-content-policy/
- Design Guidelines: https://developer.android.com/design
- App Bundle Guide: https://developer.android.com/guide/app-bundle
- Testing Guide: https://developer.android.com/studio/test

---

## 🔧 Emergency Contacts

If app is suspended or removed:

1. Read suspension email carefully
2. Address all policy violations
3. Appeal through Play Console
4. Contact developer support
5. Fix issues and resubmit

**Developer Support:**

- Play Console → Help → Contact us
- https://support.google.com/googleplay/android-developer

---

**Last Updated:** October 16, 2025  
**Version:** 1.0  
**Status:** Ready for submission (pending items marked above)
