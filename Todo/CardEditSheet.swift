import SwiftUI

struct CardEditSheet: View {
    @EnvironmentObject var service: FirebaseService
    @Environment(\.dismiss) var dismiss

    let node: Node

    @State private var title: String
    @State private var status: NodeStatus
    @State private var size: CardSize
    @State private var link: String
    @State private var notes: String
    @State private var cardColor: Color

    init(node: Node) {
        self.node = node
        _title     = State(initialValue: node.title)
        _status    = State(initialValue: node.status)
        _size      = State(initialValue: node.cardSize)
        _link      = State(initialValue: node.link ?? "")
        _notes     = State(initialValue: node.notes ?? "")
        _cardColor = State(initialValue: Color(hex: node.customColor ?? "") ?? Color(red: 0.98, green: 0.96, blue: 0.82))
    }

    // Connections where this node is the source (this → other)
    var outgoing: [Connection] {
        node.connections
    }

    // Connections where this node is the target (other → this)
    var incoming: [(node: Node, conn: Connection)] {
        service.nodes.compactMap { other in
            guard other.id != node.id,
                  let conn = other.connections.first(where: { $0.toId == node.id })
            else { return nil }
            return (other, conn)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("שם") {
                    TextField("שם המשימה", text: $title)
                        .multilineTextAlignment(.trailing)
                }

                Section("סטטוס") {
                    Picker("סטטוס", selection: $status) {
                        ForEach(NodeStatus.allCases, id: \.self) { s in
                            Text("\(s.dot) \(s.label)").tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("גודל") {
                    Picker("גודל", selection: $size) {
                        ForEach(CardSize.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("צבע כרטיסייה") {
                    ColorPicker("בחר צבע", selection: $cardColor, supportsOpacity: false)
                }

                Section("לינק") {
                    TextField("https://...", text: $link)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .multilineTextAlignment(.trailing)
                }

                Section("הערות") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .multilineTextAlignment(.trailing)
                }

                if !outgoing.isEmpty {
                    Section("יוצא מכאן →") {
                        ForEach(outgoing, id: \.toId) { conn in
                            if let target = service.node(byId: conn.toId) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: conn.colorHex) ?? .red)
                                        .frame(width: 10, height: 10)
                                    Text(target.title)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.secondary)
                                }
                                .swipeActions {
                                    Button("מחק", role: .destructive) {
                                        service.removeConnection(from: node.id ?? "", to: conn.toId)
                                    }
                                }
                            }
                        }
                    }
                }

                if !incoming.isEmpty {
                    Section("נכנס לכאן ←") {
                        ForEach(incoming, id: \.node.id) { other, conn in
                            HStack {
                                Circle()
                                    .fill(Color(hex: conn.colorHex) ?? .red)
                                    .frame(width: 10, height: 10)
                                Text(other.title)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.left")
                                    .foregroundColor(.secondary)
                            }
                            .swipeActions {
                                Button("מחק", role: .destructive) {
                                    service.removeConnection(from: other.id ?? "", to: node.id ?? "")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("עריכה")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("שמור") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func save() {
        var updated = node
        updated.title      = title.trimmingCharacters(in: .whitespaces)
        updated.status     = status
        updated.cardSize   = size
        updated.link       = link.isEmpty ? nil : link
        updated.notes      = notes.isEmpty ? nil : notes
        updated.customColor = cardColor.hexString
        service.updateNode(updated)
        dismiss()
    }
}
