import ActivityKit
import SwiftUI

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var tasksActivity: Activity<RingsActivityAttributes>?
    private var ringsActivity:  Activity<RingsActivityAttributes>?

    // Last known state — needed for restart()
    private var lastState: RingsActivityAttributes.ContentState?

    // MARK: - Update (called whenever nodes change)

    func update(rings: [RingData], nodes: [Node]) {
        let timeline: [TimelineTask] = nodes
            .filter { $0.startTime != nil && $0.endTime != nil }
            .map { node -> Node in
                // For daily habits: normalize stored time to TODAY so they always show on the current day
                guard node.coachType == .daily else { return node }
                var n = node
                n.startTime = normalizeToToday(node.startTime!)
                n.endTime   = normalizeToToday(node.endTime!)
                return n
            }
            .sorted { $0.startTime! < $1.startTime! }
            .prefix(6)
            .map { node in
                TimelineTask(
                    title:       node.title,
                    startTime:   formatTime(node.startTime!),
                    endTime:     formatTime(node.endTime!),
                    status:      "task",
                    taskId:      node.id ?? "",
                    isConfirmed: node.isConfirmed
                )
            }

        let dailyHabits = Array(nodes.filter { $0.coachType == .daily }.prefix(3))
        let habitSymbols = dailyHabits.map { node -> String in
            node.habitCategory != .none ? node.habitCategory.icon : String(node.title.prefix(1))
        }

        let state = RingsActivityAttributes.ContentState(
            rings: rings.map { RingState(id: $0.id, progress: $0.progress,
                                         colorHex: hexString($0.color), label: $0.label) },
            streakCount:     12,
            timeline:        timeline,
            codenames:       "",
            habitSymbols:    habitSymbols.pad(toSize: 3, with: "⭐️"),
            confirmedHabits: dailyHabits.map { $0.status == .done || $0.isConfirmed }.pad(toSize: 3, with: false),
            habitIds:        dailyHabits.compactMap { $0.id }.pad(toSize: 3, with: ""),
            updatedAt:       Date()
        )

        lastState = state
        applyState(state)
    }

    // MARK: - Restart (called from UI button or after dismissal detection)

    func restart() {
        end()
        if let state = lastState {
            applyState(state)
        }
    }

    // MARK: - End all

    func end() {
        Task {
            await tasksActivity?.end(nil, dismissalPolicy: .immediate)
            await ringsActivity?.end(nil, dismissalPolicy: .immediate)
        }
        tasksActivity = nil
        ringsActivity = nil
    }

    // MARK: - Private

    private func applyState(_ state: RingsActivityAttributes.ContentState) {
        let content = ActivityContent(state: state, staleDate: nil)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // Tasks activity — auto-restart if ended/dismissed
        if let a = tasksActivity, a.activityState == .active {
            Task { await a.update(content) }
        } else {
            tasksActivity = try? Activity.request(
                attributes: RingsActivityAttributes(mode: .tasks, taskOffset: 0),
                content: content
            )
        }

        // Rings activity — auto-restart if ended/dismissed
        if let a = ringsActivity, a.activityState == .active {
            Task { await a.update(content) }
        } else {
            ringsActivity = try? Activity.request(
                attributes: RingsActivityAttributes(mode: .rings, taskOffset: 0),
                content: content
            )
        }
    }

    private func normalizeToToday(_ date: Date) -> Date {
        let cal   = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: date)
        return cal.date(bySettingHour: comps.hour ?? 0, minute: comps.minute ?? 0,
                        second: 0, of: Date()) ?? date
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: date)
    }

    private func hexString(_ color: Color) -> String {
        let c = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}

extension Array {
    func pad(toSize size: Int, with padding: Element) -> [Element] {
        var padded = self
        while padded.count < size { padded.append(padding) }
        return padded
    }
}
