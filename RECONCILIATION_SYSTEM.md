# Stroke Reconciliation System

## Problem
When both users draw simultaneously, strokes from the second person to finish were being lost. This was a classic **race condition** where canvas updates would overwrite each other.

## Solution: CRDT-style Reconciliation

Instead of trying to prevent conflicts with locks, we now use a **reconciliation** approach where:

1. **Every stroke gets a unique ID and timestamp** immediately when created (local or remote)
2. **All strokes are tracked in a collection** (`allKnownStrokes`) indexed by ID
3. **The canvas is rebuilt from this collection** whenever new strokes arrive
4. **Both devices independently converge to the same state** by merging their stroke collections

This is similar to how Conflict-free Replicated Data Types (CRDTs) work.

## How It Works

### Data Structures

```swift
private struct StrokeInfo {
    let id: String              // Unique identifier
    let data: Data              // Serialized PKDrawing data
    let timestamp: Double       // When stroke was created
    let originalSize: CGSize?   // Original canvas size (for scaling)
    let originalUserId: String  // Who created it
    var stroke: PKStroke?       // Cached decoded stroke
}

private var allKnownStrokes: [String: StrokeInfo] = [:]  // All strokes by ID
private var strokeOrder: [String] = []                    // IDs sorted by timestamp
```

### Flow

#### Drawing Locally
1. User draws stroke → appears on canvas
2. Timer detects new stroke (canvas count increased)
3. Assign unique ID and timestamp
4. Add to `allKnownStrokes` immediately
5. Send to Firebase

#### Receiving Remote Strokes
1. Firebase callback receives stroke
2. Check if we already have this ID (ignore duplicates)
3. Add to `allKnownStrokes`
4. Insert ID into `strokeOrder` (sorted by timestamp)
5. **Rebuild entire canvas** from all known strokes

#### Canvas Rebuild (Reconciliation)
1. Start with empty PKDrawing
2. Iterate through `strokeOrder` (timestamp-sorted)
3. For each ID, get stroke from `allKnownStrokes`
4. Decode and scale if needed (cache for performance)
5. Append to new drawing
6. Apply rebuilt drawing to canvas

### Key Benefits

✅ **No race conditions** - strokes are never lost
✅ **Automatic conflict resolution** - both devices converge to same state
✅ **Order preserved** - strokes appear in timestamp order
✅ **Duplicate prevention** - stroke IDs prevent re-processing
✅ **Performance** - cached decoded strokes avoid repeated processing

## Critical Fixes

### Fix 1: Deferred Rebuild Timing
**Problem**: When a rebuild was deferred while the user was drawing, executing it immediately after they finished would wipe out the stroke they just drew (PKCanvasView hadn't updated the drawing object yet).

**Solution**: Always wait 50ms after the user finishes drawing to allow PKCanvasView to update, then capture local strokes and check for deferred rebuilds.

**Flow:**
1. Remote stroke arrives while user is drawing → defer rebuild
2. User finishes drawing stroke #N → `canvasViewDidEndUsingTool()` fires
3. Wait 50ms for PKCanvasView to update
4. **FIRST**: Capture stroke #N (now it's in the drawing object)
5. **THEN**: Execute any deferred rebuild
6. Result: Rebuild includes stroke #N ✅

### Fix 2: Edge Case - Stroke Arrives During Wait
**Problem**: If a remote stroke arrived during the 50ms wait period after drawing ended, it could be missed.

**Solution**: The post-drawing check now ALWAYS captures local strokes and checks for any pending rebuilds, regardless of when they were flagged.

### Fix 3: Detailed Positioning Logs
**Added**: Comprehensive logging during canvas rebuild to track stroke positions and identify any scaling issues:
- Stroke order and IDs
- Whether each stroke is cached or newly scaled
- Before/after positions for scaled strokes
- Final drawing bounds

This helps diagnose "positioning errors" that occur with many strokes on screen.

## Testing

To test simultaneous drawing:
1. Connect iPad and iPhone to same room
2. Both start drawing at the same time
3. Draw overlapping strokes
4. Both should finish with identical canvas showing all strokes from both devices
5. Try drawing while the other device sends strokes - your stroke should not disappear

## Code Changes

### Main Functions

- `syncSimultaneous()` - Timer that calls `captureNewLocalStrokes()`
- `captureNewLocalStrokes()` - Detects new local strokes, assigns IDs, adds to collection, sends to Firebase
- `observeStrokes()` - Receives remote strokes, adds to collection, triggers rebuild
- `rebuildCanvas()` - Reconciles all strokes into a single canvas (defers if user is drawing)
- `handleDrawingStarted()` - Sets flag to defer rebuilds
- `handleDrawingEnded()` - Captures local strokes, then executes any deferred rebuild
- `resetStrokeTracking()` - Clears tracking on canvas clear

### Removed

- Old approach that tried to append strokes incrementally
- Locking mechanisms that could block drawing
- Complex counting logic to skip incoming strokes

