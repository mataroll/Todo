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
                    StreakCalendarView()
                        .environmentObject(service)
                    habitsSection
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
            HStack {
                Spacer()
                Text("₪")
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.blue)
            }
            
            Text("היום ה- \(Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0) בשנה")
                .font(.headline)
                .foregroundColor(.secondary)

            let dailyCount = service.nodes.filter { $0.coachType == .daily }.count
            let dailyDone = service.nodes.filter { $0.coachType == .daily && ($0.status == .done || $0.isConfirmed) }.count
            let percentage = dailyCount > 0 ? Int((Double(dailyDone) / Double(dailyCount)) * 100) : 0

            Text("\(percentage)% מהיעדים היומיים הושלמו")
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            let budgetUsed = service.nodes.filter { $0.coachType == .budget }.compactMap { $0.price }.reduce(0, +)
            let remainingBudget = max(0, 2000 - budgetUsed)
            
            StatCard(title: "יתרה לתקציב", value: "₪\(Int(remainingBudget))", icon: "creditcard.fill", color: .yellow)
            StatCard(title: "יעדי שבוע", value: "\(service.nodes.filter { $0.coachType == .weekly && $0.status == .done }.count)/\(service.nodes.filter { $0.coachType == .weekly }.count)", icon: "calendar", color: .green)
            StatCard(title: "רצף ימים", value: "12", icon: "flame.fill", color: .orange)
            StatCard(title: "משימות פתוחות", value: "\(service.nodes.filter { $0.status != .done }.count)", icon: "list.bullet", color: .blue)
        }
    }

    func computeRings() -> [RingData] {
        HomeView.buildRings(nodes: service.nodes)
    }

    static func buildRings(nodes: [Node]) -> [RingData] {
        // Daily Progress (Blue)
        let dailyNodes = nodes.filter { $0.coachType == .daily }
        let dailyDone = dailyNodes.filter { $0.status == .done || $0.isConfirmed }.count
        let dailyProgress = dailyNodes.isEmpty ? 0 : Double(dailyDone) / Double(dailyNodes.count)
        
        // Weekly Progress (Green)
        let weeklyNodes = nodes.filter { $0.coachType == .weekly }
        let weeklyDone = weeklyNodes.filter { $0.status == .done }.count
        let weeklyProgress = weeklyNodes.isEmpty ? 0 : Double(weeklyDone) / Double(weeklyNodes.count)
        
        // Budget Progress (Gold/Yellow) - Progress toward ₪2000 limit
        let budgetUsed = nodes.filter { $0.coachType == .budget }.compactMap { $0.price }.reduce(0, +)
        let budgetProgress = min(1.0, budgetUsed / 2000.0)

        return [
            RingData(id: "daily",  progress: dailyProgress,  color: .blue,   label: "יומי"),
            RingData(id: "weekly", progress: weeklyProgress, color: .green,  label: "שבועי"),
            RingData(id: "budget", progress: budgetProgress, color: .yellow, label: "תקציב"),
        ]
    }

    var habitsSection: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text("ביצוע הרגלים")
                .font(.headline)

            HStack(spacing: 20) {
                let habits = service.nodes.filter { $0.coachType == .daily }.prefix(3)
                ForEach(habits) { habit in
                    Button {
                        service.toggleConfirmation(habit)
                    } label: {
                        VStack(spacing: 8) {
                            Text(habit.title.prefix(1)) // Using first char as emoji placeholder if not set
                                .font(.system(size: 30))
                                .grayscale(habit.isConfirmed ? 0 : 1)
                                .opacity(habit.isConfirmed ? 1.0 : 0.3)
                            
                            Text(habit.title)
                                .font(.caption2)
                                .foregroundColor(habit.isConfirmed ? .primary : .secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(habit.isConfirmed ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(habit.isConfirmed ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    var activeNodesSection: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text("משימות פעילות")
                .font(.headline)

            let activeNodes = service.nodes.filter { $0.status == .inProgress || ($0.coachType == .weekly && $0.status != .done) }.prefix(5)
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
                        Button {
                            service.updateStatus(node, to: .done)
                        } label: {
                            Image(systemName: node.status == .done ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(node.title)
                                .font(.body)
                                .strikethrough(node.status == .done)
                            
                            if let start = node.startTime, let end = node.endTime {
                                Text("\(formatTime(start))–\(formatTime(end))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Circle().fill(node.coachType.color).frame(width: 8, height: 8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
