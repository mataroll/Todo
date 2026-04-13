import Foundation
import Combine
import SwiftUI
import UserNotifications
import WidgetKit

// MARK: - Supabase Config
// PASTE YOUR PROJECT URL AND ANON KEY HERE (Settings → API in Supabase dashboard)
let supabaseURL = "https://zsrxynhmvomxocnvkcxa.supabase.co"
let supabaseKey = "sb_publishable_PxuPeLkqFbN1RnUy0TTkAw_AFz09yKa"

private let isoFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

private let isoEncoder: JSONEncoder = {
    let e = JSONEncoder()
    e.dateEncodingStrategy = .custom { date, encoder in
        var c = encoder.singleValueContainer()
        try c.encode(isoFormatter.string(from: date))
    }
    return e
}()

private let isoDecoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .custom { decoder in
        let c = try decoder.singleValueContainer()
        let s = try c.decode(String.self)
        if let date = isoFormatter.date(from: s) { return date }
        let alt = ISO8601DateFormatter()
        alt.formatOptions = [.withInternetDateTime]
        if let date = alt.date(from: s) { return date }
        return Date()
    }
    return d
}()

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    @Published var nodes: [Node] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var positions: [String: CGPoint] = [:]
    @Published var dailyLogs: [String: DailyLog] = [:]

    private var refreshTimer: Timer?

    private func request(path: String, method: String = "GET", body: Data? = nil, prefer: String? = nil) -> URLRequest? {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/\(path)") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let prefer { req.setValue(prefer, forHTTPHeaderField: "Prefer") }
        req.httpBody = body
        return req
    }

    // MARK: - Nodes

    func startListening() {
        isLoading = nodes.isEmpty
        Task { await fetchNodes() }
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { await self?.fetchNodes() }
        }
    }

    func stopListening() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func fetchNodes() async {
        guard let req = request(path: "nodes?select=*") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let rawNodes = try isoDecoder.decode([Node].self, from: data)
            isLoading = false
            saveWidgetData(rawNodes)
            nodes = rawNodes.map { node in
                var updated = node
                if node.status != .done {
                    let isBlocked = node.dependencies.contains { depId in
                        rawNodes.first { $0.id == depId }?.status != .done
                    }
                    updated.status = isBlocked ? .blocked : (node.status == .blocked ? .open : node.status)
                }
                return updated
            }.sorted { $0.priority < $1.priority }
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    func updateStatus(_ node: Node, to status: NodeStatus) {
        guard let id = node.id else { return }
        var body: [String: Any] = ["status": status.rawValue]
        if status == .done { body["completedAt"] = isoFormatter.string(from: Date()) }
        let data = try? JSONSerialization.data(withJSONObject: body)
        guard let req = request(path: "nodes?id=eq.\(id)", method: "PATCH", body: data) else { return }
        Task {
            _ = try? await URLSession.shared.data(for: req)
            await fetchNodes()
        }
    }

    func addNode(_ node: Node) {
        var n = node
        if n.id == nil { n.id = UUID().uuidString }
        guard let body = try? isoEncoder.encode(n),
              let req = request(path: "nodes", method: "POST", body: body) else { return }
        Task {
            _ = try? await URLSession.shared.data(for: req)
            await fetchNodes()
        }
    }

    func deleteNode(_ node: Node) {
        guard let id = node.id, let req = request(path: "nodes?id=eq.\(id)", method: "DELETE") else { return }
        Task {
            _ = try? await URLSession.shared.data(for: req)
            nodes.removeAll { $0.id == id }
        }
    }

    func updateNode(_ node: Node) {
        guard let id = node.id,
              let body = try? isoEncoder.encode(node),
              let req = request(path: "nodes?id=eq.\(id)", method: "PATCH", body: body) else { return }
        Task {
            _ = try? await URLSession.shared.data(for: req)
            scheduleNotification(for: node)
            await fetchNodes()
        }
    }

    func toggleConfirmation(_ node: Node) {
        guard let id = node.id else { return }
        let body = try? JSONSerialization.data(withJSONObject: ["isConfirmed": !node.isConfirmed])
        guard let req = request(path: "nodes?id=eq.\(id)", method: "PATCH", body: body) else { return }
        Task {
            _ = try? await URLSession.shared.data(for: req)
            await fetchNodes()
        }
    }

    func node(byId id: String) -> Node? {
        nodes.first { $0.id == id }
    }

    // MARK: - Connections

    func addConnection(from fromId: String, to toId: String, colorHex: String = "#CC1111") {
        guard var fromNode = nodes.first(where: { $0.id == fromId }) else { return }
        if !fromNode.connections.contains(where: { $0.toId == toId }) {
            fromNode.connections.append(Connection(toId: toId, colorHex: colorHex))
            updateNode(fromNode)
        }
    }

    func removeConnection(from fromId: String, to toId: String) {
        guard var fromNode = nodes.first(where: { $0.id == fromId }) else { return }
        fromNode.connections.removeAll { $0.toId == toId }
        updateNode(fromNode)
    }

    func updateConnectionColor(from fromId: String, to toId: String, colorHex: String) {
        guard var fromNode = nodes.first(where: { $0.id == fromId }) else { return }
        if let idx = fromNode.connections.firstIndex(where: { $0.toId == toId }) {
            fromNode.connections[idx].colorHex = colorHex
            updateNode(fromNode)
        }
    }

    func clearAllConnections() {
        for node in nodes where !node.connections.isEmpty {
            var updated = node
            updated.connections = []
            updateNode(updated)
        }
    }

    // MARK: - Board Positions

    private struct PositionRow: Codable {
        let id: String
        let x: Double
        let y: Double
    }

    func startListeningPositions() {
        Task { await fetchPositions() }
    }

    func stopListeningPositions() {}

    private func fetchPositions() async {
        guard let req = request(path: "node_positions?select=*") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let rows = try JSONDecoder().decode([PositionRow].self, from: data)
            var dict: [String: CGPoint] = [:]
            for row in rows {
                dict[row.id] = CGPoint(x: row.x, y: row.y)
            }
            positions = dict
        } catch {}
    }

    func savePosition(nodeId: String, position: CGPoint) {
        positions[nodeId] = position
        let row = PositionRow(id: nodeId, x: Double(position.x), y: Double(position.y))
        guard let body = try? JSONEncoder().encode(row),
              let req = request(path: "node_positions",
                                method: "POST",
                                body: body,
                                prefer: "resolution=merge-duplicates") else { return }
        Task { _ = try? await URLSession.shared.data(for: req) }
    }

    func initializePositions(_ defaults: [String: CGPoint]) {
        for (nodeId, point) in defaults where positions[nodeId] == nil {
            savePosition(nodeId: nodeId, position: point)
        }
    }

    // MARK: - Notifications

    func scheduleNotification(for node: Node) {
        guard let id = node.id else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard let date = node.reminderDate, date > Date(), node.status != .done else { return }
        let content = UNMutableNotificationContent()
        content.title = node.title
        content.body = node.notes ?? "תזכורת למשימה"
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // MARK: - Widget Data

    private func saveWidgetData(_ nodes: [Node]) {
        struct SharedTask: Codable {
            let id, title, status, category, coachType: String
            let price: Double?
            let isConfirmed: Bool
        }
        let tasks = nodes
            .filter { $0.status != .done }
            .sorted { $0.priority < $1.priority }
            .map { SharedTask(id: $0.id ?? "", title: $0.title, status: $0.status.rawValue,
                              category: $0.category.rawValue, coachType: $0.coachType.rawValue,
                              price: $0.price, isConfirmed: $0.isConfirmed) }
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults(suiteName: "group.com.mataroll.Todo")?.set(data, forKey: "widgetTasks")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Wipe & Reseed

    func wipeAndReseed() {
        Task {
            // Delete all
            if let req = request(path: "nodes?id=neq.__never__", method: "DELETE") {
                _ = try? await URLSession.shared.data(for: req)
            }
            // Insert seed
            for var node in SeedData.getSeedNodes() {
                if node.id == nil { node.id = UUID().uuidString }
                if let body = try? isoEncoder.encode(node),
                   let req = request(path: "nodes", method: "POST", body: body) {
                    _ = try? await URLSession.shared.data(for: req)
                }
            }
            await fetchNodes()
        }
    }

    // MARK: - Daily Logs

    static func logKey(for date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private struct DailyLogRow: Codable {
        let id: String
        let date: String
        let overallProgress: Double
        let isPerfect: Bool
        let exerciseProgress: Double
        let workProgress: Double
        let studyProgress: Double
        let hobbyProgress: Double
    }

    func saveTodayLog(nodes: [Node]) {
        let daily = nodes.filter { $0.coachType == .daily }
        guard !daily.isEmpty else { return }

        func progress(for cat: HabitCategory) -> Double? {
            let catNodes = daily.filter { $0.habitCategory == cat }
            guard !catNodes.isEmpty else { return nil }
            let done = catNodes.filter { $0.isConfirmed || $0.status == .done }.count
            return Double(done) / Double(catNodes.count)
        }

        let ep = progress(for: .exercise)
        let wp = progress(for: .work)
        let sp = progress(for: .study)
        let hp = progress(for: .hobby)
        let active = [ep, wp, sp, hp].compactMap { $0 }
        let overall = active.isEmpty ? 0.0 : active.reduce(0, +) / Double(active.count)
        let isPerfect = !active.isEmpty && active.allSatisfy { $0 == 1.0 }

        let row = DailyLogRow(
            id: SupabaseService.logKey(),
            date: isoFormatter.string(from: Date()),
            overallProgress: overall,
            isPerfect: isPerfect,
            exerciseProgress: ep ?? 0,
            workProgress: wp ?? 0,
            studyProgress: sp ?? 0,
            hobbyProgress: hp ?? 0
        )

        guard let body = try? JSONEncoder().encode(row),
              let req = request(path: "daily_logs",
                                method: "POST",
                                body: body,
                                prefer: "resolution=merge-duplicates") else { return }
        Task { _ = try? await URLSession.shared.data(for: req) }
    }

    func fetchDailyLogs(months: Int = 2) {
        let start = Calendar.current.date(byAdding: .month, value: -months, to: Date())!
        let startStr = isoFormatter.string(from: start)
        guard let req = request(path: "daily_logs?date=gte.\(startStr)&select=*") else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: req)
                let rows = try JSONDecoder().decode([DailyLogRow].self, from: data)
                var dict: [String: DailyLog] = [:]
                for row in rows {
                    let logData: [String: Any] = [
                        "date": isoFormatter.date(from: row.date) ?? Date(),
                        "overallProgress": row.overallProgress,
                        "isPerfect": row.isPerfect,
                        "exerciseProgress": row.exerciseProgress,
                        "workProgress": row.workProgress,
                        "studyProgress": row.studyProgress,
                        "hobbyProgress": row.hobbyProgress
                    ]
                    if let log = DailyLog.from(id: row.id, data: logData) {
                        dict[row.id] = log
                    }
                }
                dailyLogs = dict
            } catch {}
        }
    }

    func currentStreak() -> Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())
        let cal = Calendar.current
        while true {
            let key = SupabaseService.logKey(for: date)
            guard let log = dailyLogs[key], log.isPerfect else { break }
            streak += 1
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
    }
}
