import SwiftUI

struct BoardView: View {
    @EnvironmentObject var service: FirebaseService
    @State private var selectedStatus: NodeStatus? = nil
    @State private var searchText = ""
    @State private var selectedNode: Node? = nil
    @State private var showAdd = false

    var filtered: [Node] {
        service.nodes
            .filter { selectedStatus == nil || $0.status == selectedStatus }
            .filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var groupedByCategory: [(NodeCategory, [Node])] {
        let order = NodeCategory.allCases.sorted { $0.sortOrder < $1.sortOrder }
        return order.compactMap { cat in
            let nodes = filtered.filter { $0.category == cat }.sorted { $0.status.sortOrder < $1.status.sortOrder }
            return nodes.isEmpty ? nil : (cat, nodes)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                if service.isLoading {
                    Spacer()
                    ProgressView("טוען...")
                    Spacer()
                } else if service.nodes.isEmpty {
                    emptyState
                } else {
                    boardList
                }
            }
            .navigationTitle("לוח חיים")
            .navigationBarTitleDisplayMode(.large)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    seedButton
                }
            }
            .sheet(item: $selectedNode) { node in
                NodeDetailView(node: node)
                    .environmentObject(service)
            }
            .sheet(isPresented: $showAdd) {
                AddNodeView()
                    .environmentObject(service)
            }
        }
    }

    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "הכל", isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }
                ForEach(NodeStatus.allCases, id: \.self) { status in
                    FilterChip(label: "\(status.dot) \(status.label)", isSelected: selectedStatus == status) {
                        selectedStatus = selectedStatus == status ? nil : status
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }

    var boardList: some View {
        List {
            ForEach(groupedByCategory, id: \.0) { category, nodes in
                Section(header:
                    Text(category.label)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .environment(\.layoutDirection, .rightToLeft)
                ) {
                    ForEach(nodes) { node in
                        NodeCard(node: node, allNodes: service.nodes)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedNode = node }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "חיפוש...")
        .environment(\.layoutDirection, .rightToLeft)
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("הלוח ריק")
                .font(.title2)
                .bold()
            Text("לחץ + להוסיף משימה\nאו טען את הנתונים הקיימים")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    var seedButton: some View {
        Button("טען נתונים") {
            SeedData.seed(into: service)
        }
        .font(.footnote)
        .opacity(service.nodes.isEmpty ? 1 : 0)
        .disabled(!service.nodes.isEmpty)
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
