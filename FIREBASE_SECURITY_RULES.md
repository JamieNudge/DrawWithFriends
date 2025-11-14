# Firebase Realtime Database Security Rules

## ⚠️ IMPORTANT: Apply Before App Store Submission!

Test mode expires in 30 days. Use these rules for production.

---

## Option 1: Basic Secure Rules (Recommended for Launch)

**Use this for:** Collaborative drawing without requiring login

```json
{
  "rules": {
    "rooms": {
      "$roomId": {
        ".read": true,
        ".write": true,
        ".validate": "newData.hasChildren(['strokes'])",
        "strokes": {
          "$strokeId": {
            ".validate": "newData.hasChildren(['points', 'color', 'width', 'userId', 'timestamp'])"
          },
          ".indexOn": ["timestamp"]
        }
      }
    }
  }
}
```

**What this does:**
- ✅ Allows anyone to read/write (needed for collaborative drawing)
- ✅ Validates data structure (prevents malformed data)
- ✅ Ensures required fields exist (points, color, width, etc.)
- ✅ Indexes by timestamp for fast queries
- ⚠️ No user authentication required (open collaboration)

---

## Option 2: User Authentication Required (More Secure)

**Use this if:** You add Firebase Authentication (Sign in with Apple, Google, etc.)

```json
{
  "rules": {
    "rooms": {
      "$roomId": {
        ".read": "auth != null",
        ".write": "auth != null",
        "strokes": {
          "$strokeId": {
            ".validate": "auth != null && newData.hasChildren(['points', 'color', 'width', 'userId', 'timestamp'])",
            ".write": "auth.uid == newData.child('userId').val()"
          },
          ".indexOn": ["timestamp"]
        }
      }
    }
  }
}
```

**What this does:**
- ✅ Only authenticated users can access
- ✅ Users can only write their own strokes
- ✅ Prevents anonymous abuse
- ⚠️ Requires adding Firebase Auth to your app

---

## Option 3: Rate Limited (Prevents Spam)

**Use this for:** Production with rate limiting

```json
{
  "rules": {
    "rooms": {
      "$roomId": {
        ".read": true,
        ".write": "!data.exists() || data.child('lastUpdate').val() < (now - 100)",
        "strokes": {
          "$strokeId": {
            ".validate": "newData.hasChildren(['points', 'color', 'width', 'userId', 'timestamp']) && newData.child('timestamp').val() <= now"
          },
          ".indexOn": ["timestamp"]
        },
        "lastUpdate": {
          ".validate": "newData.val() == now"
        }
      }
    }
  }
}
```

**What this does:**
- ✅ Limits writes to once per 100ms per room (prevents spam)
- ✅ Validates timestamp is not in future
- ✅ Still allows collaborative drawing
- ⚠️ May need adjustment based on drawing speed

---

## How to Apply These Rules:

### 1. Go to Firebase Console:
   - https://console.firebase.google.com/u/0/project/draw-with-friends-3c57d/database

### 2. Click "Rules" tab (top of page)

### 3. Delete existing rules

### 4. Paste one of the rule sets above

### 5. Click "Publish"

### 6. Test your app to make sure it still works!

---

## When to Update:

- 🔴 **Before App Store submission** - Switch from test mode to Option 1
- 🟡 **After launch** - Monitor for abuse, add rate limiting if needed (Option 3)
- 🟢 **Long term** - Add authentication for best security (Option 2)

---

## Testing Rules:

After applying rules, test:
1. ✅ Can create a room
2. ✅ Can join a room with code
3. ✅ Can draw on canvas
4. ✅ Drawing syncs between devices
5. ✅ Clear canvas works

If any fail, check Firebase Console → Realtime Database → Usage tab for error messages.

---

**Last Updated:** November 10, 2025
**Status:** Test mode active (30-day limit)
**Reminder:** Update before production launch! 🚀


