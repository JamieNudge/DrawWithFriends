# Draw With Friends - Diagnostics Guide

## Overview

The app now includes a built-in diagnostics system to help debug synchronization issues. This system captures all relevant events, metrics, and errors that occur during a drawing session.

## How to Access Diagnostics

1. **Toggle Button**: Look for the floating chart icon 📊 in the bottom-right corner of the drawing canvas
2. **Tap the button** to show/hide the diagnostics overlay
3. **Red dot indicator**: If there are any errors, a red dot appears on the toggle button

## Diagnostics View Modes

### Metrics Dashboard (Default)
Shows real-time statistics:

**Connection Status**
- 🔌 Current connection state
- Green dot = Connected
- Yellow dot = Connecting  
- Red dot = Disconnected/Error

**Session Info**
- Room code
- User ID (first 8 characters)
- Device type (iPad/iPhone/Simulator)

**Stroke Metrics**
- Strokes Sent: Number of strokes you've drawn and sent
- Strokes Received: Number of strokes received from others
- Known Strokes: Total strokes in the collection
- Canvas Strokes: Actual strokes displayed on canvas

**Rebuild Metrics**
- Rebuilds: How many times canvas was rebuilt from collection
- Deferred: How many rebuilds were postponed (user was drawing)
- Sync Ticks: How many times the sync timer fired

**Current Status**
- Drawing: YES if you're currently drawing
- Rebuilding: YES if canvas is being rebuilt
- Errors: Count of errors (if any)

**Last Activity Timestamps**
- When you last sent a stroke
- When you last received a stroke
- When canvas was last rebuilt

### Full Logs Mode
Tap the list icon to see detailed event logs:

**Log Categories** (color-coded):
- 🔌 Connection events (cyan)
- 📤 Strokes sent (green)
- 📥 Strokes received (blue)
- 🔄 Canvas rebuilds (orange)
- ⏱️ Sync timer events (purple)
- ❌ Errors (red)
- ⚠️ Warnings (yellow)
- ℹ️ Info (white)
- 👆 User actions (mint)

**Features**:
- Auto-scrolls to latest entry
- Shows timestamp (HH:mm:ss.SSS)
- Keeps last 500 events
- Monospaced font for easy reading

## Actions

### Copy Diagnostics Report
1. Tap the document icon in the diagnostics header
2. Full report copied to clipboard
3. Green checkmark appears when copied
4. Paste into Notes, Messages, or email to share

**Report includes**:
- Session start time and duration
- Complete metrics summary
- All detailed logs

### Reset Session
- Tap the circular arrow icon
- Clears all logs and resets metrics
- Useful when starting a new test

## Common Scenarios & What to Look For

### Idle Timeout Issue
**Symptoms**: App stops syncing after being idle

**What to check**:
1. Look at "Last Activity" timestamps
2. Check if connection status changed to "Disconnected"
3. Look for Firebase connection errors in logs
4. Check if sync timer is still firing

**Expected logs**:
```
🔌 Connection: Connected
⏱️ Sync: ... (should fire every 0.5s)
```

**Problem indicators**:
```
🔌 Connection: Disconnected
❌ ERROR: Firebase connection lost
⏱️ Sync: ... (long gap in timestamps)
```

### Simultaneous Drawing Failures
**Symptoms**: One user's strokes disappear when both draw at once

**What to check**:
1. Compare "Strokes Sent" vs "Strokes Received" on both devices
2. Check if rebuilds are being deferred properly
3. Look for timing between "User FINISHED drawing" and rebuild execution

**Expected logs**:
```
👆 User STARTED drawing
📥 Received stroke from [other user]
🔄 Rebuild DEFERRED (user drawing)
👆 User FINISHED drawing
ℹ️ Post-drawing check
ℹ️ NEW LOCAL STROKES: 1
📤 Sent stroke [id]
🔄 Rebuild executed: X strokes
```

**Problem indicators**:
```
🔄 Rebuild executed: X strokes
(Your stroke not captured before rebuild)
```

### Positioning Errors
**Symptoms**: Strokes appear in wrong position with many strokes on screen

**What to check**:
1. Enable full logs mode
2. Look for SCALED messages during rebuilds
3. Check if canvas sizes match between devices

**Detailed rebuild logs show**:
```
🔄 Rebuild executed
   1. [id] SCALED (393,585)→(810,874)
      bounds: (130,68)→(307,103)
   2. [id] (cached) pos:(237,132) size:(345,654)
   ...
📐 Final drawing bounds: (58, 18, 634, 823)
```

## Tips for Reporting Issues

When reporting a sync problem, please:

1. **Enable diagnostics** before reproducing the issue
2. **Reproduce the problem** with diagnostics visible
3. **Copy the report** immediately after
4. **Note what happened** (e.g., "Drew circle on iPad, disappeared on iPhone")
5. **Include both devices' reports** if possible

## Example Diagnostic Report

```
========================================
DRAW WITH FRIENDS - DIAGNOSTIC REPORT
========================================
Session Start: 2025-11-12 10:30:00
Report Time: 2025-11-12 10:45:00
Session Duration: 900s

=== DIAGNOSTIC METRICS ===
Room: 835854
User: 348C4B6D
Device: iPad
Connection: Connected

Strokes Sent: 15
Strokes Received: 12
Known Strokes: 27
Canvas Strokes: 27

Rebuilds: 12 executed, 3 deferred
Sync Timer Fires: 1800
Errors: 0

User Drawing: NO
Currently Rebuilding: NO

Last Stroke Sent: 5s ago
Last Stroke Received: 3s ago
Last Rebuild: 3s ago

=== DETAILED LOGS (247 entries) ===

ℹ️ 10:30:00.123 Starting observation - userId: 348C4B6D
🔌 10:30:00.124 Connection: Connecting
...
```

## Troubleshooting the Diagnostics System

If diagnostics aren't showing up:
- Make sure you're on the drawing canvas (not room selection)
- Tap the bottom-right corner where the button should be
- Try restarting the app

If metrics seem incorrect:
- Use the reset button to clear and start fresh
- Check that both devices are in the same room
- Verify connection status is "Connected"

## Privacy Note

Diagnostic logs are:
- Stored only in memory (not saved to disk)
- Cleared when you leave the room
- Only accessible through the copy function
- User ID and room codes are truncated for readability


