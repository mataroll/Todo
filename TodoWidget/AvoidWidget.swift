import WidgetKit
import SwiftUI
import AppIntents

private let appGroup = "group.com.mataroll.Todo"

// MARK: - Entry

struct SlipEntry: TimelineEntry {
    let date: Date
    let counts: [String: Int]   // habitKey → count today

    func count(for key: String) -> Int { counts[key] ?? 0 }
    var totalSlips: Int { counts.values.reduce(0, +) }
}

// MARK: - Provider

struct SlipProvider: TimelineProvider {
    func placeholder(in context: Context) -> SlipEntry {
        SlipEntry(date: Date(), counts: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (SlipEntry) -> Void) {
        completion(SlipEntry(date: Date(), counts: readTodaySlips()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SlipEntry>) -> Void) {
        let entry = SlipEntry(date: Date(), counts: readTodaySlips())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readTodaySlips() -> [String: Int] {
        let dateKey = {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()
        return UserDefaults(suiteName: appGroup)?
            .dictionary(forKey: "slips_\(dateKey)") as? [String: Int] ?? [:]
    }
}

// MARK: - Lock Screen View (accessoryRectangular)

struct AvoidLockScreenView: View {
    let entry: SlipEntry

    var body: some View {
        HStack(spacing: 0) {
            ForEach(negativeHabits, id: \.key) { habit in
                Button(intent: RecordSlipIntent(habitKey: habit.key, habitLabel: habit.label)) {
                    VStack(spacing: 2) {
                        Text(habit.icon)
                            .font(.system(size: 16))
                        Text("\(entry.count(for: habit.key))")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(entry.count(for: habit.key) > 0 ? .red : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Widget

struct AvoidWidget: Widget {
    let kind = "AvoidWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SlipProvider()) { entry in
            AvoidLockScreenView(entry: entry)
                .containerBackground(.black.opacity(0.3), for: .widget)
        }
        .configurationDisplayName("הימנע")
        .description("סמן חריגות לאורך היום")
        .supportedFamilies([.accessoryRectangular])
    }
}
