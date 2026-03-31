import SwiftUI

struct NodeCard: View {
    let node: Node
    let allNodes: [Node]

    var blockingNames: [String] {
        node.dependencies.compactMap { depId in
            allNodes.first { $0.id == depId }?.title
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .trailing, spacing: 4) {
                Text(node.title)
                    .font(.body)
                    .foregroundColor(node.status == .done ? .secondary : .primary)
                    .strikethrough(node.status == .done)

                if !blockingNames.isEmpty && node.status != .done {
                    Text("חסום על ידי: " + blockingNames.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Image(systemName: "chevron.left")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 4)
    }

    var statusColor: Color {
        switch node.status {
        case .blocked:    return .gray
        case .open:       return .yellow
        case .inProgress: return .green
        case .done:       return .blue
        }
    }
}
