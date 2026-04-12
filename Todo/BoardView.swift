import SwiftUI

enum ListTab: String, CaseIterable {
    case daily  = "יומי"
    case weekly = "שבועי"
    case yearly = "שנתי"
    case all    = "הכל"
}

struct BoardView: View {
    @EnvironmentObject var service: FirebaseService
    @State private var selectedTab: ListTab = .daily
    @State private var selectedNode: Node? = nil
    @State private var showAdd = false

    // MARK: - Filtered nodes

    var dailyNodes:  [Node] { service.nodes.filter { $0.coachType == .daily } }
    var weeklyNodes: [Node] { service.nodes.filter { $0.coachType == .weekly } }
    var yearlyNodes: [Node] { service.nodes.filter { $0.coachType == .yearly } }
    var allNodes:    [Node] { service.nodes.filter { $0.coachType != .budget } }

    var currentNodes: [Node] {
        switch selectedTab {
        case .daily:  return dailyNodes
        case .weekly: return weeklyNodes
        case .yearly: return yearlyNodes
        case .all:    return allNodes
        }
    }

    // MARK: - Progress

    var dailyDone:  Int { dailyNodes.filter  { $0.isConfirmed || $0.status == .done }.count }
    var weeklyDone: Int { weeklyNodes.filter { $0.status == .done }.count }
    var yearlyDone: Int { yearlyNodes.filter { $0.status == .done }.count }

    var currentDone:  Int { switch selectedTab { case .daily: return dailyDone; case .weekly: return weeklyDone; case .yearly: return yearlyDone; case .all: return 0 } }
    var currentTotal: Int { currentNodes.count }
    var currentProgress: Double {
        guard currentTotal > 0 else { return 0 }
        return Double(currentDone) / Double(currentTotal)
    }

    // MARK: - Color

    var tabColor: Color {
        switch selectedTab {
        case .daily:  return .blue
        case .weekly: return .green
        case .yearly: return .orange
        case .all:    return .primary
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabPicker
                if selectedTab != .all { progressSection }
                if service.isLoading {
                    Spacer(); ProgressView("טוען..."); Spacer()
                } else if currentNodes.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            .navigationTitle("רשימה")
            .navigationBarTitleDisplayMode(.large)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) { seedButton }
            }
            .sheet(item: $selectedNode) { node in
                NodeDetailView(node: node).environmentObject(service)
            }
            .sheet(isPresented: $showAdd) {
                AddNodeView().environmentObject(service)
            }
        }
    }

    // MARK: - Tab Picker

    var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(ListTab.allCases, id: \.self) { tab in
                Button { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } } label: {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: selectedTab == tab ? .bold : .regular))
                            .foregroundColor(selectedTab == tab ? (tab == .all ? .primary : tabColorFor(tab)) : .secondary)
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == tab ? (tab == .all ? .primary : tabColorFor(tab)) : .clear)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    func tabColorFor(_ tab: ListTab) -> Color {
        switch tab {
        case .daily:  return .blue
        case .weekly: return .green
        case .yearly: return .orange
        case .all:    return .primary
        }
    }

    // MARK: - Progress Section

    var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(currentDone) / \(currentTotal) משימות")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(currentProgress * 100))%")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(tabColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(tabColor.opacity(0.15))
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(tabColor)
                        .frame(width: geo.size.width * currentProgress, height: 7)
                        .animation(.easeInOut, value: currentProgress)
                }
            }
            .frame(height: 7)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Task List

    var taskList: some View {
        List {
            ForEach(currentNodes.sorted { $0.status.sortOrder < $1.status.sortOrder }) { node in
                NodeCard(node: node, allNodes: service.nodes)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedNode = node }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("אין משימות כאן")
                .font(.title3.bold())
            Text("הוסף משימה עם התגית המתאימה")
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Seed Button

    var seedButton: some View {
        Button("טען נתונים") { SeedData.seed(into: service) }
            .font(.footnote)
            .opacity(service.nodes.isEmpty ? 1 : 0)
            .disabled(!service.nodes.isEmpty)
    }
}
