import WidgetKit
import SwiftUI

private let appGroup = "group.com.mataroll.Todo"

// Shared data model written by main app, read by widget
struct WidgetTask: Codable, Identifiable {
    let id: String
    let title: String
    let status: String   // "inProgress", "open", "blocked", "done"
    let category: String
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    var inProgress: Int { tasks.filter { $0.status == "inProgress" }.count }
    var blocked: Int    { tasks.filter { $0.status == "blocked"    }.count }
    var open: Int       { tasks.filter { $0.status == "open"       }.count }
    var topTasks: [WidgetTask] { tasks.filter { $0.status != "done" }.prefix(5).map { $0 } }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        completion(TaskEntry(date: Date(), tasks: loadFromAppGroup()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let entry = TaskEntry(date: Date(), tasks: loadFromAppGroup())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadFromAppGroup() -> [WidgetTask] {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: "widgetTasks"),
              let decoded = try? JSONDecoder().decode([WidgetTask].self, from: data)
        else { return [] }
        return decoded
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: TaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("לוח בלש")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 12) {
                statView(count: entry.inProgress, label: "פעיל", color: .green)
                statView(count: entry.blocked,    label: "חסום", color: .red)
                statView(count: entry.open,       label: "פתוח", color: .yellow)
            }

            Spacer()

            if let top = entry.topTasks.first {
                Text(top.title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(12)
        .environment(\.layoutDirection, .rightToLeft)
    }

    func statView(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: TaskEntry

    var statusDot: (String) -> String = { status in
        switch status {
        case "inProgress": return "🟢"
        case "blocked":    return "⚫"
        case "open":       return "🟡"
        default:           return "✅"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Stats column
            VStack(spacing: 8) {
                Text("לוח בלש")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Divider()
                statRow(count: entry.inProgress, label: "פעיל", color: .green)
                statRow(count: entry.blocked,    label: "חסום", color: .red)
                statRow(count: entry.open,       label: "פתוח", color: .orange)
                Spacer()
            }
            .frame(width: 60)
            .padding(.leading, 12)
            .padding(.top, 12)

            Divider().padding(.vertical, 8)

            // Task list
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(entry.topTasks) { task in
                    HStack {
                        Spacer()
                        Text(task.title)
                            .font(.system(size: 11))
                            .lineLimit(1)
                        Text(statusDot(task.status))
                            .font(.system(size: 10))
                    }
                }
                Spacer()
            }
            .padding(.trailing, 12)
            .padding(.top, 12)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    func statRow(count: Int, label: String, color: Color) -> some View {
        HStack {
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - Entry View

struct TodoWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: TaskEntry

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default:            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget

struct TodoWidget: Widget {
    let kind = "TodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoWidgetEntryView(entry: entry)
                .containerBackground(Color(red: 0.98, green: 0.96, blue: 0.90), for: .widget)
        }
        .configurationDisplayName("לוח בלש")
        .description("משימות פעילות מהלוח שלך")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
