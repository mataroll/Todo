import ActivityKit
import SwiftUI

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var activity: Activity<RingsActivityAttributes>?

    func update(rings: [RingData], nodes: [Node]) {
        let timeline = nodes
            .filter { $0.startTime != nil && $0.endTime != nil }
            .sorted { $0.startTime! < $1.startTime! }
            .prefix(3)
            .enumerated()
            .map { i, node in
                TimelineTask(
                    title: node.title,
                    startTime: formatTime(node.startTime!),
                    endTime: formatTime(node.endTime!),
                    status: i == 0 ? "now" : (i == 1 ? "next" : "dim")
                )
            }
        
        let dailyHabits = Array(nodes.filter { $0.coachType == .daily }.prefix(3))
        let habitSymbols = dailyHabits.map { _ in "🏃" }  // can refine per task later
        let confirmedHabits = dailyHabits.map { $0.status == .done || $0.isConfirmed }
        let habitIds = dailyHabits.compactMap { $0.id }

        let state = RingsActivityAttributes.ContentState(
            rings: rings.map { RingState(id: $0.id, progress: $0.progress,
                                         colorHex: hexString($0.color), label: $0.label) },
            streakCount: 12,
            timeline: Array(timeline),
            codenames: "TWD · CITRON · HF",
            habitSymbols: habitSymbols,
            confirmedHabits: Array(confirmedHabits).pad(toSize: 3, with: false),
            habitIds: habitIds.pad(toSize: 3, with: ""),
            updatedAt: Date()
        )
        
        let content = ActivityContent(state: state, staleDate: nil)
        
        if let activity {
            Task { await activity.update(content) }
        } else {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            activity = try? Activity.request(attributes: RingsActivityAttributes(), content: content)
        }
    }

    func end() {
        Task { await activity?.end(nil, dismissalPolicy: .immediate) }
        activity = nil
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func hexString(_ color: Color) -> String {
        let c = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        // Note: Live Activity hex string should not have # for some reason in many examples, 
        // but here the RingView uses it. I'll keep it consistent with what ExpandedRingsView expects.
        return String(format: "%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}

extension Array {
    func pad(toSize size: Int, with padding: Element) -> [Element] {
        var padded = self
        while padded.count < size {
            padded.append(padding)
        }
        return padded
    }
}
