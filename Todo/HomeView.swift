import SwiftUI

// MARK: - Shared design primitives (accessible app-wide — no access modifier = internal)

struct GlassCard<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        content()
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

struct DarkStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.38))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }
}

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var service: SupabaseService

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.059, green: 0.090, blue: 0.161).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        topHeader
                        ringsCard
                        statsGrid
                        habitsCard
                        activeTasksCard
                        StreakCalendarView()
                            .environmentObject(service)
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
            }
            .navigationTitle("שלום, מטר")
            .toolbarBackground(Color(red: 0.059, green: 0.090, blue: 0.161), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    liveActivityButton
                }
            }
        }
    }

    // MARK: - Live activity toggle button

    var liveActivityButton: some View {
        Button {
            LiveActivityManager.shared.restart()
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 6, height: 6)
                Text("Live")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.cyan.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.cyan.opacity(0.25), lineWidth: 1))
        }
    }

    // MARK: - Top header

    var topHeader: some View {
        let dailyNodes = service.nodes.filter { $0.coachType == .daily }
        let dailyDone  = dailyNodes.filter { $0.status == .done || $0.isConfirmed }.count
        let pct = dailyNodes.isEmpty ? 0 : Int(Double(dailyDone) / Double(dailyNodes.count) * 100)
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0

        return HStack(alignment: .lastTextBaseline) {
            Text("יום \(dayOfYear) בשנה")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.32))
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(pct)")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(.blue)
                Text("%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue.opacity(0.55))
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Rings card

    var ringsCard: some View {
        GlassCard {
            HStack(spacing: 20) {
                ActivityRingsView(rings: computeRings(), size: 110, lineWidth: 11, spacing: 8)
                VStack(alignment: .leading, spacing: 11) {
                    ForEach(computeRings()) { ring in
                        HStack(spacing: 8) {
                            Circle().fill(ring.color).frame(width: 8, height: 8)
                            Text(ring.label)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.52))
                            Spacer()
                            Text("\(Int(ring.progress * 100))%")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(ring.color)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Stats grid

    var statsGrid: some View {
        let budgetUsed = service.nodes.filter { $0.coachType == .budget && $0.status == .done }.compactMap { $0.price }.reduce(0, +)
        let remaining  = max(0, 2000 - budgetUsed)
        let wDone  = service.nodes.filter { $0.coachType == .weekly && $0.status == .done }.count
        let wTotal = service.nodes.filter { $0.coachType == .weekly }.count
        let open   = service.nodes.filter { $0.status != .done }.count

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DarkStatCard(title: "יתרה לתקציב", value: "₪\(Int(remaining))", color: .yellow)
            DarkStatCard(title: "יעדי שבוע",   value: "\(wDone)/\(wTotal)",  color: .green)
            DarkStatCard(title: "רצף ימים",    value: "\(service.currentStreak()) 🔥", color: .orange)
            DarkStatCard(title: "פתוחות",      value: "\(open)",              color: .blue)
        }
    }

    // MARK: - Habits card

    @ViewBuilder
    var habitsCard: some View {
        let habits = Array(service.nodes.filter { $0.coachType == .daily }.prefix(5))
        if !habits.isEmpty {
            GlassCard {
                VStack(alignment: .trailing, spacing: 12) {
                    Text("ביצוע הרגלים")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.38))
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    HStack(spacing: 8) {
                        ForEach(habits) { habit in
                            Button { service.toggleConfirmation(habit) } label: {
                                VStack(spacing: 5) {
                                    Text(habit.habitCategory != .none
                                         ? habit.habitCategory.icon
                                         : String(habit.title.prefix(1)))
                                        .font(.system(size: 26))
                                        .opacity(habit.isConfirmed ? 1.0 : 0.28)

                                    Text(habit.title)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(habit.isConfirmed ? .white : .white.opacity(0.32))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    habit.isConfirmed
                                        ? habit.habitCategory.color.opacity(0.16)
                                        : Color.white.opacity(0.04)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            habit.isConfirmed
                                                ? habit.habitCategory.color.opacity(0.4)
                                                : Color.white.opacity(0.07),
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Active tasks card

    var activeTasksCard: some View {
        let active = Array(
            service.nodes
                .filter { $0.status == .inProgress || ($0.coachType == .weekly && $0.status != .done) }
                .prefix(5)
        )

        return GlassCard {
            VStack(alignment: .trailing, spacing: 0) {
                Text("משימות פעילות")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.38))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, 12)

                if active.isEmpty {
                    Text("אין משימות פעילות")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.22))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 0) {
                        ForEach(active.indices, id: \.self) { i in
                            let node = active[i]
                            HStack(spacing: 12) {
                                Button { service.updateStatus(node, to: .done) } label: {
                                    Image(systemName: "circle")
                                        .font(.system(size: 20, weight: .ultraLight))
                                        .foregroundColor(node.coachType.color)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(node.title)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                    if let start = node.startTime, let end = node.endTime {
                                        Text("\(formatTime(start))–\(formatTime(end))")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.32))
                                    }
                                }

                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(node.coachType.color)
                                    .frame(width: 3, height: 34)
                            }
                            .padding(.vertical, 10)

                            if i < active.count - 1 {
                                Divider().background(Color.white.opacity(0.07))
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Ring computation

    func computeRings() -> [RingData] { HomeView.buildRings(nodes: service.nodes) }

    static func buildRings(nodes: [Node]) -> [RingData] {
        let daily   = nodes.filter { $0.coachType == .daily }
        let dDone   = daily.filter { $0.status == .done || $0.isConfirmed }.count
        let dProg   = daily.isEmpty   ? 0.0 : Double(dDone)  / Double(daily.count)

        let weekly  = nodes.filter { $0.coachType == .weekly }
        let wDone   = weekly.filter { $0.status == .done }.count
        let wProg   = weekly.isEmpty  ? 0.0 : Double(wDone)  / Double(weekly.count)

        let spent   = nodes.filter { $0.coachType == .budget && $0.status == .done }.compactMap { $0.price }.reduce(0, +)
        let bProg   = min(1.0, spent / 2000.0)

        return [
            RingData(id: "daily",  progress: dProg, color: .blue,   label: "יומי"),
            RingData(id: "weekly", progress: wProg, color: .green,  label: "שבועי"),
            RingData(id: "budget", progress: bProg, color: .yellow, label: "תקציב"),
        ]
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: date)
    }
}
