# Play Store Submission - Interactive Step-by-Step Guide

**Current Status:** Ready to begin submission process  
**Estimated Time:** 2-3 hours total

---

## 🎯 START HERE: Step 1 - Generate Signing Key (5 minutes)

This is the FIRST and MOST IMPORTANT step. This keystore will sign your app and you'll need it for ALL future updates.

### What to do:

1. **Open Terminal** and run this command:

```bash
keytool -genkey -v -keystore ~/medify-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias medify-upload
```

2. **Answer the prompts:**

   - **Enter keystore password:** (Choose a STRONG password - remember it!)
   - **Re-enter password:** (Same password)
   - **What is your first and last name?** Sumit Pal (or your name)
   - **What is the name of your organizational unit?** Medify
   - **What is the name of your organization?** Medify
   - **What is the name of your City or Locality?** (Your city)
   - **What is the name of your State or Province?** (Your state)
   - **What is the two-letter country code?** IN (or your country)
   - **Is this correct?** yes
   - **Enter key password:** (Press Enter to use same password as keystore)

3. **SAVE THIS INFORMATION SECURELY:**

   ```
   Keystore Password: _______________
   Key Alias: medify-upload
   Keystore Path: /Users/sumitpal/medify-upload-keystore.jks
   ```

   **⚠️ CRITICAL:** If you lose this keystore or password, you can NEVER update your app!

   **Backup:** Copy `~/medify-upload-keystore.jks` to a secure location (Google Drive, USB drive, etc.)

### Status: ⏳ **COMPLETE THIS FIRST**

---

## Step 2 - Configure Signing (10 minutes)

Once you have your keystore, let's configure your app to use it.

### 2.1 Create key.properties

I'll create this file for you. You just need to **replace YOUR_PASSWORD_HERE** with the actual password you chose in Step 1.

### 2.2 Update build.gradle.kts

I'll update the Android configuration files with proper signing config.

### 2.3 Add key.properties to .gitignore

I'll ensure your password file is never committed to git.

### Status: ⏳ **Ready to execute after Step 1**

---

## Step 3 - Build Signed App Bundle (5 minutes)

Once signing is configured, we'll build the final app bundle for Play Store.

```bash
fvm flutter clean
fvm flutter pub get
fvm flutter build appbundle --release
```

This creates: `build/app/outputs/bundle/release/app-release.aab`

### Status: ⏳ **Ready after Step 2**

---

## Step 4 - Create Store Assets (60-90 minutes)

You'll need to create graphics for the Play Store.

### Required Assets:

1. **App Icon (512x512)**

   - Take your current app icon
   - Resize to 512x512 pixels
   - Save as PNG

2. **Feature Graphic (1024x500)**

   - Create an attractive banner
   - Show app concept or screenshot
   - Use Medify branding (Teal colors)

3. **Screenshots (2-8 images)**
   - Take screenshots of your app running
   - Recommended: 1080x1920 (portrait)
   - Show key features

**Tools:** Figma, Canva, or Photoshop

### Status: ⏳ **Can do in parallel**

---

## Step 5 - Create Play Console Account (15 minutes)

1. Go to: https://play.google.com/console
2. Sign in with Google Account
3. Pay $25 USD one-time fee
4. Complete developer profile

### Status: ⏳ **Can do now or later**

---

## Step 6 - Verify Privacy Policy (2 minutes)

Check if your privacy policy is live:
https://sumit-piston.github.io/medify/PRIVACY_POLICY

If not working:

1. Go to: https://github.com/Sumit-Piston/medify/settings/pages
2. Enable GitHub Pages (main, root)
3. Wait 2-3 minutes

### Status: ⏳ **Quick check needed**

---

## Step 7 - Upload to Play Console (30 minutes)

Once you have:

- ✅ Signed app bundle (Step 3)
- ✅ Store assets (Step 4)
- ✅ Play Console account (Step 5)

Then:

1. Create new app in Play Console
2. Fill out all required sections
3. Upload app bundle
4. Upload graphics
5. Submit for review

---

## 🚦 Current Action Items

**RIGHT NOW:**

1. Run Step 1 command to generate keystore
2. Save the password securely
3. Let me know when done, I'll update the config files

**Type "done step 1" when you've generated the keystore and saved the password**

---

## 📝 Quick Reference

**Keystore Info:**

- Alias: `medify-upload`
- Location: `~/medify-upload-keystore.jks`
- Validity: 27 years (10,000 days)

**App Info:**

- Package: `com.medify.medify` (current)
- Version: 1.0.0
- Version Code: 1

**Privacy Policy:**

- URL: https://sumit-piston.github.io/medify/PRIVACY_POLICY

---

**Let's start with Step 1! 🚀**
