import SwiftUI

struct NodeDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var service: SupabaseService
    let node: Node

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .trailing, spacing: 12) {
                        HStack {
                            Spacer()
                            Text(node.status.label)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor.opacity(0.1))
                                .foregroundColor(statusColor)
                                .cornerRadius(8)
                        }
                        
                        Text(node.title)
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        if let notes = node.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("שינוי סטטוס") {
                    ForEach(NodeStatus.allCases, id: \.self) { status in
                        Button {
                            service.updateStatus(node, to: status)
                            dismiss()
                        } label: {
                            HStack {
                                if node.status == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                                Spacer()
                                Text(status.label)
                                    .foregroundColor(.primary)
                                Text(status.dot)
                            }
                        }
                    }
                }

                Section("קבצים ומסמכים") {
                    Button {
                        // TODO: Implement Photo Picker
                    } label: {
                        Label("הוסף תמונה", systemImage: "photo")
                    }
                    
                    Button {
                        // TODO: Implement PDF Picker
                    } label: {
                        Label("הוסף PDF", systemImage: "doc.fill")
                    }
                }

                if let link = node.link, !link.isEmpty {
                    Section("קישור") {
                        Link(destination: URL(string: link) ?? URL(string: "https://google.com")!) {
                            Label(link, systemImage: "link")
                                .lineLimit(1)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        service.deleteNode(node)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("מחק משימה")
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .navigationTitle("פרטי משימה")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("סגור") { dismiss() }
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
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
