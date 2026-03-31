import SwiftUI

struct HomeView: View {
    @EnvironmentObject var service: FirebaseService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ActivityRingsRow(rings: computeRings())
                    summaryHeader
                    statsGrid
                    activeNodesSection
                }
                .padding()
            }
            .navigationTitle("שלום, מטר")
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    var summaryHeader: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("היום ה- \(Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0) בשנה")
                .font(.headline)
                .foregroundColor(.secondary)

            let completed = service.nodes.filter { $0.status == .done }.count
            let total = service.nodes.count
            let percentage = total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0

            Text("\(percentage)% מהמשימות הושלמו")
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(title: "בתהליך", value: "\(service.nodes.filter { $0.status == .inProgress }.count)", icon: "play.circle.fill", color: .green)
            StatCard(title: "פתוחים", value: "\(service.nodes.filter { $0.status == .open }.count)", icon: "circle.fill", color: .yellow)
            StatCard(title: "חסומים", value: "\(service.nodes.filter { $0.status == .blocked }.count)", icon: "lock.fill", color: .gray)
            StatCard(title: "הושלמו", value: "\(service.nodes.filter { $0.status == .done }.count)", icon: "checkmark.circle.fill", color: .blue)
        }
    }

    func computeRings() -> [RingData] {
        HomeView.buildRings(nodes: service.nodes)
    }

    static func buildRings(nodes: [Node]) -> [RingData] {
        let total   = nodes.count
        let done    = nodes.filter { $0.status == .done }.count
        let active  = nodes.filter { $0.status == .inProgress }.count
        let blocked = nodes.filter { $0.status == .blocked }.count

        return [
            RingData(id: "done",    progress: total > 0 ? Double(done)    / Double(total) : 0, color: .green, label: "הושלם"),
            RingData(id: "active",  progress: total > 0 ? Double(active)  / Double(total) : 0, color: .blue,  label: "פעיל"),
            RingData(id: "blocked", progress: total > 0 ? Double(blocked) / Double(total) : 0, color: .red,   label: "חסום"),
        ]
    }

    var activeNodesSection: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text("משימות פעילות")
                .font(.headline)

            let activeNodes = service.nodes.filter { $0.status == .inProgress }.prefix(5)
            if activeNodes.isEmpty {
                Text("אין משימות בתהליך")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                ForEach(activeNodes) { node in
                    HStack {
                        Spacer()
                        Text(node.title)
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
