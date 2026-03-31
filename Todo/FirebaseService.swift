import Foundation
import FirebaseFirestore
import Combine
import UserNotifications
import WidgetKit

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    @Published var nodes: [Node] = []
    @Published var isLoading = false
    @Published var error: String?

    nonisolated(unsafe) private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        // Only show loading spinner on first launch (no cached data yet)
        isLoading = nodes.isEmpty
        listener = db.collection("nodes")
            .addSnapshotListener(includeMetadataChanges: false) { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.error = error.localizedDescription
                    return
                }
                let rawNodes = snapshot?.documents.compactMap {
                    try? $0.data(as: Node.self)
                } ?? []
                
                // Auto-compute blocked status
                self.saveWidgetData(rawNodes)
                self.nodes = rawNodes.map { node in
                    var updatedNode = node
                    if node.status != .done {
                        let isBlocked = node.dependencies.contains { depId in
                            let depNode = rawNodes.first { $0.id == depId }
                            return depNode?.status != .done
                        }
                        updatedNode.status = isBlocked ? .blocked : (node.status == .blocked ? .open : node.status)
                    }
                    return updatedNode
                }
            }
    }

    func stopListening() {
        listener?.remove()
    }

    func updateStatus(_ node: Node, to status: NodeStatus) {
        guard let id = node.id else { return }
        var data: [String: Any] = ["status": status.rawValue]
        if status == .done {
            data["completedAt"] = Timestamp(date: Date())
        }
        db.collection("nodes").document(id).updateData(data)
    }

    func addNode(_ node: Node) {
        _ = try? db.collection("nodes").addDocument(from: node)
    }

    func deleteNode(_ node: Node) {
        guard let id = node.id else { return }
        db.collection("nodes").document(id).delete()
    }

    func node(byId id: String) -> Node? {
        nodes.first { $0.id == id }
    }

    func clearAllConnections() {
        db.collection("nodes").getDocuments { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let batch = self.db.batch()
            for doc in docs {
                batch.updateData(["dependencies": []], forDocument: doc.reference)
            }
            batch.commit()
        }
    }

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

    func updateNode(_ node: Node) {
        guard let id = node.id else { return }
        _ = try? db.collection("nodes").document(id).setData(from: node)
        scheduleNotification(for: node)
    }

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

    // MARK: - Board Positions

    @Published var positions: [String: CGPoint] = [:]
    private var positionsListener: ListenerRegistration?

    func startListeningPositions() {
        positionsListener = db.collection("nodePositions")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                var dict: [String: CGPoint] = [:]
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    if let x = data["x"] as? Double, let y = data["y"] as? Double {
                        dict[doc.documentID] = CGPoint(x: x, y: y)
                    }
                }
                self.positions = dict
            }
    }

    func stopListeningPositions() {
        positionsListener?.remove()
    }

    private func saveWidgetData(_ nodes: [Node]) {
        struct WidgetTask: Codable {
            let id, title, status, category: String
        }
        let tasks = nodes
            .filter { $0.status != .done }
            .sorted { $0.priority < $1.priority }
            .map { WidgetTask(id: $0.id ?? "", title: $0.title, status: $0.status.rawValue, category: $0.category.rawValue) }
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults(suiteName: "group.com.mataroll.Todo")?.set(data, forKey: "widgetTasks")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func wipeAndReseed() {
        // Encode seed data on MainActor before entering nonisolated callbacks
        let seedPairs: [(String, [String: Any])] = SeedData.getSeedNodes().compactMap { node in
            guard let id = node.id, let data = try? Firestore.Encoder().encode(node) else { return nil }
            return (id, data)
        }
        db.collection("nodes").getDocuments { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let batch = self.db.batch()
            for doc in docs { batch.deleteDocument(doc.reference) }
            batch.commit { _ in
                self.db.collection("nodePositions").getDocuments { snapshot2, _ in
                    let batch2 = self.db.batch()
                    snapshot2?.documents.forEach { batch2.deleteDocument($0.reference) }
                    batch2.commit { _ in
                        let batch3 = self.db.batch()
                        for (id, data) in seedPairs {
                            let ref = self.db.collection("nodes").document(id)
                            batch3.setData(data, forDocument: ref)
                        }
                        batch3.commit()
                    }
                }
            }
        }
    }

    func savePosition(nodeId: String, position: CGPoint) {
        db.collection("nodePositions").document(nodeId).setData([
            "x": position.x,
            "y": position.y
        ])
    }

    // Call once after computing default positions — persists any node that has no saved position yet
    func initializePositions(_ defaults: [String: CGPoint]) {
        for (nodeId, point) in defaults where positions[nodeId] == nil {
            savePosition(nodeId: nodeId, position: point)
        }
    }
}
