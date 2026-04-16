import SwiftUI

enum ListTab: String, CaseIterable {
    case daily  = "יומי"
    case weekly = "שבועי"
    case yearly = "שנתי"
    case all    = "הכל"
}

struct BoardView: View {
    @EnvironmentObject var service: SupabaseService
    @State private var selectedTab: ListTab = .daily
    @State private var selectedNode: Node? = nil
    @State private var showAdd = false

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

    var currentDone: Int {
        switch selectedTab {
        case .daily:  return dailyNodes.filter  { $0.isConfirmed || $0.status == .done }.count
        case .weekly: return weeklyNodes.filter { $0.status == .done }.count
        case .yearly: return yearlyNodes.filter { $0.status == .done }.count
        case .all:    return 0
        }
    }

    var currentProgress: Double {
        guard currentNodes.count > 0 else { return 0 }
        return Double(currentDone) / Double(currentNodes.count)
    }

    var tabColor: Color {
        switch selectedTab {
        case .daily:  return .blue
        case .weekly: return .green
        case .yearly: return .orange
        case .all:    return .white
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.059, green: 0.090, blue: 0.161).ignoresSafeArea()
                VStack(spacing: 0) {
                    tabPicker
                    if selectedTab != .all { progressCard }
                    if service.isLoading {
                        Spacer()
                        ProgressView("טוען...").tint(.white)
                        Spacer()
                    } else if currentNodes.isEmpty {
                        emptyState
                    } else {
                        taskList
                    }
                }
            }
            .navigationTitle("רשימה")
            .navigationBarTitleDisplayMode(.large)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
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

    // MARK: - Tab picker (pill style)

    var tabPicker: some View {
        HStack(spacing: 6) {
            ForEach(ListTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.38))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab
                                ? (tab == .all ? Color.white.opacity(0.14) : tabColorFor(tab).opacity(0.22))
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    func tabColorFor(_ tab: ListTab) -> Color {
        switch tab {
        case .daily:  return .blue
        case .weekly: return .green
        case .yearly: return .orange
        case .all:    return .white
        }
    }

    // MARK: - Progress card

    var progressCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(Int(currentProgress * 100))%")
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(tabColor)
                Spacer()
                Text("\(currentDone) / \(currentNodes.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.38))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(tabColor.opacity(0.12))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(tabColor)
                        .frame(width: geo.size.width * currentProgress, height: 6)
                        .animation(.easeInOut, value: currentProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Task list

    var taskList: some View {
        List {
            ForEach(currentNodes.sorted { $0.status.sortOrder < $1.status.sortOrder }) { node in
                NodeCard(node: node, allNodes: service.nodes)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedNode = node }
                    .listRowBackground(Color.white.opacity(0.04))
                    .listRowSeparatorTint(Color.white.opacity(0.07))
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .swipeActions(edge: .leading) {
                        Button { service.updateStatus(node, to: .done) } label: {
                            Label("בוצע", systemImage: "checkmark.circle.fill")
                        }.tint(.green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { service.deleteNode(node) } label: {
                            Label("מחק", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Empty state

    var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.18))
            Text("אין משימות כאן")
                .font(.title3.bold())
                .foregroundColor(.white.opacity(0.45))
            Text("הוסף משימה עם התגית המתאימה")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.28))
            Spacer()
        }
    }

    var seedButton: some View {
        Button("טען נתונים") { SeedData.seed(into: service) }
            .font(.footnote)
            .opacity(service.nodes.isEmpty ? 1 : 0)
            .disabled(!service.nodes.isEmpty)
    }
}
