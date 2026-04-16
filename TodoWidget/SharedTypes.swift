import ActivityKit
import SwiftUI

// Shared types needed by both the main app and widget extension.

struct RingState: Codable, Hashable {
    let id: String
    let progress: Double   // 0.0 – 1.0
    let colorHex: String
    let label: String
}

struct TimelineTask: Codable, Hashable {
    let title: String
    let startTime: String
    let endTime: String
    let status: String       // "now", "next", "dim"
    let taskId: String
    var isConfirmed: Bool
}

struct RingsActivityAttributes: ActivityAttributes {
    enum Mode: String, Codable { case tasks, rings }

    let mode: Mode
    let taskOffset: Int  // for tasks mode: first task index to show (0, 2, 4…)

    struct ContentState: Codable, Hashable {
        var rings: [RingState]
        var streakCount: Int
        var timeline: [TimelineTask]
        var codenames: String
        var habitSymbols: [String]
        var confirmedHabits: [Bool]
        var habitIds: [String]
        var updatedAt: Date
    }
}
