# Build Sessions

---

## Session 1 — Board: Arrows + Notes (no Xcode, Python only)
**Outcome:** Learning path fully drawn, every node has a clear description.
- Draw all dependency arrows (math pyramid, science track, coding track)
- Add notes to each learning path node explaining what it is and what unlocks next
- Mark done logic: completing a course → weekly test reminder auto-created + next course unlocks
- No app code needed — pure Supabase PATCH calls

## Session 2 — Board fixes (Xcode)
**Outcome:** Board works the same on iPhone and iPad, arrows look right.
- Fix arrow anchors: bottom of source card → top of destination card
- Sync headlines + free labels to Supabase (currently local-only, breaks across devices)
- Unify new task / edit task into one sheet (TaskSheet with create/edit mode)

## Session 3 — Supabase daily_schedule table + chain reader (Xcode)
**Outcome:** App reads today's chain from Supabase. Claude can write tomorrow's plan without Xcode.
- Create `daily_schedule` table in Supabase
- LiveActivityManager reads the table, finds current pending step, pushes to live activity
- Window 1: current step (chain type = yes/no buttons, pomodoro type = bar)
- Windows 2-4: next steps dimmed

## Session 4 — Morning chain + Pomodoro (Xcode)
**Outcome:** Wake → pray → breakfast → work actually works on the lock screen.
- Chain steps: yes/no buttons, each tap writes status back to Supabase, unlocks next
- Pomodoro: 50-min animated progress bar, flips to 10-min break confirm, repeats
- Skip = moves forward, never gets stuck
- What's skipped is recorded (visible in HomeView / calendar later)

## Session 5 — Sport section (Xcode)
**Outcome:** New Sport tab. Tap "Outdoor" → Watch guides you step by step through the session.
- Sport tab: choose Running / Home / Outdoor
- Session chain: exercise → mark done (enter reps) or skip → rest timer (counts up, tap ready) → next
- Apple Watch companion: one step at a time, vibrate on rest end
- Per-exercise logging to Supabase (not per-round)
- Auto-progression: hit target on all sessions over 2 cycles → target bumps up

## Session 6 — Calendar section (Xcode)
**Outcome:** New Calendar tab showing full life history at a glance.
- Training history (sport sessions, reps, rounds completed per day)
- Habit streaks (daily habits confirmed/skipped)
- Monthly rhythm highlights (haircut due, car check, family call, teaching report)
- Upcoming: important dates and reminders
- Streak records visible

## Session 7 — Daily Claude dispatch
**Outcome:** End-of-day conversation with Claude updates tomorrow's live activity. No Xcode needed ever again for daily planning.
- Claude reads MATAR.md + asks about tomorrow
- Writes `daily_schedule` rows for the day
- App polls every 30s → live activity updates automatically
- Test: "tomorrow I have handball at 20:00" → watch the chain update on the phone

---

# Live Activity System — Build Plan

---

## The Core Model — Daily Chain

### What It Actually Is

The live activity is not a calendar. It's a **chain** — each task unlocks the next. The phone is always showing exactly one question: *what are you doing right now?*

The day is made of three types of blocks:

| Type | Behavior |
|------|----------|
| **Chain step** | Appears, you tap yes/no, next step unlocks |
| **Pomodoro block** | 50-min bar counts down, flips to 10-min break, you confirm, repeats |
| **Time block** | Appears at a set time, auto-advances when the window ends |

---

### Morning Chain (sequential, event-driven — not time-based)

```
[Wake up] ──tap──► [Pray] ──yes or no──► [Breakfast] ──yes or no──► [Study block starts]
```

- **Wake up** — appears at 7:00. Tap to start the day. This unlocks Pray.
- **Pray** — 30-minute window. Two buttons: ✓ התפללתי / ✗ לא התפללתי. Either one moves forward.
- **Breakfast** — same. ✓ אכלתי / ✗ דילגתי. Moves forward regardless.
- Skipping = recorded as a miss in rings/HomeView, but the chain never gets stuck.

The live activity **window 1** shows the current step full-screen, large confirm button.  
**Window 2** shows a dim preview of what's coming next.

---

### Work / Study Block (Pomodoro)

After breakfast the chain enters the Pomodoro loop:

```
[▓▓▓▓▓░░░░░ 50 min work] ──auto──► [10 min break — tap to confirm] ──tap──► repeat
```

- Live activity **window 1**: animated progress bar filling over 50 minutes
- At minute 50: bar turns green, label flips to "הפסקה 10 דקות"
- You tap confirm on the break → resets, next work block starts
- This repeats through the morning (4 cycles = ~4 hours)

The Pomodoro runs *within* the chain — it's one "block" in the sequence, self-repeating.

---

### Evening Block

Not fixed — depends on the day:
- Strength training some days
- Run some days (~9pm, 30 min including stretch)
- Handball / football on their days (see MATAR.md sports schedule)
- Pull-ups are part of strength evenings, not a standalone daily habit

Claude sets this at the Saturday session based on the week ahead.

---

### How the Live Activity Windows Are Used

| Window | Shows |
|--------|-------|
| 1 (tasks mode) | Current step in chain — big, full-screen, one button |
| 2 (rings mode) | Rings progress + next 2 tasks preview + 🌸 bad habit button |
| 3+ (tasks mode, offset) | Next tasks in the chain, dimmed |

The idea: glance at the lock screen → window 1 tells you exactly what to do right now. Swipe → window 2 shows the big picture (rings, what's coming).

---

### Corrections from Earlier Version

- ~~Pull-ups daily morning~~ → **Evening, not daily, strength days only**
- ~~תרגילים לליבי = heart exercises~~ → **Libby = Matar's student. Mark done after tutoring session.**
- The chain gates the next step — it does NOT auto-advance based purely on clock time (morning steps)

---

### Supabase Data Model — `daily_schedule` Table

```
date         text       "2026-04-15"
slot         int        order in chain (1, 2, 3…)
title        text       "להתפלל"
type         text       "chain" | "pomodoro" | "time_block"
window_min   int        max minutes before auto-skip (chain type)
yes_label    text       "התפללתי"
no_label     text       "לא התפללתי"
start_time   text       "07:00" (time_block type)
end_time     text       "07:30"
emoji        text       "🙏"
status       text       "pending" | "done" | "skipped"  ← app writes this
```

Claude Code updates `date` + `slot` rows each morning or Sunday night.  
The app reads the table, executes the chain, writes back `status`.  
**No Xcode needed to change the day's plan** — just a message to Claude.

---

## What We're Building

Two connected features:

1. **Smart Live Activity Chain** — 5 live activities on the lock screen at all times: 1 general (rings/streak), 4 showing the current + next activities in order for today. Time-aware — activities drop off when their window passes, new ones join at the end.

2. **Wireless Remote Updates** — Change your day's plan by messaging Claude, no cable or Mac connection needed. Claude writes the updated schedule to Supabase, the app picks it up within 30 seconds and refreshes the chain automatically.

---

## Part 1 — Smart Live Activity Chain

### The Problem Now
- Live Activities start and stay — no time awareness
- Prayer shows at 3:30 PM because nothing tells it to stop
- No chain — just one or two activities with no "what's next" context

### How It Works After

At any moment, the lock screen shows:

| Slot | Type | Content |
|------|------|---------|
| 1 | General (always on) | Rings progress, streak count, daily habit dots |
| 2 | NOW | Current activity — highlighted, with time remaining |
| 3 | Next | Next activity today |
| 4 | Then | 2nd upcoming |
| 5 | Then | 3rd upcoming |

As time passes, the chain shifts: the current one ends → drops off → everything moves up → a new one joins at the end.

### What Needs to Change in the App

**1. Daily Schedule Table in Supabase**
- New table: `daily_schedule`
- Fields: `date`, `slot` (1–4), `title`, `emoji`, `start_time`, `end_time`, `category`
- Claude writes here each evening (Saturday session sets the week, or on the fly mid-day)

**2. LiveActivityManager — Time-Aware Updates**
- On each 30-second refresh from Supabase, recompute which activities are current/upcoming
- Filter out anything whose `end_time` has already passed
- Build the chain: find the block whose window includes `now` → that's slot 2. Next 3 upcoming → slots 3–5
- If nothing is scheduled right now → slot 2 shows "Free time" or stays empty

**3. Prayer Times**
- Prayer times live in `MATAR.md` as part of the daily rhythm (morning after wake-up, evening before sleep)
- Add them as fixed daily entries in the schedule — they get placed automatically based on time of day
- Shacharit: 7:00–7:45. Maariv: ~23:00 (or whenever pre-sleep starts)
- These are injected into every day's chain automatically — Claude doesn't need to re-specify them each time

**4. General Slot (Slot 1)**
- Stays exactly as it is now — rings, streak, habit dots
- No changes needed here

---

## Part 2 — Wireless Remote Updates

### The Problem Now
- Live Activities only update when the app is open and running
- No way to change today's plan from a conversation without opening Xcode or connecting a cable

### How It Works After

```
You message Claude (any device, any time)
        ↓
Claude reads MATAR.md to understand the context
        ↓
Claude updates `daily_schedule` table in Supabase
        ↓
App polls Supabase every 30s (already doing this)
        ↓
LiveActivityManager sees new schedule → rebuilds the chain
        ↓
Lock screen updates — no cable, no Mac needed
```

### What Claude Needs

- Supabase URL + service key (write access) — store once, never re-enter
- Permission to read/write `daily_schedule` table
- MATAR.md as context so Claude knows your rhythm, prayer times, sports schedule, etc.

### The Daily Flow

**Saturday evening (weekly reset):**
- Tell Claude the week ahead — which days have teaching, sports, anything special
- Claude writes the full week's schedule to Supabase in one session
- Done — rest of the week runs automatically

**Mid-day change:**
- "Claude, I'm skipping handball tonight"
- Claude removes that slot, shifts the chain forward
- Phone updates within 30 seconds

**Fully spontaneous day:**
- Don't plan anything → the chain auto-builds from your standard rhythm in MATAR.md
- Prayer, study block, work, evening routine — all from the baseline profile

---

---

## Fix — Headlines & Free Labels Not Syncing Across Devices

### The Problem
- **Category headlines** → saved to `UserDefaults.standard` (key: `board_headlines_v1`) → local only, never leaves the device
- **Free labels** → saved to `UserDefaults.standard` (key: `board_free_labels_v1`) → same problem
- **Node cards** → saved to `node_positions` table in Supabase → syncs fine ✓

Moving a headline on iPad stays on iPad. Moving a note card on iPad shows up on iPhone instantly. Inconsistent because they use different storage.

### The Fix
Migrate both `saveHeadlineData()` and `saveFreeLabels()` from `UserDefaults` to Supabase — two new tables, loaded on startup and on the 30-second refresh cycle already in place.

**New Supabase tables:**

`board_headlines`
| column | type | notes |
|--------|------|-------|
| category | text | primary key (e.g. "work", "study") |
| x | float | position |
| y | float | position |
| text | text | custom label text |
| font_size | float | |

`board_free_labels`
| column | type | notes |
|--------|------|-------|
| id | text | primary key (UUID) |
| x | float | |
| y | float | |
| text | text | |
| font_size | float | |

**Code changes in `DetectiveBoardView.swift`:**
1. Replace `saveHeadlineData()` → POST/PATCH to `board_headlines` (upsert by category)
2. Replace `saveFreeLabels()` → POST/PATCH to `board_free_labels` (upsert by id)
3. Replace `UserDefaults` load in `onAppear` → fetch from Supabase (same pattern as `fetchPositions()`)
4. Wire into the existing 30-second refresh so any device change is picked up automatically

**No changes needed to:** node cards, notes, connections — those already sync correctly.

---

---

## Fix — Unify New Task / Edit Task + Add Location to New Task

### The Problem

Two completely separate UIs for the same concept:

**AddNodeView (new task):** Title, Category, Type (coachType), Notes, Link, Dependencies — that's it. No status, no size, no color, no photos, no reminder, no location.

**CardEditSheet (edit task):** Title, Status, Size, Color, Link, Notes, Photos, Files, Reminder (with location geocoding already built in). Missing: coachType, dependencies.

Result: you set up a task one way when creating it and get a totally different interface when editing it. Fields that only exist in one place feel like missing features.

Location is **already built** in `CardEditSheet` (geocode by name → lat/lon → geofence notification on entry/exit) but it's hidden behind the reminder type picker. It's never accessible from the new task flow at all.

### The Fix — One Unified Sheet

Replace both `AddNodeView` and `CardEditSheet` with a single `TaskSheet` that works in two modes: **create** and **edit**. Same layout, same fields, same order — the only difference is the title ("משימה חדשה" vs "עריכה") and whether fields are pre-filled.

**Unified field order (top to bottom):**

| Section | Fields |
|---------|--------|
| Basic | Title, Type (coachType), Category, Status, Size, Color |
| Details | Notes, Link |
| Location | Place name → geocode → lat/lon shown, on-entry/on-exit toggle |
| Media | Photos (camera + gallery), Files |
| Schedule | Reminder toggle → date / weekly days / monthly / custom |
| Relations | Dependencies (blocked by) |

### Location — How It Should Work

Already partially built — just needs to be surfaced properly:

- Text field: type a place name (e.g. "חדר כושר", "עבודה", "בית אבא")
- Tap "Find" → geocodes to lat/lon using `CLGeocoder` (already implemented in `NotificationManager`)
- Shows confirmed coordinates under the field
- Toggle: notify on **entry** or on **exit**
- Saved to `NotificationManager` config alongside the task (existing pattern)
- **New:** expose location as a first-class field in both create and edit — not buried under reminder type

### What Gets Deleted / Replaced

- `AddNodeView.swift` → deleted, replaced by `TaskSheet` in create mode
- `CardEditSheet.swift` → replaced by `TaskSheet` in edit mode
- All call sites updated to present `TaskSheet` with the appropriate mode

### What Stays the Same

- All save logic (`service.addNode()` / `service.updateNode()`) — just called from one place
- `NotificationManager` reminder + location logic — unchanged, just always visible
- Supabase schema — no changes needed

---

---

## Fix — Arrow Anchor Points (Bottom → Top, Not Top → Top)

### The Problem
Arrows connecting notes on the detective board currently anchor at the **top** of both the source and destination cards. This causes lines to cross over the cards themselves — the opposite of how a real corkboard works.

### What It Should Look Like
Like a real corkboard with a string pinned between notes:
- Line starts at the **bottom center** of the source card
- Line ends at the **top center** of the destination card
- No crossing over card faces — the string runs cleanly between them

### Where to Fix
In `DetectiveBoardView.swift`, inside the `Canvas` block that draws connection lines (~line 390+). The `from` and `to` points are currently calculated using the card's position (top-left corner) without any offset. 

The fix is to:
1. **Source point** → `CGPoint(x: cardCenter.x, y: cardTop.y + cardHeight)`  — bottom center of source card
2. **Destination point** → `CGPoint(x: cardCenter.x, y: cardTop.y)` — top center of destination card

Card height and width are available from `CardSize` — use those to compute the offsets from the stored position.

---

## Build Order

### Phase 1 — Create `daily_schedule` table in Supabase
- Fields: date, slot, title, type, window_min, yes_label, no_label, start_time, end_time, emoji, status
- Seed with a sample Tuesday chain (wake → pray → breakfast → 4× pomodoro → evening)
- Claude Code can write rows via existing Python script pattern

### Phase 2 — Chain execution in the app
- `LiveActivityManager` reads `daily_schedule` for today
- Finds the first `status = pending` row → that's the current step
- Pushes it to live activity window 1 (full-screen, one confirm button)
- Pushes next 2 pending rows to window 2 preview

### Phase 3 — Chain step types
- **chain**: shows yes/no buttons, writing status back to Supabase on tap
- **pomodoro**: 50-min countdown animation in live activity bar, flips to 10-min break
- **time_block**: auto-advances when end_time passes (for evening events)

### Phase 4 — Claude as daily scheduler
- Saturday session: tell Claude the week → Claude writes all 7 days to `daily_schedule`
- Mid-day: "skip handball tonight" → Claude patches that row's status to skipped
- Phone updates on next 30s poll — no Xcode, no cable

### Phase 5 — WhatsApp bot (future)
- Reads sports signup chats, teaching schedule → auto-fills `daily_schedule`
- Same table, same app — just a new writer

---

## Notes

- No APNs / push tokens needed — polling every 30s is fast enough and simpler
- The General slot (rings/streak) needs zero changes — it already works
- Prayer times are fixed and should never need Claude to re-specify them — bake them into the baseline
- The WhatsApp bot idea (from MATAR.md) could eventually feed into this same `daily_schedule` table automatically — that's Phase 4 someday
