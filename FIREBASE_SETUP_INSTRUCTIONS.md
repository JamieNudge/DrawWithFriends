# Draw With Friends - Firebase Setup Guide

## Step 1: Create Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click "Add project"
3. Name it "Draw With Friends"
4. Disable Google Analytics (not needed for this app)
5. Click "Create project"

## Step 2: Add iOS App to Firebase

1. In Firebase console, click the iOS+ icon
2. Enter your Bundle ID: `com.yourname.Draw-With-Friends`
   - You can find this in Xcode: Select project → General → Bundle Identifier
3. Enter App nickname: "Draw With Friends"
4. Click "Register app"
5. **Download GoogleService-Info.plist**
6. Drag this file into your Xcode project (make sure "Copy items if needed" is checked)

## Step 3: Enable Realtime Database

1. In Firebase console, go to "Build" → "Realtime Database"
2. Click "Create Database"
3. Select location (choose closest to you)
4. Start in **test mode** (we'll secure it later)
5. Click "Enable"

## Step 4: Update Firebase Rules (Security)

In the Realtime Database → Rules tab, replace with:

```json
{
  "rules": {
    "rooms": {
      "$roomId": {
        ".read": true,
        ".write": true,
        "strokes": {
          ".indexOn": ["timestamp"]
        }
      }
    }
  }
}
```

## Step 5: Add Firebase SDK to Xcode

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Click "Add Package"
4. Select these products:
   - ✅ FirebaseDatabase
   - ✅ FirebaseAuth (optional, for future user accounts)
5. Click "Add Package"

## Step 6: Update App File

Open `Draw_With_FriendsApp.swift` and make sure it looks like this:

```swift
import SwiftUI
import FirebaseCore

@main
struct Draw_With_FriendsApp: App {
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Step 7: Add Files to Xcode Project

Make sure these files are added to your Xcode project:
- ✅ FirebaseManager.swift
- ✅ RoomView.swift
- ✅ DrawingCanvasView.swift
- ✅ ContentView.swift (updated)
- ✅ GoogleService-Info.plist

To add files:
1. Right-click your project folder in Xcode
2. Select "Add Files to Draw With Friends"
3. Select the files
4. Make sure "Copy items if needed" is checked
5. Click "Add"

## Step 8: Build and Run!

1. Select a simulator or your iPhone
2. Press Cmd + R to build and run
3. Create a room or join with a code
4. Start drawing!

## Testing with Multiple Devices

1. Run the app on 2+ devices/simulators
2. Create a room on device 1 - note the 6-digit code
3. Join that room on device 2 using the code
4. Draw on either device - you should see it appear on both in real-time!

## Troubleshooting

### "Firebase not configured" error
- Make sure GoogleService-Info.plist is in your project
- Check that FirebaseApp.configure() is called in the app's init

### Strokes not syncing
- Check Firebase console to verify database was created
- Verify you're in the same room code on both devices
- Check internet connection

### Build errors
- Make sure Firebase packages are fully downloaded
- Try Product → Clean Build Folder (Cmd + Shift + K)
- Restart Xcode

## Next Steps (Future Features)

- User accounts and authentication
- Save/load drawings
- More drawing tools (brush types, eraser, fill)
- Chat between users
- Drawing history/replay
- Export as image
- Room passwords for privacy

---

**You're all set!** 🎨 Your collaborative drawing app is ready to use!



