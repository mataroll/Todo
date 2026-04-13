import SwiftUI

struct CardActionMenu: View {
    @EnvironmentObject var service: SupabaseService
    let node: Node
    let onDismiss: () -> Void

    @State private var showEdit = false
    @State private var showConnect = false

    var body: some View {
        ZStack {
            // Blur backdrop
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                // Card preview
                BoardNoteCard(node: node)
                    .scaleEffect(1.15)
                    .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)
                    .padding(.bottom, 32)

                // Action buttons
                VStack(spacing: 12) {
                    MenuButton(title: "עריכה", icon: "pencil.circle.fill", color: .blue) {
                        showEdit = true
                    }
                    MenuButton(title: "חיבור", icon: "arrow.triangle.branch", color: Color(red: 0.7, green: 0.15, blue: 0.15)) {
                        showConnect = true
                    }

                    // Quick size picker
                    HStack(spacing: 0) {
                        ForEach(CardSize.allCases, id: \.self) { size in
                            Button {
                                var updated = node
                                updated.cardSize = size
                                service.updateNode(updated)
                                onDismiss()
                            } label: {
                                Text(size.label)
                                    .font(.system(size: 17, weight: node.cardSize == size ? .bold : .regular))
                                    .foregroundColor(node.cardSize == size ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(node.cardSize == size ? Color.blue : Color.clear)
                            }
                        }
                    }
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Delete
                    MenuButton(title: "מחק משימה", icon: "trash.fill", color: .red) {
                        service.deleteNode(node)
                        onDismiss()
                    }
                }
                .padding(.horizontal, 48)

                Button("ביטול") { onDismiss() }
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(.top, 24)
            }
        }
        .sheet(isPresented: $showEdit) {
            CardEditSheet(node: node)
                .environmentObject(service)
        }
        .sheet(isPresented: $showConnect) {
            ConnectionPickerView(node: node, onDismiss: { showConnect = false })
                .environmentObject(service)
        }
        .onChange(of: showEdit) { _, val in if !val { onDismiss() } }
        .onChange(of: showConnect) { _, val in if !val { onDismiss() } }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
