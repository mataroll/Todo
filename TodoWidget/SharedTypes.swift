import ActivityKit
import SwiftUI

// Shared types needed by both the main app and widget extension.
// These must match the definitions in Todo/RingsActivityAttributes.swift exactly.

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
    let status: String // "now", "next", "dim"
}

struct RingsActivityAttributes: ActivityAttributes {
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
