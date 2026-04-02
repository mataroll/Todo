import WidgetKit
import SwiftUI

private let firestoreURL =
    "https://firestore.googleapis.com/v1/projects/life-center-985b5/databases/(default)/documents/nodes" +
    "?key=AIzaSyAmsRrT2DFGUmz4Y2U_64MUWnCtwvPZC-c&pageSize=200"

// MARK: - Models

struct WidgetTask: Codable, Identifiable {
    let id: String
    let title: String
    let status: String   // "inProgress", "open", "blocked", "done"
    let category: String
    let priority: Int
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    var inProgress: Int { tasks.filter { $0.status == "inProgress" }.count }
    var blocked: Int    { tasks.filter { $0.status == "blocked"    }.count }
    var open: Int       { tasks.filter { $0.status == "open"       }.count }
    var topTasks: [WidgetTask] { tasks.filter { $0.status != "done" }.prefix(5).map { $0 } }
}

// MARK: - Firestore REST helpers

private struct FirestoreResponse: Decodable {
    let documents: [FirestoreDocument]?
}

private struct FirestoreDocument: Decodable {
    let name: String
    let fields: [String: FirestoreField]
}

private struct FirestoreField: Decodable {
    let stringValue: String?
    let integerValue: String?   // Firestore sends ints as strings in REST
    let booleanValue: Bool?
}

private func parseWidgetTasks(from data: Data) -> [WidgetTask] {
    guard let response = try? JSONDecoder().decode(FirestoreResponse.self, from: data),
          let docs = response.documents else { return [] }

    return docs.compactMap { doc -> WidgetTask? in
        let parts = doc.name.split(separator: "/")
        guard let docId = parts.last.map(String.init),
              let title  = doc.fields["title"]?.stringValue,
              let status = doc.fields["status"]?.stringValue
        else { return nil }
        let category = doc.fields["category"]?.stringValue ?? ""
        let priority = Int(doc.fields["priority"]?.integerValue ?? "0") ?? 0
        return WidgetTask(id: docId, title: title, status: status, category: category, priority: priority)
    }
    .filter { $0.status != "done" }
    .sorted { $0.priority < $1.priority }
}

// MARK: - Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        Task {
            let tasks = await fetchFromFirestore()
            completion(TaskEntry(date: Date(), tasks: tasks))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        Task {
            let tasks = await fetchFromFirestore()
            let entry = TaskEntry(date: Date(), tasks: tasks)
            let next  = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func fetchFromFirestore() async -> [WidgetTask] {
        guard let url = URL(string: firestoreURL),
              let (data, _) = try? await URLSession.shared.data(from: url)
        else { return [] }
        return parseWidgetTasks(from: data)
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: TaskEntry

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("לוח בלש")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Color(red: 0.3, green: 0.2, blue: 0.1))
                .widgetAccentable()

            Spacer()

            HStack(spacing: 16) {
                statView(count: entry.inProgress, label: "פעיל", color: .green)
                statView(count: entry.blocked,    label: "חסום", color: .red)
                statView(count: entry.open,       label: "פתוח", color: .yellow)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            if let top = entry.topTasks.first {
                Text(top.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary.opacity(1.0))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(12)
        .environment(\.layoutDirection, .rightToLeft)
    }

    func statView(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
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
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.primary.opacity(1.0))
                    .widgetAccentable()
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
                            .foregroundStyle(.primary.opacity(1.0))
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
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
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
