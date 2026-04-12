import SwiftUI

struct StreakCalendarView: View {
    @EnvironmentObject var service: FirebaseService
    @State private var displayMonth: Date = Date()
    @State private var selectedLog: DailyLog? = nil
    @State private var selectedDateStr: String? = nil

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekLabels = ["א", "ב", "ג", "ד", "ה", "ו", "ש"]

    var streak: Int { service.currentStreak() }

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {

            // Streak header
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.title2)
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(streak)")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.orange)
                        Text("ימי רצף")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Month navigation
            HStack {
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(monthTitle)
                    .font(.headline)
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }

            // Week day labels
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar days
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarDays.indices, id: \.self) { i in
                    if let date = calendarDays[i] {
                        let key = FirebaseService.logKey(for: date)
                        let log = service.dailyLogs[key]
                        let isToday = cal.isDateInToday(date)
                        let isFuture = date > Date()

                        DayCell(log: log, isToday: isToday, isFuture: isFuture)
                            .onTapGesture {
                                if !isFuture, let log = log {
                                    selectedLog = log
                                } else if !isFuture {
                                    selectedDateStr = key
                                }
                            }
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .sheet(item: $selectedLog) { log in
            DayDetailSheet(log: log)
        }
    }

    // MARK: - Helpers

    var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "he")
        return f.string(from: displayMonth)
    }

    var calendarDays: [Date?] {
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: displayMonth)),
              let range = cal.range(of: .day, in: .month, for: monthStart) else { return [] }

        // weekday of first day (1=Sun, adjusted for our Sun-first grid)
        let firstWeekday = (cal.component(.weekday, from: monthStart) - 1) % 7
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            days.append(cal.date(byAdding: .day, value: day - 1, to: monthStart))
        }
        // pad to full rows
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    func changeMonth(by value: Int) {
        if let newMonth = cal.date(byAdding: .month, value: value, to: displayMonth) {
            displayMonth = newMonth
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let log: DailyLog?
    let isToday: Bool
    let isFuture: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
            if isToday {
                Circle()
                    .stroke(Color.primary, lineWidth: 1.5)
            }
        }
        .frame(height: 36)
        .opacity(isFuture ? 0.2 : 1)
    }

    var fillColor: Color {
        guard let log, !isFuture else { return Color(.systemGray5) }
        if log.isPerfect { return .green }
        if log.overallProgress > 0 {
            return Color.blue.opacity(0.3 + log.overallProgress * 0.7)
        }
        return Color(.systemGray5)
    }
}

// MARK: - Day Detail Sheet

struct DayDetailSheet: View {
    let log: DailyLog
    @Environment(\.dismiss) var dismiss

    private let activeCategories: [HabitCategory] = [.exercise, .work, .study, .hobby]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Perfect badge
                if log.isPerfect {
                    HStack {
                        Spacer()
                        Label("יום מושלם 🔥", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                        Spacer()
                    }
                }

                // Category breakdown
                VStack(spacing: 16) {
                    ForEach(activeCategories, id: \.self) { cat in
                        let progress = log.progress(for: cat)
                        HStack(spacing: 12) {
                            Text(cat.icon)
                                .font(.title2)
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(cat.label)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text("\(Int(progress * 100))%")
                                        .font(.subheadline.bold())
                                        .foregroundColor(progress == 1.0 ? .green : cat.color)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(cat.color.opacity(0.15))
                                            .frame(height: 6)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(progress == 1.0 ? Color.green : cat.color)
                                            .frame(width: geo.size.width * progress, height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)

                Spacer()
            }
            .padding()
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("סגור") { dismiss() }
                }
            }
        }
    }

    var dateTitle: String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        f.locale = Locale(identifier: "he")
        return f.string(from: log.date)
    }
}
