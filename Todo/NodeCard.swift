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
        HStack(alignment: .center, spacing: 0) {
            // Colored status bar on the right (RTL: this is the leading edge visually)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(statusColor)
                .frame(width: 3, height: 36)
                .padding(.trailing, 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text(node.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(node.status == .done ? .white.opacity(0.28) : .white.opacity(0.85))
                    .strikethrough(node.status == .done, color: .white.opacity(0.28))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if !blockingNames.isEmpty && node.status != .done {
                    Text("חסום: " + blockingNames.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.orange.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            Spacer()

            // CoachType dot indicator
            if node.coachType != .none {
                Circle()
                    .fill(node.coachType.color.opacity(0.22))
                    .overlay(Circle().stroke(node.coachType.color.opacity(0.38), lineWidth: 1))
                    .frame(width: 8, height: 8)
                    .padding(.leading, 10)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }

    var statusColor: Color {
        switch node.status {
        case .blocked:    return .gray.opacity(0.45)
        case .open:       return .yellow
        case .inProgress: return .green
        case .done:       return .blue.opacity(0.35)
        }
    }
}
