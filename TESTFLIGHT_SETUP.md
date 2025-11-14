# TestFlight Setup Guide for Draw With Friends

## Step 1: Apply Firebase Security Rules (REQUIRED)

Your app is currently in "test mode" which expires in 30 days. You **must** update the security rules before TestFlight.

### How to Apply:

1. **Open Firebase Console:**
   - Go to: https://console.firebase.google.com/
   - Select your project: "draw-with-friends-3c57d"

2. **Navigate to Database Rules:**
   - Click "Realtime Database" in the left sidebar
   - Click the "Rules" tab at the top

3. **Copy the New Rules:**
   - Open the file: `firebase-rules.json` (in this folder)
   - Copy ALL the contents

4. **Paste and Publish:**
   - Delete everything in the Firebase Rules editor
   - Paste the new rules
   - Click "Publish" button

5. **Test Your App:**
   - Create a room ✅
   - Join a room ✅
   - Draw and sync ✅
   - Clear canvas ✅

**If anything breaks:** Check Firebase Console → Realtime Database → Usage tab for error messages.

---

## Step 2: Prepare App for TestFlight

### A. Update App Info

1. **Open Xcode**
2. **Select your project** (top of file navigator)
3. **Select "Draw With Friends" target**
4. **Go to "General" tab**

Check these settings:
- ✅ **Display Name:** Draw With Friends
- ✅ **Bundle Identifier:** (should already be set)
- ✅ **Version:** 1.0
- ✅ **Build:** 1 (increment for each upload)
- ✅ **Deployment Target:** iOS 15.0 (or whatever you set)

### B. Add App Icon

1. **Click on Assets.xcassets** in file navigator
2. **Click "AppIcon"**
3. **Drag and drop** your icon images (various sizes needed)
   - Or use a tool like https://appicon.co/ to generate all sizes

### C. Add Privacy Descriptions (REQUIRED)

Your app doesn't need camera/location, but if you add those features later, you'll need:

1. **Select your project → Info tab**
2. **Add these if needed:**
   - `NSCameraUsageDescription`: "To take photos of your drawings"
   - `NSPhotoLibraryAddUsageDescription`: "To save drawings to your photo library"

---

## Step 3: Archive and Upload

### A. Select "Any iOS Device (arm64)"

1. At the top of Xcode, click the device selector
2. Choose **"Any iOS Device (arm64)"**

### B. Archive the App

1. **Product** → **Archive**
2. Wait for build to complete (may take a few minutes)
3. Xcode Organizer window will open

### C. Distribute to TestFlight

1. Click **"Distribute App"**
2. Select **"App Store Connect"**
3. Click **"Upload"**
4. Select **"Automatically manage signing"** (if you have Apple Developer account)
5. Click **"Upload"**

---

## Step 4: TestFlight Configuration

### A. Wait for Processing

- After upload, Apple processes your build (10-60 minutes)
- You'll get an email when it's ready

### B. Add Testers

1. **Go to App Store Connect:** https://appstoreconnect.apple.com/
2. **Click "My Apps"**
3. **Select "Draw With Friends"**
4. **Click "TestFlight" tab**
5. **Click "+ Add Testers"**
6. **Add emails** of your friends

### C. What to Test

Send your testers this checklist:

**Basic Functionality:**
- [ ] Create a room (both modes: Simultaneous & Turn-Based)
- [ ] Join a room with code
- [ ] Draw on canvas
- [ ] Drawing syncs between devices
- [ ] Clear canvas works
- [ ] Leave room works

**Drawing Tools:**
- [ ] Pencil, Brush, Spray tools work
- [ ] Thickness slider works (1-30)
- [ ] Color picker works
- [ ] Undo works

**Echo Mode:**
- [ ] Enable echo mode
- [ ] See shadow/trail effect
- [ ] Adjust echo count (2x, 3x, ∞)

**Edge Cases:**
- [ ] App works on iPhone and iPad
- [ ] Works on different iOS versions
- [ ] Handles poor network connection
- [ ] Multiple users in same room
- [ ] Room code input not laggy

---

## Common Issues & Solutions

### "Failed to upload"
- **Solution:** Check your Apple Developer account is active and paid

### "Invalid Bundle"
- **Solution:** Make sure all required icons are added

### "Missing compliance"
- **Solution:** In App Store Connect, answer "No" to encryption questions (your app doesn't use encryption beyond HTTPS)

### "Rules rejected" in Firebase
- **Solution:** Double-check you copied ALL the rules from `firebase-rules.json`

---

## Current Status

- ✅ App builds successfully
- ✅ Firebase configured
- ⏳ Security rules need to be applied
- ⏳ TestFlight upload pending

**Next Steps:**
1. Apply Firebase security rules (Step 1)
2. Test app locally to confirm rules work
3. Archive and upload to TestFlight (Step 3)
4. Add testers and collect feedback

---

**Questions?** Check the Firebase Console for any database errors, or Xcode Organizer for build issues.


