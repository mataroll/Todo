# Todo App — Handoff Note

## Project Location
`/Users/matarroll/Desktop/Todo/` — ACTIVE project.
Firebase project: `life-center-985b5` (same as LifeCommand).
GoogleService-Info.plist has bundle ID `com.mataroll.LifeCommand` — Firebase warning on launch is harmless, data still syncs fine.

## Run
```
~/Desktop/Under\ the\ Hood/launch-simulator.sh
```
Builds + launches on iPhone 17 simulator. For iPhone: plug in → Xcode → Cmd+R (Personal Team, LAUYA46MGB).

---

## What's Built

### Architecture
- SwiftUI iOS app, Firebase Firestore real-time sync, Hebrew RTL throughout
- 3 tabs: HomeView (דף הבית), BoardView (רשימה), DetectiveBoardView (לוח בלש)
- No auth — single user, direct Firestore access
- **Offline-first**: Firestore `PersistentCacheSettings` enabled — data loads from local cache instantly after first launch, syncs changes in background

### App Icon & Tab Icons
- **App icon**: node diagram JPEG resized to 1024×1024 → `Todo/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- **Board tab icon**: same image as template asset → `BoardIcon.imageset`, used in ContentView with `image: "BoardIcon"`

### Activity Rings (HomeView top)
- `ActivityRingsView` — concentric Apple Watch-style rings, `RingData` model (id, progress, color, label)
- `ActivityRingsRow` — rings + legend labels side by side, shown at top of HomeView
- 3 rings: הושלם (green), פעיל (blue), חסום (red) — content/meaning defined by user later
- `HomeView.buildRings(nodes:)` is static so both HomeView and TodoApp can call it

### Live Activity (Lock Screen + Dynamic Island)
- `RingsActivityAttributes.swift` — shared attributes struct (in main app target)
- `LiveActivityManager.swift` — singleton, starts/updates/ends the activity
- `RingsLiveActivity.swift` (widget target) — lock screen + Dynamic Island UI with rings
- Wired in `TodoApp`: `.onChange(of: firebaseService.nodes)` → `LiveActivityManager.shared.update(rings:)`
- Starts automatically on first Firebase data load, updates on every sync
- **Free account**: local updates work (start/update while app is open). Remote push updates need $99 account.
- Info.plist keys: `NSSupportsLiveActivities = YES`, `NSSupportsLiveActivitiesFrequentUpdates = YES`

### Widget (TodoWidgetExtension)
- Small: counts (פעיל/חסום/פתוח) + top task name
- Medium: counts column + list of top 5 active tasks
- **Data strategy (dual fallback)**:
  - Simulator: reads from App Group `group.com.mataroll.Todo` via UserDefaults (written by `FirebaseService.saveWidgetData()`)
  - iPhone (free account): App Groups require paid membership → widget fetches directly from **Firestore REST API** (`https://firestore.googleapis.com/v1/projects/life-center-985b5/databases/(default)/documents/nodes?key=...`)
- Refreshes every 30 minutes
- To install on iPhone: plug in → Xcode → Cmd+R (widget is embedded in main app build)

### Detective Board (main feature)
- **Canvas**: 4200×2200pt, starts at 0.35 zoom centered on content
- **Zoom/pan**: `ZoomableScrollView` (UIViewRepresentable wrapping UIScrollView) — native pinch zoom at correct anchor
- **Cards**: `DraggableBoardCard` — long press (0.35s) → drag to move, stationary hold (<8px) → popup menu
- **Drag fix**: RTL flips DragGesture.translation.width, so X uses `savedPosition.x - t.width`
- **Positions**: Saved to `nodePositions` Firestore collection per card, loaded via real-time listener
- **Default positions**: Computed from `categoryOrigins` map, 5 cols × N rows, colSpacing=185, rowSpacing=115
- **Lines**: Drawn on SwiftUI `Canvas`, straight lines clipped to card edges. Uses `edgeOffset` func clipped to card bounding box using actual `cardWidth` per node.
- **Arrow heads**: Drawn at destination endpoint
- **Card popup menu**: `CardActionMenu` — blur overlay, 3 buttons (Edit / Connect / Cancel)
- **Edit sheet**: `CardEditSheet` — rename, status, S/M/L size, card color (ColorPicker), link, notes, outgoing+incoming connections with swipe-to-delete
- **Connection picker**: `ConnectionPickerView` — direction (from/to), line color picker, searchable node list

### Data Model (`Node.swift`)
- `Connection` struct: `toId: String`, `colorHex: String` (default `#CC1111`)
- `connections: [Connection]` on source node
- `cardSize: CardSize` enum (small/medium/large) with `cardWidth` + `fontSize`
- `customColor: String?` (hex) for per-card color
- `dependencies: [String]` kept for auto-blocking logic

### Firebase (`FirebaseService.swift`)
- `db` marked `nonisolated(unsafe)` — Firestore is thread-safe, avoids Swift concurrency warnings
- `startListening()` uses `includeMetadataChanges: false` — only fires on real data changes
- `isLoading` only shows spinner when `nodes.isEmpty` (first launch), not on every open
- `addConnection(from:to:colorHex:)` / `removeConnection(from:to:)`
- `updateNode(_:)` — full `setData(from:)` overwrite
- `startListeningPositions()` / `savePosition(nodeId:position:)`
- `clearAllConnections()` — queries Firestore directly (not in-memory) for batch clear
- `saveWidgetData(_:)` — writes to App Group UserDefaults + reloads widget timelines

---

## Firestore State
- **nodes** collection: ~425 documents (duplicates from multiple seed runs — user aware)
- **nodePositions** collection: per-card CGPoint positions
- **connections**: real connections exist on board

---

## Known Issues / Next Steps
1. **Duplicate nodes**: ~425 docs but ~200 unique tasks (multiple seed runs). Needs dedup or wipe + re-seed.
2. **Category title colors**: Discussed but not implemented (would be stored in `boardSettings` Firestore doc)
3. **iCloud/CloudKit migration**: User wants to move off Firebase eventually. Not urgent.
4. **Photo/PDF attachments**: UI placeholders exist but backend not implemented.
5. **Live Activity remote updates**: Need $99 Apple Developer account for push-based updates when app is killed.

---

## Key Design Decisions & Gotchas
- RTL (`layoutDirection: .rightToLeft`) on NavigationStack propagates everywhere. `.position()` uses absolute coords so unaffected. `DragGesture.translation.width` IS flipped — always negate X.
- `clearAllConnections` MUST query Firestore directly (not `service.nodes`) — in-memory array only has subset of 425 docs.
- SourceKit shows "Cannot find type" errors across files — false positives, actual compiler builds fine.
- Canvas `edgeOffset` uses `cardHalfH: CGFloat = 42` as fixed estimate for card height.
- App Group (`group.com.mataroll.Todo`) requires paid Apple Developer account on real device — widget bypasses this with direct Firebase REST fetch.
- `wipeAndReseed()` pre-encodes seed nodes on MainActor before entering Firestore callbacks to avoid Swift 6 actor isolation warning.
