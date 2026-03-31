import ActivityKit
import SwiftUI

// MARK: - Shared ring state (codable for ActivityKit)

struct RingState: Codable, Hashable {
    let id: String
    let progress: Double   // 0.0 – 1.0
    let colorHex: String
    let label: String
}

// MARK: - Activity attributes

struct RingsActivityAttributes: ActivityAttributes {
    // Static — doesn't change while activity is live
    struct ContentState: Codable, Hashable {
        var rings: [RingState]
        var updatedAt: Date
    }
    // (no static fields needed for now)
}
