# Quick Start - Release Build for Play Store

## ✅ Configuration Complete!

All Android configuration files have been updated and optimized for Play Store release.

---

## 🎯 What's Been Done

### Application Configuration

- ✅ **Application ID:** `com.sumit.medify`
- ✅ **Target SDK:** 36 (Android 15)
- ✅ **Compile SDK:** 36 (Android 15)
- ✅ **Version:** 1.0.0 (Code: 1)

### Optimization Enabled

- ✅ **ProGuard/R8:** Code shrinking & obfuscation
- ✅ **Resource Shrinking:** Removes unused resources
- ✅ **Expected Size Reduction:** 30-50%

### Security

- ✅ **Release Signing:** Configured
- ✅ **Keystore Files:** Added to .gitignore
- ✅ **Credentials:** Secure storage setup

---

## 🚀 Two Options to Proceed

### Option A: Install Java & Use Script (Recommended)

1. **Install Java JDK:**

   ```bash
   # macOS
   brew install openjdk@17

   # Or download from Oracle
   # https://www.oracle.com/java/technologies/downloads/
   ```

2. **Run the keystore generation script:**

   ```bash
   ./generate-keystore.sh
   ```

3. **Build release:**
   ```bash
   fvm flutter build appbundle --release
   ```

---

### Option B: Manual Setup (No Java Install Needed)

If you can't install Java or prefer manual setup, follow this workaround:

#### Step 1: Generate Keystore Using Android Studio

1. **Open Android Studio**
2. **Go to:** Build → Generate Signed Bundle / APK
3. **Click:** Create new keystore
4. **Fill in:**
   - Key store path: `/Users/sumitpal/medify-upload-keystore.jks`
   - Password: `medify2024secure`
   - Alias: `medify-upload`
   - Alias password: `medify2024secure`
   - Validity: 10000 days
   - Certificate info:
     - First and Last Name: Sumit Pal
     - Organizational Unit: Medify
     - Organization: Medify
     - City: KOLKATA
     - State: WB
     - Country: IN
5. **Click:** OK (don't build yet, just create keystore)
6. **Cancel** the build dialog

#### Step 2: Verify Keystore File

Check that the file exists:

```bash
ls -lh ~/medify-upload-keystore.jks
```

#### Step 3: Build Release

```bash
fvm flutter clean
fvm flutter pub get
fvm flutter build appbundle --release
```

---

## 📦 Build Commands

### Clean Build

```bash
fvm flutter clean
fvm flutter pub get
```

### Build App Bundle (Play Store)

```bash
fvm flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

### Build APK (Testing)

```bash
fvm flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

---

## 🔍 Verify Build

### Check App Bundle Size

```bash
ls -lh build/app/outputs/bundle/release/app-release.aab
```

**Expected:** 20-30 MB (optimized)

### Test Release Build

```bash
# Install APK on connected device
fvm flutter build apk --release
fvm flutter install --release

# Or manually:
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Test checklist:**

- [ ] App launches successfully
- [ ] All features work
- [ ] Notifications trigger
- [ ] Theme switching works
- [ ] Medicine CRUD operations work
- [ ] No crashes

---

## 📊 Current Configuration Summary

```
Application ID: com.sumit.medify
Package Name:   com.sumit.medify
Version Name:   1.0.0
Version Code:   1

Target SDK:     36 (Android 15)
Compile SDK:    36 (Android 15)
Min SDK:        21 (Android 5.0)

Optimization:   ✅ Enabled
Code Shrinking: ✅ Enabled
Resource Shrink:✅ Enabled
Obfuscation:    ✅ Enabled

Keystore:       ~/medify-upload-keystore.jks
Key Alias:      medify-upload
Password:       medify2024secure
```

---

## 🎨 Next: Store Assets

While building, you can create store assets in parallel:

### Required Assets

1. **App Icon (512x512)**

   - Export your current app icon
   - Resize to 512x512 pixels
   - Save as PNG

2. **Feature Graphic (1024x500)**

   - Create promotional banner
   - Show app concept
   - Use Medify branding (Teal: #14B8A6)

3. **Screenshots (2-8 images)**
   - 1080x1920 (portrait) recommended
   - Show key features:
     - Medicine list
     - Add medicine
     - Today's schedule
     - Statistics
     - Dark mode

**Tools:** Figma, Canva, or Photoshop

---

## 📝 Keystore Information

**SAVE THIS SECURELY:**

```
Keystore File: /Users/sumitpal/medify-upload-keystore.jks
Keystore Password: medify2024secure
Key Alias: medify-upload
Key Password: medify2024secure
Application ID: com.sumit.medify
```

**⚠️ CRITICAL:**

- Backup keystore file to secure location
- Save passwords in password manager
- Never commit keystore to Git
- Without keystore, you cannot update your app!

---

## 🐛 Troubleshooting

### Build Error: "Signing config not found"

**Solution:** Ensure keystore file exists at `~/medify-upload-keystore.jks`

### Build Error: "compileSdkVersion 36 not found"

**Solution:** Update Android SDK in Android Studio:

- Open Android Studio
- Tools → SDK Manager
- Install Android SDK Platform 36 (Android 15)

### Build Error: "Execution failed for task ':app:minifyReleaseWithR8'"

**Solution:** This is rare, but if happens:

1. Check `android/app/proguard-rules.pro` exists
2. Run `fvm flutter clean`
3. Rebuild

### App Crashes After Release Build

**Solution:** Check ProGuard rules:

- ObjectBox models might need -keep rules
- Check logcat for specific errors
- Test with `fvm flutter run --release` first

---

## ✅ Pre-Submission Checklist

Before uploading to Play Console:

- [ ] Keystore generated and backed up
- [ ] Release app bundle builds successfully
- [ ] App bundle size is reasonable (< 50MB)
- [ ] Release APK tested on physical device
- [ ] All features work in release mode
- [ ] No crashes or ANRs
- [ ] Notifications work properly
- [ ] Store assets created (icon, graphic, screenshots)
- [ ] Privacy policy live: https://sumit-piston.github.io/medify/PRIVACY_POLICY

---

## 🎯 Final Steps

1. ✅ Generate keystore (Option A or B above)
2. ✅ Build app bundle
3. ✅ Test release build
4. ✅ Create store assets
5. ✅ Create Play Console account ($25)
6. ✅ Upload app bundle to Play Console
7. ✅ Fill out store listing
8. ✅ Submit for review

---

## 📚 Additional Resources

- **Full Guide:** `PLAY_STORE_SUBMISSION_GUIDE.md`
- **Step-by-Step:** `STEP_BY_STEP_GUIDE.md`
- **Keystore Setup:** `KEYSTORE_SETUP_INSTRUCTIONS.md`
- **Play Store Checklist:** `docs/PLAY_STORE_CHECKLIST.md`

---

**You're almost there! Just generate the keystore and build! 🚀**
