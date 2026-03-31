import ActivityKit
import SwiftUI

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var activity: Activity<RingsActivityAttributes>?

    func start(rings: [RingData]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = RingsActivityAttributes.ContentState(
            rings: rings.map { RingState(id: $0.id, progress: $0.progress,
                                         colorHex: hexString($0.color), label: $0.label) },
            updatedAt: Date()
        )
        let content = ActivityContent(state: state, staleDate: nil)
        activity = try? Activity.request(attributes: RingsActivityAttributes(), content: content)
    }

    func update(rings: [RingData]) {
        guard let activity else { start(rings: rings); return }
        let state = RingsActivityAttributes.ContentState(
            rings: rings.map { RingState(id: $0.id, progress: $0.progress,
                                         colorHex: hexString($0.color), label: $0.label) },
            updatedAt: Date()
        )
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    func end(rings: [RingData]) {
        let state = RingsActivityAttributes.ContentState(
            rings: rings.map { RingState(id: $0.id, progress: $0.progress,
                                         colorHex: hexString($0.color), label: $0.label) },
            updatedAt: Date()
        )
        Task { await activity?.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .default) }
    }

    private func hexString(_ color: Color) -> String {
        let c = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}
