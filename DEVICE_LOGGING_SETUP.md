# 🎯 Device Logging - Correct Method

## ✅ Use Console.app (Easiest & Most Reliable)

### Step 1: Open Console.app
- Press **Cmd+Space** (Spotlight)
- Type: `Console`
- Press **Enter**

### Step 2: Connect & Select Devices
1. **Plug in both devices** (iPad and iPhone) via USB or use Wi-Fi sync
2. In Console.app's **left sidebar**, you'll see:
   - Your Mac
   - Your iPad (e.g., "Jamie's iPad")
   - Your iPhone (e.g., "Jamie's iPhone")

### Step 3: Start Logging on BOTH Devices

**For iPad:**
1. Click on your **iPad** in the left sidebar
2. Click the **"Start"** button in the top toolbar
3. In the **search bar** (top right), type: `Draw With Friends`
4. Press Enter

**For iPhone:**
1. Open a **new Console window** (File → New Window, or Cmd+N)
2. Click on your **iPhone** in the left sidebar
3. Click the **"Start"** button
4. In the **search bar**, type: `Draw With Friends`
5. Press Enter

### Step 4: Test Your App
1. Launch **Draw With Friends** on both devices
2. Join the **same room code**
3. **Draw on both devices**
4. Watch the logs appear in **both Console windows**

You should see:
- 📤 `SENDING stroke` messages
- 📨 `STROKE RECEIVED` messages  
- Real-time updates as you draw

### Step 5: Save the Logs

**When you're done testing:**

**iPad Console Window:**
1. **Cmd+A** (select all)
2. **Cmd+C** (copy)
3. Open TextEdit, paste, save as `ipad_logs.txt`

**iPhone Console Window:**
1. **Cmd+A** (select all)
2. **Cmd+C** (copy)  
3. Open TextEdit, paste, save as `iphone_logs.txt`

---

## 💡 Tips

- **Clear logs** before testing: Click "Clear" button in Console toolbar
- **Timestamps** are on the left - makes it easy to match events
- **Filter is powerful**: You can search for specific stroke IDs (e.g., `B2888217`)
- **Multiple windows**: You can tile them side-by-side to watch both simultaneously

---

## 🔍 What to Look For

### ✅ Good Sync:
```
iPad:  📤 SENDING stroke ABC123
iPhone: 📨 STROKE RECEIVED: strokeId=ABC123  [within 1 sec]
```

### ❌ Missing Stroke:
```
iPad:  📤 SENDING stroke ABC123
iPhone: [no matching STROKE RECEIVED]
```

If you see missing strokes, send me BOTH log files and I can trace exactly where it got lost!

---

## Alternative: Xcode Debug Console

If Console.app isn't working, you can also:
1. Run app from **Xcode on iPad** → see logs in Xcode console
2. Run app **standalone on iPhone** → logs go to Console.app
3. You'll need to manually correlate by timestamp


