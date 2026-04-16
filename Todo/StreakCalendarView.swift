import SwiftUI

struct StreakCalendarView: View {
    @EnvironmentObject var service: SupabaseService
    @State private var displayMonth: Date = Date()
    @State private var selectedLog: DailyLog? = nil

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekLabels = ["א", "ב", "ג", "ד", "ה", "ו", "ש"]

    var streak: Int { service.currentStreak() }

    var body: some View {
        GlassCard {
            VStack(alignment: .trailing, spacing: 14) {

                // Streak badge
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Text("🔥")
                            .font(.title2)
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(streak)")
                                .font(.system(size: 26, weight: .black))
                                .foregroundColor(.orange)
                            Text("ימי רצף")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.38))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.orange.opacity(0.22), lineWidth: 1)
                    )
                }

                // Month navigation
                HStack {
                    Button { changeMonth(by: 1) } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white.opacity(0.38))
                    }
                    Spacer()
                    Text(monthTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                    Spacer()
                    Button { changeMonth(by: -1) } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.38))
                    }
                }

                // Week day labels
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(weekLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.28))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar days
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(calendarDays.indices, id: \.self) { i in
                        if let date = calendarDays[i] {
                            let key = SupabaseService.logKey(for: date)
                            let log = service.dailyLogs[key]
                            let isToday = cal.isDateInToday(date)
                            let isFuture = date > Date()
                            DayCell(log: log, isToday: isToday, isFuture: isFuture)
                                .onTapGesture {
                                    if !isFuture, let log { selectedLog = log }
                                }
                        } else {
                            Color.clear.frame(height: 32)
                        }
                    }
                }
            }
            .padding(16)
        }
        .sheet(item: $selectedLog) { log in DayDetailSheet(log: log) }
    }

    var monthTitle: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; f.locale = Locale(identifier: "he")
        return f.string(from: displayMonth)
    }

    var calendarDays: [Date?] {
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: displayMonth)),
              let range = cal.range(of: .day, in: .month, for: monthStart) else { return [] }
        let firstWeekday = (cal.component(.weekday, from: monthStart) - 1) % 7
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range { days.append(cal.date(byAdding: .day, value: day - 1, to: monthStart)) }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    func changeMonth(by value: Int) {
        if let m = cal.date(byAdding: .month, value: value, to: displayMonth) { displayMonth = m }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let log: DailyLog?
    let isToday: Bool
    let isFuture: Bool

    var body: some View {
        ZStack {
            Circle().fill(fillColor)
            if isToday {
                Circle().stroke(Color.white.opacity(0.55), lineWidth: 1.5)
            }
        }
        .frame(height: 32)
        .opacity(isFuture ? 0.15 : 1)
    }

    var fillColor: Color {
        guard let log, !isFuture else { return Color.white.opacity(0.07) }
        if log.isPerfect { return .green }
        if log.overallProgress > 0 { return Color.blue.opacity(0.2 + log.overallProgress * 0.6) }
        return Color.white.opacity(0.07)
    }
}

// MARK: - Day Detail Sheet

struct DayDetailSheet: View {
    let log: DailyLog
    @Environment(\.dismiss) var dismiss
    private let activeCategories: [HabitCategory] = [.exercise, .work, .study, .hobby]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if log.isPerfect {
                    Label("יום מושלם 🔥", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                }
                VStack(spacing: 14) {
                    ForEach(activeCategories, id: \.self) { cat in
                        let progress = log.progress(for: cat)
                        HStack(spacing: 12) {
                            Text(cat.icon).font(.title2).frame(width: 36)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(cat.label).font(.subheadline.bold())
                                    Spacer()
                                    Text("\(Int(progress * 100))%")
                                        .font(.subheadline.bold())
                                        .foregroundColor(progress == 1.0 ? .green : cat.color)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3).fill(cat.color.opacity(0.15)).frame(height: 5)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(progress == 1.0 ? Color.green : cat.color)
                                            .frame(width: geo.size.width * progress, height: 5)
                                    }
                                }.frame(height: 5)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1))
                Spacer()
            }
            .padding()
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("סגור") { dismiss() } }
            }
        }
    }

    var dateTitle: String {
        let f = DateFormatter(); f.dateFormat = "d MMMM yyyy"; f.locale = Locale(identifier: "he")
        return f.string(from: log.date)
    }
}
