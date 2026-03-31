import SwiftUI

struct ConnectionPickerView: View {
    @EnvironmentObject var service: FirebaseService
    let node: Node
    let onDismiss: () -> Void

    @State private var search = ""
    @State private var direction: Direction = .fromThis
    @State private var lineColor: Color = .red

    enum Direction { case fromThis, toThis }

    var filtered: [Node] {
        let others = service.nodes.filter { $0.id != node.id }
        if search.isEmpty { return others }
        return others.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Picker("כיוון", selection: $direction) {
                        Text("מ: \(node.title) →").tag(Direction.fromThis)
                        Text("← \(node.title) :אל").tag(Direction.toThis)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    HStack {
                        Text("צבע חוט")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        ColorPicker("", selection: $lineColor, supportsOpacity: false)
                            .labelsHidden()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))

                List(filtered) { other in
                    Button {
                        connect(to: other)
                    } label: {
                        HStack {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(other.title)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.trailing)
                                Text(other.category.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(other.status.dot)
                        }
                    }
                }
                .searchable(text: $search, prompt: "חיפוש משימה...")
            }
            .navigationTitle("חיבור חדש")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") { onDismiss() }
                }
            }
        }
    }

    func connect(to other: Node) {
        guard let thisId = node.id, let otherId = other.id else { return }
        let hex = lineColor.hexString
        switch direction {
        case .fromThis: service.addConnection(from: thisId, to: otherId, colorHex: hex)
        case .toThis:   service.addConnection(from: otherId, to: thisId, colorHex: hex)
        }
        onDismiss()
    }
}
