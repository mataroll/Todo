# Coach App — Vision Document

## Core Philosophy
The phone is a coach standing next to you. It can't stop you from doing something bad, but it puts the data in your face so you change your habits. The goal is to open the app as little as possible — everything happens from the lock screen, widgets, and live activity.

---

## The Two Sides of Every Day

### DO (Positive Habits)
Things to confirm you did. Marked from widget/live activity, not the app.
- Exercise
- Prayer
- Breakfast
- Work / Study
- Hobby (piano, etc.)

### AVOID (Negative Habits)
Things to mark when you slipped. One tap from the lock screen widget or live activity.
- Coca Cola
- Sugar
- Useless screen time
- No jerk off
- Spending 40 min on phone in bed

A perfect day = all positives confirmed + zero negatives marked.
Categories and habits are added only through code (via Claude), not through the app UI.

---

## Streak Logic
- A day counts only if ALL categories hit 100%
- Weekends: TBD (for now treated as normal days)
- Wake-up tracking: geofence — if you exit a 500m radius from home, "left home" auto-confirms in background (no app open needed). Time window TBD.
- Streak resets on any imperfect day

---

## Timeframes — The Three Views (in רשימה tab)
Tasks are tagged as one of:
- **יומי (Daily)** — resets every day, shows today's progress bar
- **שבועי (Weekly)** — resets every Saturday, shows week progress bar
- **שנתי (Yearly)** — once-a-year events (trips, milestones), shows year progress
- **None** — one-time tasks, appear only in הכל

Progress = tasks done / total tasks in that timeframe, shown as a colored bar.

---

## Money Section (₪ tab)
- Separate tab with shekel icon
- Bank statements and financial data loaded externally (not through the app UI)
- Budget ring on widgets = spending toward ₪2,000 monthly self-set limit
- Privacy: lock screen only shows sum of purchases > ₪200, never full bank balance
- Purchases (coachType: budget) are hidden from the main task lists, live in money tab only

---

## Widgets & Lock Screen (the real UI)

### Lock Screen Widget 1 — "Pulse" (accessoryRectangular)
- Three nested rings: Blue (daily), Green (weekly), Gold (budget)
- Percentages: 38 24 44
- Privacy spend: ₪8,668 (sum of purchases > ₪200)

### Lock Screen Widget 2 — "הימנע" / Avoid (accessoryRectangular)
- One icon per negative habit (🥤 🍫 📱)
- Shows today's count next to each
- TAP to record a slip — calls Firestore REST directly, no app opens
- Refreshes every 15 minutes

### Home Screen Widget — "Pulse" (systemSmall)
- Same rings + percentages as lock screen version

### Home Screen Widget — "Weekly Vision" (systemLarge)
- Weekly tasks list with checkmark buttons (tap = mark done via App Intent)
- Budget remaining
- Days until Saturday

### Live Activity — "Execution Board" (expanded + Dynamic Island)
- 🔥 streak count
- Timeline: Now (cyan) / Next / Next-Next with time ranges
- Codenames: top 3 priority tasks in short form
- Habit icons: tap to confirm (calls Firestore REST via App Intent)
- Avoid row: 🥤 🍫 📱 tap to record a slip
- Dynamic Island compact: mini rings + daily %

---

## App Screens (minimal, for quick marking only)

### דף הבית (Home)
- Activity rings
- Summary header (day of year, daily % complete)
- Stats grid: budget remaining, weekly goals, streak count, open tasks
- Streak calendar: full month grid, each day colored by completion %
  - Gray = no data, Blue gradient = partial, Green = perfect day
  - Tap a day → breakdown by category (exercise/work/study/hobby) with progress bars
- Habits row: tap to confirm daily habits
- Active nodes: quick mark done

### רשימה (List)
- Segmented tabs: יומי | שבועי | שנתי | הכל
- Per tab: progress bar (done/total, %) + task list
- הכל excludes budget items

### לוח בלש (Detective Board)
- Zoomable cork board with all nodes as sticky cards
- Red string connections between related tasks
- Toggle (default ON) to hide purchases + their connection lines
- Drag to reposition cards, positions saved to Firebase

### כסף (Money)
- TBD — will show bank statement data loaded externally
- Budget tracking, spending categories

---

## Data Model

### Node (main task unit)
- `title`, `category` (NodeCategory), `status` (blocked/open/inProgress/done)
- `coachType`: daily | weekly | yearly | budget | none
- `habitCategory`: exercise | work | study | hobby | none (for streak tracking)
- `isConfirmed`: Bool (daily confirmation, resets each day)
- `startTime`, `endTime`: for timeline in live activity
- `priority`, `dependencies`, `connections` (for detective board)
- `price`: for budget items

### DailyLog (streak history)
- Collection: `dailyLogs/{yyyy-MM-dd}`
- `exerciseProgress`, `workProgress`, `studyProgress`, `hobbyProgress`: 0.0–1.0
- `overallProgress`: average of active categories
- `isPerfect`: true only if ALL active categories = 1.0
- Written automatically whenever nodes change while app is active

### DailySlips (negative habits)
- Collection: `dailySlips/{yyyy-MM-dd}`
- Fields per habit key: `coke`, `sugar`, `screen` (integer counts)
- Incremented atomically via Firestore batchWrite REST API (from widget, no app needed)

### NodePositions
- Collection: `nodePositions/{nodeId}`
- `x`, `y`: CGPoint for detective board card positions

---

## Technical Stack
- SwiftUI, WidgetKit, ActivityKit, CoreLocation
- Firebase Firestore (real-time listener in app, REST API from widgets)
- App Intents for interactive widgets/live activity (iOS 17+)
- Geofencing via CLCircularRegion for auto wake-up detection
- Offline cache enabled (PersistentCacheSettings unlimited)
- Simulator: network issues prevent Firebase connection — test on real iPhone
- Widget extension fetches Firestore via REST with API key (no Firebase SDK in widget)

---

## Negative Habits Config (add here, then update code)
```swift
let negativeHabits: [(key: String, icon: String, label: String)] = [
    ("coke",   "🥤", "קולה"),
    ("sugar",  "🍫", "סוכר"),
    ("screen", "📱", "מסך"),
    // add more here
]
```

---

## What's Built
- [x] Firebase sync with offline cache
- [x] Detective board with connections and positions
- [x] Live Activity (rings, timeline, habits, avoid buttons)
- [x] Lock screen Pulse widget (rings + spending)
- [x] Lock screen Avoid widget (slip counters + tap to record)
- [x] Home screen widgets (small pulse + large weekly)
- [x] App Intents: confirm habit, mark done, record slip
- [x] רשימה with Daily/Weekly/Yearly/All tabs + progress bars
- [x] Money tab (₪ placeholder)
- [x] Streak calendar on home page (full month grid)
- [x] DailyLog model and Firebase collection
- [x] HabitCategory on Node (exercise/work/study/hobby)

## What's Pending
- [ ] Geofence wake-up detection (home coordinates not set yet)
- [ ] Negative habit slips affecting streak/daily score
- [ ] Weekend behavior for streak
- [ ] Money tab content (bank statement import)
- [ ] Wake-up time cutoff logic
- [ ] Yearly tasks fully wired
- [ ] Task unlock dependencies (e.g., 30-day run streak → unlocks swimming)
- [ ] Per-task habit icon (currently hardcoded 🏃)
- [ ] Daily isConfirmed reset at midnight
