import SwiftUI

struct AddNodeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var service: FirebaseService

    @State private var title = ""
    @State private var category = NodeCategory.oneTime
    @State private var notes = ""
    @State private var link = ""
    @State private var selectedDependencies: Set<String> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("פרטי משימה") {
                    TextField("כותרת", text: $title)
                        .multilineTextAlignment(.trailing)
                    
                    Picker("קטגוריה", selection: $category) {
                        ForEach(NodeCategory.allCases, id: \.self) { cat in
                            Text(cat.label).tag(cat)
                        }
                    }
                }

                Section("מידע נוסף") {
                    TextField("הערות", text: $notes, axis: .vertical)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(3...10)
                    
                    TextField("קישור", text: $link)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("תלויות (חסום על ידי)") {
                    let otherNodes = service.nodes.sorted { $0.title < $1.title }
                    if otherNodes.isEmpty {
                        Text("אין משימות קיימות לתלויות")
                            .foregroundColor(.secondary)
                    } else {
                        List(otherNodes) { node in
                            Button {
                                if let id = node.id {
                                    if selectedDependencies.contains(id) {
                                        selectedDependencies.remove(id)
                                    } else {
                                        selectedDependencies.insert(id)
                                    }
                                }
                            } label: {
                                HStack {
                                    if let id = node.id, selectedDependencies.contains(id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(node.title)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .frame(minHeight: 200)
                    }
                }
            }
            .navigationTitle("משימה חדשה")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("שמור") {
                        save()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private func save() {
        let node = Node(
            title: title,
            category: category,
            status: selectedDependencies.isEmpty ? .open : .blocked,
            dependencies: Array(selectedDependencies),
            notes: notes.isEmpty ? nil : notes,
            link: link.isEmpty ? nil : link
        )
        service.addNode(node)
        dismiss()
    }
}
