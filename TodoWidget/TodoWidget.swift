import WidgetKit
import SwiftUI
import AppIntents

private let appGroup = "group.com.mataroll.Todo"

// MARK: - Models

struct WidgetTask: Codable, Identifiable {
    let id: String
    let title: String
    let status: String   // "done", "inProgress", "open", "blocked"
    let category: String
    let coachType: String // "daily", "weekly", "budget", "none"
    let price: Double?
    let isConfirmed: Bool
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]

    var dailyProgress: Double {
        let daily = tasks.filter { $0.coachType == "daily" }
        guard !daily.isEmpty else { return 0 }
        let done = daily.filter { $0.status == "done" || $0.isConfirmed }.count
        return Double(done) / Double(daily.count)
    }

    var weeklyProgress: Double {
        let weekly = tasks.filter { $0.coachType == "weekly" }
        guard !weekly.isEmpty else { return 0 }
        let done = weekly.filter { $0.status == "done" }.count
        return Double(done) / Double(weekly.count)
    }

    var totalSpending: Int {
        Int(tasks.filter { $0.coachType == "budget" && ($0.price ?? 0) > 200 }.compactMap { $0.price }.reduce(0, +))
    }

    var budgetUsed: Double {
        tasks.filter { $0.coachType == "budget" }.compactMap { $0.price }.reduce(0, +)
    }

    var budgetProgress: Double { min(1.0, budgetUsed / 2000.0) }

    var weeklyTasks: [WidgetTask] {
        tasks.filter { $0.coachType == "weekly" && $0.status != "done" }.prefix(5).map { $0 }
    }
}

// MARK: - Provider

private let fallbackTasks: [WidgetTask] = [
    WidgetTask(id: "run", title: "ריצה 90 יום", status: "inProgress", category: "keyBlockers", coachType: "daily", price: nil, isConfirmed: true),
    WidgetTask(id: "photos", title: "לנקות תמונות", status: "open", category: "recurring", coachType: "daily", price: nil, isConfirmed: false),
    WidgetTask(id: "piano", title: "פסנתר", status: "open", category: "recurring", coachType: "daily", price: nil, isConfirmed: false),
    WidgetTask(id: "dad", title: "דיבור עם אבא", status: "open", category: "keyBlockers", coachType: "weekly", price: nil, isConfirmed: false),
    WidgetTask(id: "haifa", title: "חיפה", status: "open", category: "keyBlockers", coachType: "weekly", price: nil, isConfirmed: false),
    WidgetTask(id: "citron", title: "ציטרון", status: "open", category: "keyBlockers", coachType: "weekly", price: nil, isConfirmed: false),
    WidgetTask(id: "pants", title: "מכנסיים ופוף", status: "open", category: "purchases", coachType: "budget", price: 250, isConfirmed: false),
    WidgetTask(id: "teeth", title: "הלבנת שיניים", status: "open", category: "purchases", coachType: "budget", price: 600, isConfirmed: false),
]

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: fallbackTasks)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        completion(TaskEntry(date: Date(), tasks: readFromShared()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let entry = TaskEntry(date: Date(), tasks: readFromShared())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readFromShared() -> [WidgetTask] {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = defaults.data(forKey: "widgetTasks"),
              let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data),
              !tasks.isEmpty
        else { return fallbackTasks }
        return tasks
    }
}

// MARK: - Views

struct PulseWidgetView: View {
    let entry: TaskEntry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RingView(progress: entry.dailyProgress, color: .blue, radius: 20)
                RingView(progress: entry.weeklyProgress, color: .green, radius: 14)
                RingView(progress: entry.budgetProgress, color: .yellow, radius: 8)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(Int(entry.dailyProgress * 100))")
                        .foregroundColor(.blue)
                    Text("\(Int(entry.weeklyProgress * 100))")
                        .foregroundColor(.green)
                    Text("\(Int(entry.budgetProgress * 100))")
                        .foregroundColor(.yellow)
                    Text("₪\(entry.totalSpending)")
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                }
                .font(.system(size: 12, weight: .black))

                Text("יומי • שבועי • יעד • הוצאות")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
            }
        }
        .padding(12)
        .background(Color(red: 0.1, green: 0.11, blue: 0.14))
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct RingView: View {
    let progress: Double
    let color: Color
    let radius: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: radius * 2, height: radius * 2)
    }
}

struct WeeklyVisionWidgetView: View {
    let entry: TaskEntry

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Text("שבוע \(Calendar.current.component(.weekOfYear, from: Date()))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                Spacer()
                Text("משימות עד שבת")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.black)
            }

            VStack(spacing: 12) {
                ForEach(entry.weeklyTasks) { task in
                    HStack {
                        Button(intent: MarkTaskDoneIntent(taskId: task.id)) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text(task.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            HStack {
                Text("₪ נותר: \(2000 - entry.totalSpending)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.gray)
                Spacer()
                Text("\"עקביות היא המפתח\"")
                    .font(.system(size: 10, weight: .medium))
                    .italic()
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.top, 8)
            .border(width: 1, edges: [.top], color: Color.black.opacity(0.05))
        }
        .padding(20)
        .background(Color.white)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - Lock Screen Widget (accessoryRectangular)

struct LockScreenPulseView: View {
    let entry: TaskEntry

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 2.5)
                    .frame(width: 28, height: 28)
                Circle()
                    .trim(from: 0, to: entry.dailyProgress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 2.5)
                    .frame(width: 20, height: 20)
                Circle()
                    .trim(from: 0, to: entry.weeklyProgress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .stroke(Color.yellow.opacity(0.2), lineWidth: 2.5)
                    .frame(width: 12, height: 12)
                Circle()
                    .trim(from: 0, to: entry.budgetProgress)
                    .stroke(Color.yellow, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 3) {
                    Text("\(Int(entry.dailyProgress * 100))")
                        .foregroundColor(.blue)
                    Text("\(Int(entry.weeklyProgress * 100))")
                        .foregroundColor(.green)
                    Text("\(Int(entry.budgetProgress * 100))")
                        .foregroundColor(.yellow)
                }
                .font(.system(size: 13, weight: .black))

                Text("₪\(entry.totalSpending)")
                    .font(.system(size: 11, weight: .bold))
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - Entry View

struct TodoWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: TaskEntry

    var body: some View {
        switch family {
        case .accessoryRectangular: LockScreenPulseView(entry: entry)
        case .systemSmall:  PulseWidgetView(entry: entry)
        case .systemLarge:  WeeklyVisionWidgetView(entry: entry)
        default:            PulseWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget

struct TodoWidget: Widget {
    let kind = "TodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoWidgetEntryView(entry: entry)
                .containerBackground(Color.white, for: .widget)
        }
        .configurationDisplayName("Coach")
        .description("המבט השבועי והיומי שלך")
        .supportedFamilies([.accessoryRectangular, .systemSmall, .systemLarge])
    }
}

// EdgeBorder and border(width:edges:color:) are defined in RingsLiveActivity.swift
