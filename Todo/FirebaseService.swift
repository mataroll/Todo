import Foundation
import FirebaseFirestore
import Combine

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    @Published var nodes: [Node] = []
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        isLoading = true
        listener = db.collection("nodes")
            .addSnapshotListener { [weak self] snapshot, error in
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
        try? db.collection("nodes").addDocument(from: node)
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
        try? db.collection("nodes").document(id).setData(from: node)
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

    func wipeAndReseed() {
        db.collection("nodes").getDocuments { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let batch = self.db.batch()
            for doc in docs { batch.deleteDocument(doc.reference) }
            batch.commit { _ in
                self.db.collection("nodePositions").getDocuments { snapshot2, _ in
                    let batch2 = self.db.batch()
                    snapshot2?.documents.forEach { batch2.deleteDocument($0.reference) }
                    batch2.commit { _ in
                        let nodes = SeedData.getSeedNodes()
                        let batch3 = self.db.batch()
                        for node in nodes {
                            guard let id = node.id else { continue }
                            let ref = self.db.collection("nodes").document(id)
                            try? batch3.setData(from: node, forDocument: ref)
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
