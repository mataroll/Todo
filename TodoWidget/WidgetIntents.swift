import AppIntents
import ActivityKit
import Foundation
import WidgetKit

// PASTE YOUR PROJECT URL AND ANON KEY HERE — same values as in FirebaseService.swift
private let supabaseURL = "https://zsrxynhmvomxocnvkcxa.supabase.co"
private let supabaseKey = "sb_publishable_PxuPeLkqFbN1RnUy0TTkAw_AFz09yKa"
private let appGroup = "group.com.mataroll.Todo"

let negativeHabits: [(key: String, icon: String, label: String)] = [
    ("coke",   "🥤", "קולה"),
    ("sugar",  "🍫", "סוכר"),
    ("screen", "📱", "מסך"),
]

private func patchNode(id: String, body: [String: Any]) async {
    guard let url = URL(string: "\(supabaseURL)/rest/v1/nodes?id=eq.\(id)") else { return }
    var req = URLRequest(url: url)
    req.httpMethod = "PATCH"
    req.setValue(supabaseKey, forHTTPHeaderField: "apikey")
    req.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)
    _ = try? await URLSession.shared.data(for: req)
}

// MARK: - Toggle habit confirmed (for Live Activity habit icons)

struct ConfirmHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "סמן הרגל"

    @Parameter(title: "Task ID")
    var taskId: String

    @Parameter(title: "Current Value")
    var currentValue: Bool

    init() { taskId = ""; currentValue = false }
    init(taskId: String, currentValue: Bool) {
        self.taskId = taskId
        self.currentValue = currentValue
    }

    func perform() async throws -> some IntentResult {
        guard !taskId.isEmpty else { return .result() }
        await patchNode(id: taskId, body: ["isConfirmed": !currentValue])

        // Immediately flip the confirmed state in the live activity so UI updates without opening app
        for activity in Activity<RingsActivityAttributes>.activities {
            var state = activity.content.state
            if let idx = state.habitIds.firstIndex(of: taskId), idx < state.confirmedHabits.count {
                state.confirmedHabits[idx] = !currentValue
                state.updatedAt = Date()
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Record a negative habit slip (local UserDefaults — no network)

struct RecordSlipIntent: AppIntent {
    static var title: LocalizedStringResource = "סמן חריגה"

    @Parameter(title: "Habit Key") var habitKey: String
    @Parameter(title: "Habit Label") var habitLabel: String

    init() { habitKey = ""; habitLabel = "" }
    init(habitKey: String, habitLabel: String) {
        self.habitKey = habitKey
        self.habitLabel = habitLabel
    }

    func perform() async throws -> some IntentResult {
        guard !habitKey.isEmpty else { return .result() }
        let dateKey = {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()
        let defaults = UserDefaults(suiteName: appGroup)
        let key = "slips_\(dateKey)"
        var counts = defaults?.dictionary(forKey: key) as? [String: Int] ?? [:]
        counts[habitKey, default: 0] += 1
        defaults?.set(counts, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Mark task done (for Weekly widget task list)

struct MarkTaskDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "סמן כבוצע"

    @Parameter(title: "Task ID")
    var taskId: String

    init() { taskId = "" }
    init(taskId: String) { self.taskId = taskId }

    func perform() async throws -> some IntentResult {
        guard !taskId.isEmpty else { return .result() }
        let iso = ISO8601DateFormatter().string(from: Date())
        await patchNode(id: taskId, body: ["status": "done", "completedAt": iso])
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
