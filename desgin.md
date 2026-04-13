This is a comprehensive "Source of Truth" document for your app. You can feed this into any AI (or keep it for your own development) to ensure the logic, design, and philosophy stay consistent.

---

# 📱 Project Brief: "Coach" — Personal Dashboards
**Philosophy:** A privacy-first, glanceable life-coach that tracks time, progress, and finances through a "Tap-to-Confirm" interaction model.

---

## 🎨 1. Visual Identity & Design System
* **Branding:** The Hebrew Shekel symbol (**₪**) in clean, bold, sans-serif.
* **Color Hierarchy:**
    * **Blue:** Daily Tasks/Habits (Progress toward 100%).
    * **Green:** Weekly Goals (Progress toward Saturday).
    * **Gold/Yellow:** Monthly Budget (Remaining capacity from ₪2,000).
    * **Cyan:** Current Active Task (High contrast).
* **The Pulse:** Three nested rings (Blue outer, Green middle, Gold inner).

---

## 🛠️ 2. Data Distribution Strategy (No Duplication)

### A. Lock Screen Widget (The "Pulse")
* **Size:** Rectangular (160x72 pt).
* **Content:**
    * Nested Rings (Blue/Green/Gold).
    * Status Legend: `[Blue %] [Green %] [Gold %]`.
    * **Privacy Finance:** The absolute sum of purchases > ₪200 displayed in white (e.g., `₪8,668`).
* **Goal:** Answer "How am I doing overall?" in 0.5 seconds.

### B. Live Activity (The "Execution Board")
* **Size:** Expanded Banner (160 pt height) + Dynamic Island.
* **Content:**
    * **Streak Indicator:** `🔥 X ימי רצף` (Streak count).
    * **Timeline:** 3-row list: **Now** (Cyan), **Next** (Muted), **Next-Next** (Dim). Must include time ranges (e.g., `19:00–21:00`).
    * **Codenames:** 3 priority tasks in code (e.g., `TWD · CITRON · HF`).
    * **Habit Icons:** Interactive symbols (🏃 🎹 📖) that highlight when confirmed.
* **Goal:** Answer "What am I doing now and next?"

### C. Home Screen Large Widget (The "Weekly Vision")
* **Size:** System Large (4x4).
* **Content:**
    * **Weekly Tasks:** A list of 4–5 major goals for the week until Saturday.
    * **Visual Progress:** Individual percentage numbers + horizontal progress bars for each goal.
    * **Countdown:** `עוד X ימים לשבת`.
    * **Financial Safety:** `₪ נותר: X,XXX` (Remaining budget).
* **Goal:** Answer "Am I on track for the weekend?"

---

## 🕹️ 3. Logic & Interaction (The "Coach" System)
1.  **Passive Tracking:** The app populates based on the Calendar and preset Budget.
2.  **Active Confirmation:** Nothing "auto-completes." The user must tap an event or icon to confirm it happened.
3.  **Real-Time Feedback:** Every tap expands the **Blue Daily Ring**.
4.  **Privacy Protection:** No bank balances on the lock screen; only spending relative to the ₪2,000 "Self-Set Goal" and the sum of large purchases.

---

## 💻 4. Technical Implementation Notes
* **Tech Stack:** SwiftUI, WidgetKit, ActivityKit (Live Activities).
* **Backend:** Firestore (already handling `WidgetTask` and `TaskEntry`).
* **Rings Logic:** Use a `ZStack` of `Circle()` shapes with `.trim(from: 0, to: progress)` and `stroke(style: StrokeStyle(lineCap: .round))`.
* **Time Management:** TimelineProvider must refresh every 30 minutes or upon manual "Tap-to-Confirm."

---

**Next Steps for Gemini:**
> "Gemini, use the provided HTML mockups and this brief to refactor the Swift code. Focus on splitting the `TaskEntry` data so the Lock Screen gets 'Daily' data and the Large Widget gets 'Weekly' data."




<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');
        body { font-family: 'Inter', sans-serif; background-color: #0f172a; color: white; }
        .ring { fill: none; stroke-width: 6; stroke-linecap: round; transform: rotate(-90deg); transform-origin: 50% 50%; }
        .ring-bg { fill: none; stroke-width: 6; opacity: 0.15; }
        .glass { background: rgba(255, 255, 255, 0.05); backdrop-filter: blur(10px); border: 1px solid rgba(255, 255, 255, 0.1); }
        .iphone-frame { width: 340px; border: 8px solid #1e293b; border-radius: 40px; padding: 20px; position: relative; }
        .island { background: black; border-radius: 20px; color: white; }
    </style>
</head>
<body class="flex flex-col md:flex-row items-center justify-center min-h-screen p-8 gap-12">

    <!-- 1. LOCK SCREEN & DYNAMIC ISLAND -->
    <div class="flex flex-col items-center gap-6">
        <h2 class="text-sm font-bold text-slate-400 uppercase tracking-widest">מבט מהיר (דינאמי + נעילה)</h2>
        <div class="iphone-frame bg-slate-900 h-[640px] shadow-2xl flex flex-col items-center">
            
            <!-- DYNAMIC ISLAND (Compact View) -->
            <div class="island w-[200px] h-[36px] mt-2 mb-4 flex items-center justify-between px-4">
                <div class="flex gap-1.5">
                    <div class="w-2 h-2 rounded-full bg-blue-500"></div>
                    <div class="w-2 h-2 rounded-full bg-green-500"></div>
                    <div class="w-2 h-2 rounded-full bg-yellow-500"></div>
                </div>
                <div class="text-[11px] font-bold text-blue-400">38%</div>
            </div>

            <div class="text-[12px] font-medium opacity-80 mb-1">יום רביעי • 2 באפריל</div>
            <div class="text-[64px] font-bold mb-4 leading-none">19:35</div>

            <!-- LOCK SCREEN WIDGET (Rings & Spending Pulse) -->
            <div class="w-[160px] h-[72px] rounded-[22px] glass p-3 flex items-center gap-3 mb-auto">
                <div class="w-10 h-10 shrink-0">
                    <svg viewBox="0 0 36 36">
                        <circle class="ring-bg stroke-blue-500" cx="18" cy="18" r="16" />
                        <circle class="ring stroke-blue-500" cx="18" cy="18" r="16" stroke-dasharray="38, 100" />
                        <circle class="ring-bg stroke-green-500" cx="18" cy="18" r="11" />
                        <circle class="ring stroke-green-500" cx="18" cy="18" r="11" stroke-dasharray="24, 100" />
                        <circle class="ring-bg stroke-yellow-500" cx="18" cy="18" r="6" />
                        <circle class="ring stroke-yellow-500" cx="18" cy="18" r="6" stroke-dasharray="44, 100" />
                    </svg>
                </div>
                <div class="flex flex-col justify-center">
                    <div class="text-[11px] font-black leading-none flex items-center gap-1">
                        <span class="text-blue-400">38</span> 
                        <span class="text-green-400">24</span> 
                        <span class="text-yellow-400">44</span> 
                        <span class="text-white ml-0.5">₪8,668</span>
                    </div>
                    <div class="text-[8px] text-white/30 mt-1 font-bold uppercase tracking-tighter">יומי • שבועי • יעד • הוצאות</div>
                </div>
            </div>

            <!-- LIVE ACTIVITY (Timeline with Times) -->
            <div class="w-full h-[160px] bg-[#1a1c24]/95 rounded-[30px] p-4 flex flex-col justify-between shadow-2xl border border-white/10">
                <div class="flex items-center justify-between">
                    <div class="text-[10px] font-bold bg-orange-500/10 text-orange-400 px-2 py-0.5 rounded-full border border-orange-500/20">🔥 12 ימי רצף</div>
                    <div class="text-[10px] text-slate-400 font-bold tracking-tight">TWD · CITRON · HF</div>
                </div>

                <!-- Timeline: Now, Next, Next-Next with Times -->
                <div class="space-y-1 py-1">
                    <div class="flex items-center gap-2 text-[11px] font-bold text-cyan-400">
                        <div class="w-2 h-2 rounded-full bg-cyan-400 shadow-[0_0_8px_rgba(34,211,238,0.6)]"></div>
                        <span>19:00–21:00: כתיבת קוד</span>
                    </div>
                    <div class="flex items-center gap-2 text-[10px] font-medium text-slate-300 opacity-70">
                        <div class="w-2 h-2 rounded-full border border-slate-500"></div>
                        <span>21:00–22:00: אימון ריצה</span>
                    </div>
                    <div class="flex items-center gap-2 text-[9px] font-medium text-slate-600 opacity-50">
                        <div class="w-1.5 h-1.5 rounded-full border border-slate-800"></div>
                        <span>22:00–23:00: קריאת ספר</span>
                    </div>
                </div>

                <div class="flex justify-between items-center border-t border-white/5 pt-2">
                    <div class="flex gap-4 text-[18px]">
                        <span>🏃</span> <span class="opacity-20 grayscale">🎹</span> <span class="opacity-20 grayscale">📖</span>
                    </div>
                    <div class="text-[9px] font-bold text-slate-500 uppercase tracking-widest">ביצוע הרגלים</div>
                </div>
            </div>
            <div class="w-24 h-1 bg-white/20 rounded-full mt-6"></div>
        </div>
    </div>

    <!-- 2. HOME SCREEN (WEEKLY VISION) -->
    <div class="flex flex-col items-center gap-6">
        <h2 class="text-sm font-bold text-slate-400 uppercase tracking-widest">משימות השבוע (בית)</h2>
        <div class="iphone-frame bg-[#fefce8] h-[640px] shadow-2xl text-slate-900">
            <!-- App Grid -->
            <div class="grid grid-cols-4 gap-4 mb-6">
                <div class="w-12 h-12 bg-blue-500 rounded-[12px] shadow-sm flex items-center justify-center text-white text-xl">₪</div>
                <div class="w-12 h-12 bg-white rounded-[12px] shadow-sm border border-slate-200"></div>
                <div class="w-12 h-12 bg-white rounded-[12px] shadow-sm border border-slate-200"></div>
                <div class="w-12 h-12 bg-white rounded-[12px] shadow-sm border border-slate-200"></div>
            </div>

            <!-- WEEKLY LIST WIDGET -->
            <div class="w-full aspect-square bg-white rounded-[32px] p-6 shadow-lg flex flex-col border border-slate-100">
                <div class="flex justify-between items-center mb-4">
                    <h3 class="text-sm font-black text-slate-800">משימות עד שבת</h3>
                    <div class="text-[10px] font-bold text-green-600 bg-green-50 px-2 py-0.5 rounded-full">שבוע 14</div>
                </div>

                <div class="flex-grow space-y-4">
                    <div class="space-y-1">
                        <div class="flex justify-between items-end">
                            <span class="text-[12px] font-bold">פרויקט גמר</span>
                            <span class="text-[10px] font-black text-blue-600">85%</span>
                        </div>
                        <div class="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                            <div class="h-full bg-blue-500 w-[85%]"></div>
                        </div>
                    </div>
                    <div class="space-y-1">
                        <div class="flex justify-between items-end">
                            <span class="text-[12px] font-bold">אימוני כוח (3/4)</span>
                            <span class="text-[10px] font-black text-green-600">75%</span>
                        </div>
                        <div class="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                            <div class="h-full bg-green-500 w-[75%]"></div>
                        </div>
                    </div>
                    <div class="space-y-1">
                        <div class="flex justify-between items-end">
                            <span class="text-[12px] font-bold">חשבונות בנק</span>
                            <span class="text-[10px] font-black text-amber-600">20%</span>
                        </div>
                        <div class="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                            <div class="h-full bg-amber-500 w-[20%]"></div>
                        </div>
                    </div>
                </div>

                <div class="mt-4 pt-4 border-t border-slate-50 flex justify-between items-center text-[10px]">
                    <div class="text-slate-400 italic">"עקביות היא המפתח"</div>
                    <div class="font-black text-slate-600">₪ נותר: 1,118</div>
                </div>
            </div>
            
            <div class="mt-auto mb-4 flex justify-around items-center glass bg-white/50 py-3 rounded-[24px]">
                <div class="w-6 h-6 rounded-full bg-blue-500"></div>
                <div class="text-xl opacity-40 font-bold">₪</div>
                <div class="w-6 h-6 rounded-full bg-slate-300 opacity-40"></div>
            </div>
        </div>
    </div>

</body>
</html>

---

## Current Live Activity Code (RingsLiveActivity.swift)

```swift
import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Compact ring for Dynamic Island

private struct CompactRingsView: View {
    let rings: [RingState]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(rings.prefix(3), id: \.id) { ring in
                ZStack {
                    Circle()
                        .stroke(color(ring.colorHex).opacity(0.25),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    Circle()
                        .trim(from: 0, to: ring.progress)
                        .stroke(color(ring.colorHex),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 18, height: 18)
            }
        }
    }

    func color(_ hex: String) -> Color {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&int), h.count == 6 else { return .green }
        return Color(red: Double((int >> 16) & 0xFF) / 255,
                     green: Double((int >> 8)  & 0xFF) / 255,
                     blue:  Double(int         & 0xFF) / 255)
    }
}

// MARK: - Expanded / Lock Screen View

private struct CoachLiveActivityView: View {
    let state: RingsActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 12) {
            // Top Row: Streak + Codenames
            HStack {
                Text("🔥 \(state.streakCount) ימי רצף")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.orange.opacity(0.2), lineWidth: 1))
                
                Spacer()
                
                Text(state.codenames)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1)
            }
            
            // Middle: Timeline
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(state.timeline, id: \.title) { task in
                    HStack(spacing: 8) {
                        Spacer()
                        Text("\(task.startTime)–\(task.endTime): \(task.title)")
                            .font(.system(size: task.status == "now" ? 11 : 10, weight: task.status == "now" ? .bold : .medium))
                            .foregroundColor(task.status == "now" ? .cyan : (task.status == "next" ? .white.opacity(0.7) : .white.opacity(0.4)))
                        
                        Circle()
                            .fill(task.status == "now" ? Color.cyan : (task.status == "next" ? Color.gray : Color.gray.opacity(0.3)))
                            .frame(width: 6, height: 6)
                            .shadow(color: task.status == "now" ? Color.cyan.opacity(0.6) : .clear, radius: 4)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Bottom: Habits + Pulse
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("הרגלים")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                        .kerning(1)
                    HStack(spacing: 12) {
                        ForEach(0..<state.habitSymbols.count, id: \.self) { i in
                            let id = i < state.habitIds.count ? state.habitIds[i] : ""
                            let confirmed = i < state.confirmedHabits.count ? state.confirmedHabits[i] : false
                            Button(intent: ConfirmHabitIntent(taskId: id, currentValue: confirmed)) {
                                Text(state.habitSymbols[i])
                                    .font(.system(size: 18))
                                    .opacity(confirmed ? 1.0 : 0.2)
                                    .grayscale(confirmed ? 0 : 1)
                            }
                            .buttonStyle(.plain)
                            .disabled(id.isEmpty)
                        }
                    }

                    // Negative habit quick-mark
                    Text("הימנע")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.red.opacity(0.7))
                        .kerning(1)
                    HStack(spacing: 10) {
                        ForEach(negativeHabits, id: \.key) { habit in
                            Button(intent: RecordSlipIntent(habitKey: habit.key, habitLabel: habit.label)) {
                                Text(habit.icon)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()
                
                // Pulse Rings (Small)
                ZStack {
                    ForEach(state.rings.indices, id: \.self) { i in
                        let d = CGFloat(34 - i * 10)
                        Circle()
                            .stroke(color(state.rings[i].colorHex).opacity(0.15), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: d, height: d)
                        Circle()
                            .trim(from: 0, to: state.rings[i].progress)
                            .stroke(color(state.rings[i].colorHex), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: d, height: d)
                            .rotationEffect(.degrees(-90))
                    }
                }
                .frame(width: 40, height: 40)
            }
            .padding(.top, 8)
            .border(width: 1, edges: [.top], color: Color.white.opacity(0.05))
        }
        .padding(16)
        .background(Color(red: 0.1, green: 0.11, blue: 0.14).opacity(0.95))
        .environment(\.layoutDirection, .rightToLeft)
    }

    func color(_ hex: String) -> Color {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&int), h.count == 6 else { return .green }
        return Color(red: Double((int >> 16) & 0xFF) / 255,
                     green: Double((int >> 8)  & 0xFF) / 255,
                     blue:  Double(int         & 0xFF) / 255)
    }
}

// MARK: - Widget

struct RingsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RingsActivityAttributes.self) { context in
            // Lock screen / notification banner view
            CoachLiveActivityView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    CompactRingsView(rings: context.state.rings)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("38%")  // BUG: hardcoded
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.blue)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    CoachLiveActivityView(state: context.state)
                }
            } compactLeading: {
                CompactRingsView(rings: Array(context.state.rings.prefix(3)))
            } compactTrailing: {
                // BUG: operator precedence — always shows 0%
                Text("\(Int(context.state.rings.first?.progress ?? 0 * 100))%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.blue)
            } minimal: {
                Circle()
                    .trim(from: 0, to: context.state.rings.first?.progress ?? 0)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}
```