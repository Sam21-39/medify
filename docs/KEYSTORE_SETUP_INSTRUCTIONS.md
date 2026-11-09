# Keystore Generation Instructions

## ⚠️ IMPORTANT: Generate Your Keystore

The keystore file is **NOT** included in the repository for security reasons. You need to generate it before building the release version.

---

## Step 1: Install Java JDK (if not already installed)

### macOS:

```bash
brew install openjdk@17
```

Or download from: https://www.oracle.com/java/technologies/downloads/

---

## Step 2: Generate Keystore

Run this command in your terminal:

```bash
keytool -genkey -v -keystore ~/medify-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias medify-upload \
  -storepass medify2024secure -keypass medify2024secure \
  -dname "CN=Sumit Pal, OU=Medify, O=Medify, L=KOLKATA, ST=WB, C=IN"
```

**What this creates:**

- **File:** `~/medify-upload-keystore.jks` (in your home directory)
- **Alias:** `medify-upload`
- **Password:** `medify2024secure` (stored in `android/key.properties`)
- **Validity:** 10,000 days (~27 years)

---

## Step 3: Verify Keystore Created

Check if the keystore file exists:

```bash
ls -lh ~/medify-upload-keystore.jks
```

You should see:

```
-rw-r--r--  1 sumitpal  staff   2.5K Oct 16 10:00 /Users/sumitpal/medify-upload-keystore.jks
```

---

## Step 4: Keystore Configuration (Already Done)

The following files have been configured for you:

### ✅ `android/key.properties`

Contains keystore credentials:

```properties
storePassword=medify2024secure
keyPassword=medify2024secure
keyAlias=medify-upload
storeFile=/Users/sumitpal/medify-upload-keystore.jks
```

### ✅ `android/app/build.gradle.kts`

Configured with:

- Application ID: `com.sumit.medify`
- Target SDK: 36
- Compile SDK: 36
- ProGuard optimization enabled
- Release signing configuration

### ✅ `android/app/proguard-rules.pro`

Optimization rules for:

- Code shrinking
- Resource shrinking
- Obfuscation
- Flutter compatibility
- ObjectBox compatibility

---

## Step 5: Build Release App

After generating the keystore, build your release app:

### Clean build:

```bash
fvm flutter clean
fvm flutter pub get
```

### Build App Bundle (for Play Store):

```bash
fvm flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

### Build APK (for testing):

```bash
fvm flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

---

## ⚠️ SECURITY - CRITICAL INFORMATION

### DO NOT:

- ❌ Commit keystore files to Git
- ❌ Share keystore files publicly
- ❌ Lose your keystore file
- ❌ Forget your keystore password

### DO:

- ✅ Backup keystore file to secure location (Google Drive, USB, etc.)
- ✅ Save password in password manager
- ✅ Keep multiple backups
- ✅ Store in different physical locations

### Why is this important?

- Without the keystore, you **CANNOT** update your app on Play Store
- If lost, you must publish a NEW app with a new package name
- All existing users will need to uninstall and reinstall

---

## Keystore Information Summary

**Store in password manager:**

```
App: Medify (Play Store)
Keystore File: /Users/sumitpal/medify-upload-keystore.jks
Keystore Password: medify2024secure
Key Alias: medify-upload
Key Password: medify2024secure
Application ID: com.sumit.medify
```

---

## Troubleshooting

### Error: "keytool: command not found"

**Solution:** Install Java JDK (see Step 1)

### Error: "Could not find or load main class"

**Solution:** Ensure Java is in your PATH:

```bash
export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH
```

### Error: "Keystore file does not exist"

**Solution:** Ensure you ran the keytool command and file was created at `~/medify-upload-keystore.jks`

### Build Error: "Signing config has not been configured"

**Solution:**

1. Ensure keystore file exists
2. Verify `android/key.properties` has correct path
3. Run `fvm flutter clean` and rebuild

---

## What's Been Configured

### ✅ Application Updates:

- **Application ID:** Changed from `com.medify.medify` to `com.sumit.medify`
- **Namespace:** Updated to `com.sumit.medify`
- **Target SDK:** Updated to 36 (Android 15)
- **Compile SDK:** Updated to 36
- **Version Code:** 1
- **Version Name:** 1.0.0

### ✅ Optimization Enabled:

- **R8 Code Shrinking:** Enabled
- **Resource Shrinking:** Enabled
- **ProGuard Rules:** Custom rules added
- **Obfuscation:** Enabled for release builds

### ✅ Size Optimization:

Expected reduction: **30-50% smaller app size**

- Code shrinking removes unused code
- Resource shrinking removes unused resources
- Obfuscation reduces method names

### ✅ Security:

- Release builds signed with upload keystore
- Debug builds use debug keystore
- Key credentials not committed to Git

---

## Next Steps

1. ✅ Run the keytool command above to generate keystore
2. ✅ Verify keystore file exists
3. ✅ Build release app bundle
4. ✅ Test release build on device
5. ✅ Create store assets (screenshots, graphics)
6. ✅ Upload to Play Console

---

## Build Commands Reference

```bash
# Clean project
fvm flutter clean

# Get dependencies
fvm flutter pub get

# Analyze code
fvm flutter analyze

# Build release app bundle (Play Store)
fvm flutter build appbundle --release

# Build release APK (testing)
fvm flutter build apk --release

# Install release APK on connected device
fvm flutter install --release

# Check app size
ls -lh build/app/outputs/bundle/release/app-release.aab
```

---

## Expected Build Output

**Before optimization:**

- App size: ~40-50 MB

**After optimization (with ProGuard):**

- App size: ~20-30 MB (30-50% reduction)
- Download size on Play Store: ~10-15 MB (compressed)

---

**Good luck with your Play Store submission! 🚀**
