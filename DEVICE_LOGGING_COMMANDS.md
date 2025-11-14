# 🎯 Draw With Friends - Device Logging Commands

## ⚠️ UPDATED: Use Console.app Instead!

The Terminal `log stream --device` commands don't work on current macOS.

**👉 See `DEVICE_LOGGING_SETUP.md` for the correct method using Console.app**

---

## OLD (Don't Use - Kept for Reference)

### Terminal 1 - First Device (iPad)
```bash
log stream --device --predicate 'processImagePath CONTAINS "Draw With Friends"' --style compact
```

### Terminal 2 - Second Device (iPhone)
```bash
log stream --device --predicate 'processImagePath CONTAINS "Draw With Friends"' --style compact
```

---

## If You Have Multiple Devices Connected

First, find your device names:
```bash
xcrun xctrace list devices
```

Then use the specific device name:

### Terminal 1 - iPad
```bash
log stream --device-name="Jamie's iPad" --predicate 'processImagePath CONTAINS "Draw With Friends"' --style compact
```

### Terminal 2 - iPhone
```bash
log stream --device-name="Jamie's iPhone" --predicate 'processImagePath CONTAINS "Draw With Friends"' --style compact
```

---

## Testing Steps

1. **Start both log streams** in separate Terminal windows
2. **Launch the app** on both devices
3. **Join the same room** (e.g., room code "129734")
4. **Draw strokes** on both devices simultaneously
5. **Watch the logs** - you should see:
   - `📤 SENDING stroke` when a device sends
   - `📨 STROKE RECEIVED` when a device receives
6. **Stop logging** with `Ctrl+C` in each terminal
7. **Copy logs** (Cmd+A, Cmd+C) and paste into text files

---

## What to Look For

✅ **Good sync:**
- Every `📤 SENDING` on one device shows `📨 STROKE RECEIVED` on the other
- Timestamps are close together (< 1 second apart)
- `Canvas strokes:` count matches on both devices

❌ **Missing strokes:**
- `📤 SENDING` appears but no matching `📨 STROKE RECEIVED`
- `Canvas strokes:` counts are different
- Look for the stroke ID to trace it through both logs

---

## Alternative: Use Console.app Instead

If Terminal commands don't work:
1. Open **Console.app** (Spotlight search)
2. Connect both devices
3. Select each device in sidebar
4. Click "Start" to begin capturing
5. Filter by typing: `Draw With Friends`
6. Export: Right-click → "Save Selection..."

