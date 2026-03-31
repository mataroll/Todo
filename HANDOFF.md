# Todo App — Handoff Note

## Project Location
`/Users/matarroll/Desktop/Todo/` — ACTIVE project.
Firebase project: `life-center-985b5` (same as LifeCommand).

## Run
```
cd /Users/matarroll/Desktop/Todo && bash run.sh
```
Builds + launches on iPhone 17 simulator. iPhone build requires opening Xcode and setting team manually (Personal Team, LAUYA46MGB). User handles iPhone deploy themselves.

---

## What's Built

### Architecture
- SwiftUI iOS app, Firebase Firestore real-time sync, Hebrew RTL throughout
- 3 tabs: HomeView (דף הבית), BoardView (רשימה), DetectiveBoardView (לוח בלש)
- No auth — single user, direct Firestore access

### Detective Board (main feature)
- **Canvas**: 4200×2200pt, starts at 0.35 zoom centered on content
- **Zoom/pan**: `ZoomableScrollView` (UIViewRepresentable wrapping UIScrollView) — native pinch zoom at correct anchor
- **Cards**: `DraggableBoardCard` — long press (0.35s) → drag to move, stationary hold (<8px) → popup menu
- **Drag fix**: RTL flips DragGesture.translation.width, so X uses `savedPosition.x - t.width`
- **Positions**: Saved to `nodePositions` Firestore collection per card, loaded via real-time listener
- **Default positions**: Computed from `categoryOrigins` map, 5 cols × N rows, colSpacing=185, rowSpacing=115
- **Lines**: Drawn on SwiftUI `Canvas`, straight lines clipped to card edges (not center-to-center). Uses `edgeOffset` func that clips to card bounding box using actual `cardWidth` per node.
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
- `addConnection(from:to:colorHex:)` / `removeConnection(from:to:)`
- `updateNode(_:)` — full `setData(from:)` overwrite
- `startListeningPositions()` / `savePosition(nodeId:position:)`
- `clearAllConnections()` — queries Firestore directly (not in-memory) for batch clear

### Utility
- `ColorExtension.swift`: `Color(hex:)` init + `hexString` computed var (needs UIKit, uses `UIColor`)

---

## Firestore State
- **nodes** collection: ~425 documents (duplicates from multiple seed runs — user aware, not addressed yet)
- **nodePositions** collection: per-card CGPoint positions
- **connections**: 1 real connection exists: "מערכת כריזה לאוטו" → "דיבור עם אבא" (red #FF383C)
- All old `dependencies`-based connections were bulk-cleared

---

## Known Issues / Next Steps
1. **Duplicate nodes**: ~425 docs but ~200 unique tasks (multiple seed runs). Causes crowded board layout. Needs dedup or wipe + re-seed.
2. **Category title colors**: Discussed but not implemented (would be stored in `boardSettings` Firestore doc)
3. **Detective board tab icon**: User has a Gemini-generated PNG in Downloads (black on transparent). Needs to be added as asset and wired to tab.
4. **iCloud/CloudKit migration**: User wants to move off Firebase eventually. Not urgent.
5. **Photo/PDF attachments**: UI placeholders exist in NodeDetailView but backend not implemented.

---

## Key Design Decisions & Gotchas
- RTL (`layoutDirection: .rightToLeft`) is set on NavigationStack and propagates everywhere. `.position()` uses absolute coords so it's unaffected. `DragGesture.translation.width` IS flipped — always negate X.
- `clearAllConnections` MUST query Firestore directly (not `service.nodes`) — in-memory array only has subset of 425 docs.
- SourceKit shows "Cannot find type" errors across files — these are false positives, actual compiler builds fine.
- `try?` in `updateNode` silently swallows Firestore write errors.
- Canvas `edgeOffset` uses `cardHalfH: CGFloat = 42` as fixed estimate for card height — works well for typical content.
