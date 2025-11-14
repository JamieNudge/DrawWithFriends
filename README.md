# 🎨 Draw With Friends

A real-time collaborative drawing app for iOS where users can draw together from anywhere in the world!

## ✨ Features

✅ **Real-time Collaboration** - Draw with friends simultaneously  
✅ **Room System** - Create or join rooms with simple 6-digit codes  
✅ **PencilKit Integration** - Smooth, professional drawing with Apple Pencil support  
✅ **Color Picker** - 12 vibrant colors to choose from  
✅ **Cloud Sync** - Firebase Realtime Database for instant synchronization  
✅ **Copy Room Code** - Easy sharing with built-in copy button  
✅ **Clear Canvas** - Start fresh anytime  
✅ **Beautiful UI** - Modern gradient design with smooth animations

## 🚀 How It Works

1. **Create a Room** - Tap "Create New Room" to generate a unique code
2. **Share the Code** - Give your 6-digit room code to friends
3. **Join & Draw** - Friends enter the code and you all draw together!
4. **Real-time Magic** - Every stroke appears instantly on all devices

## 📋 Setup Instructions

**See `FIREBASE_SETUP_INSTRUCTIONS.md` for complete Firebase setup guide**

### Quick Start:
1. Create Firebase project at console.firebase.google.com
2. Add iOS app and download GoogleService-Info.plist
3. Enable Realtime Database
4. Add Firebase SDK via Swift Package Manager
5. Build and run!

## 📱 Technical Details

**Platform:** iOS 15.0+  
**Language:** Swift + SwiftUI  
**Drawing:** PencilKit  
**Backend:** Firebase Realtime Database  
**Connectivity:** Real-time cloud sync (works globally)

## 🏗️ Project Structure

```
Draw With Friends/
├── ContentView.swift           # Main navigation
├── RoomView.swift             # Join/create room UI
├── DrawingCanvasView.swift    # Collaborative canvas
├── FirebaseManager.swift      # Real-time sync logic
└── GoogleService-Info.plist   # Firebase config (you add this)
```

## 🎯 What's Next?

Current MVP is complete! Future enhancements could include:

- 👤 User accounts & authentication
- 💾 Save and load drawings
- 🖌️ More brush types and tools
- 💬 In-app chat
- 📸 Export drawings as images
- 🔒 Private rooms with passwords
- 📊 Drawing history/replay
- 🌈 Gradient brushes and effects

## 🐛 Troubleshooting

**Firebase not configured?**
- Make sure GoogleService-Info.plist is added to Xcode project

**Strokes not syncing?**
- Check Firebase console - is Realtime Database created?
- Verify both devices are in the same room code
- Check internet connection

**Build errors?**
- Clean build folder (Cmd + Shift + K)
- Restart Xcode
- Verify Firebase packages are downloaded

## 📝 Notes

- Room codes are 6 digits (000000-999999)
- Rooms persist in Firebase until manually deleted
- No user authentication required (anonymous access)
- Works on iPhone and iPad
- Supports Apple Pencil on compatible devices

## 🌐 Website Files

The repository also includes a simple landing website for DrawWithFriends:

- **index.html** — Main landing page and frontend room UI shell
- **privacy.html** — Privacy policy page
- **support.html** — Support / contact page
- **styles.css** — Site styling

These are frontend-only starter pages placed at the repository root. No backend or real-time sync included — update and wire up as needed.

To view locally, simply open `index.html` in a web browser. To publish, consider using GitHub Pages or your preferred hosting platform.

---

Built with ❤️ by Jamie | November 2025



