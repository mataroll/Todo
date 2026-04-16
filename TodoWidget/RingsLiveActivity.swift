import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Compact rings for Dynamic Island pill

private struct CompactRingsView: View {
    let rings: [RingState]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(rings.prefix(3), id: \.id) { ring in
                ZStack {
                    Circle()
                        .stroke(hexColor(ring.colorHex).opacity(0.2),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    Circle()
                        .trim(from: 0, to: ring.progress)
                        .stroke(hexColor(ring.colorHex),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 16, height: 16)
            }
        }
    }
}

// MARK: - Live Activity 1 (and 3–5): Tasks view

private struct CoachTasksView: View {
    let state: RingsActivityAttributes.ContentState
    let offset: Int

    var tasks: [TimelineTask] {
        Array(state.timeline.dropFirst(offset).prefix(2))
    }

    // Parse "HH:mm" → today's Date for time comparison
    private func todayDate(from timeStr: String) -> Date? {
        let parts = timeStr.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1],
                                     second: 0, of: Date())
    }

    private func isActive(_ task: TimelineTask) -> Bool {
        guard let start = todayDate(from: task.startTime),
              let end   = todayDate(from: task.endTime) else { return false }
        let now = Date()
        return now >= start && now <= end
    }

    private func isUpcoming(_ task: TimelineTask) -> Bool {
        guard let start = todayDate(from: task.startTime) else { return false }
        return start > Date()
    }

    var body: some View {
        VStack(spacing: 0) {
            if tasks.isEmpty {
                Text("אין משימות מתוזמנות")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(tasks.indices, id: \.self) { i in
                        let task    = tasks[i]
                        let active  = isActive(task)
                        let upcoming = isUpcoming(task)
                        taskRow(task, active: active, upcoming: upcoming, isFirst: i == 0)
                        if i < tasks.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 1)
                                .padding(.horizontal, 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.10, green: 0.11, blue: 0.14))
        .environment(\.layoutDirection, .rightToLeft)
    }

    @ViewBuilder
    func taskRow(_ task: TimelineTask, active: Bool, upcoming: Bool, isFirst: Bool) -> some View {
        let accentColor: Color = active ? .green : (upcoming ? .cyan : .white.opacity(0.35))

        HStack(alignment: .center, spacing: 12) {

            // Confirm button — big filled circle when active, outline when not
            Button(intent: ConfirmHabitIntent(taskId: task.taskId, currentValue: task.isConfirmed)) {
                ZStack {
                    Circle()
                        .fill(active && !task.isConfirmed
                              ? Color.green.opacity(0.18)
                              : Color.clear)
                        .frame(width: active ? 38 : 26, height: active ? 38 : 26)

                    Image(systemName: task.isConfirmed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: active ? 26 : (isFirst ? 20 : 17), weight: .light))
                        .foregroundColor(task.isConfirmed ? .green : accentColor)
                }
            }
            .buttonStyle(.plain)
            .disabled(task.taskId.isEmpty)

            Spacer()

            // Task info
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(task.startTime)–\(task.endTime)")
                    .font(.system(size: active ? 11 : 10, weight: .semibold))
                    .foregroundColor(accentColor.opacity(0.85))

                Text(task.title)
                    .font(.system(size: active ? 22 : (isFirst ? 17 : 13),
                                  weight: active ? .bold : (isFirst ? .semibold : .medium)))
                    .foregroundColor(task.isConfirmed ? .white.opacity(0.25) : .white.opacity(active ? 1.0 : 0.6))
                    .strikethrough(task.isConfirmed, color: .white.opacity(0.3))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // Live indicator dot
            Circle()
                .fill(active ? Color.green : accentColor.opacity(0.5))
                .frame(width: active ? 7 : 5, height: active ? 7 : 5)
                .shadow(color: active ? Color.green.opacity(0.9) : .clear, radius: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, active ? 10 : 7)
        .background(active ? Color.green.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Live Activity 2: Rings + Habits view

private struct CoachRingsView: View {
    let state: RingsActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 0) {

            // Top: current + next task (compact)
            if !state.timeline.isEmpty {
                VStack(spacing: 5) {
                    ForEach(Array(state.timeline.prefix(2).enumerated()), id: \.offset) { i, task in
                        HStack(spacing: 8) {
                            Button(intent: ConfirmHabitIntent(taskId: task.taskId, currentValue: task.isConfirmed)) {
                                Image(systemName: task.isConfirmed ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(task.isConfirmed ? .green : .white.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .disabled(task.taskId.isEmpty)

                            Spacer()

                            Text(task.title)
                                .font(.system(size: i == 0 ? 12 : 10,
                                              weight: i == 0 ? .semibold : .regular))
                                .foregroundColor(i == 0 ? .white.opacity(0.88) : .white.opacity(0.4))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Text(task.startTime)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(i == 0 ? .cyan.opacity(0.65) : .white.opacity(0.22))
                                .frame(width: 32, alignment: .trailing)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 7)

                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
            }

            // Bottom: rings (left) + streak + habits + avoid (right)
            HStack(spacing: 16) {
                // Rings
                ZStack {
                    ForEach(state.rings.indices, id: \.self) { i in
                        let d = CGFloat(54 - i * 16)
                        Circle()
                            .stroke(hexColor(state.rings[i].colorHex).opacity(0.18),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: d, height: d)
                        Circle()
                            .trim(from: 0, to: state.rings[i].progress)
                            .stroke(hexColor(state.rings[i].colorHex),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: d, height: d)
                            .rotationEffect(.degrees(-90))
                    }
                }
                .frame(width: 58, height: 58)

                Spacer()

                // Right: streak + habits + avoid
                VStack(alignment: .trailing, spacing: 7) {
                    // Streak
                    Text("🔥 \(state.streakCount) ימי רצף")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.orange.opacity(0.25), lineWidth: 1))

                    // Habits
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("הרגלים")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white.opacity(0.28))
                            .kerning(1)
                        HStack(spacing: 10) {
                            ForEach(0..<state.habitSymbols.count, id: \.self) { i in
                                let id = i < state.habitIds.count ? state.habitIds[i] : ""
                                let confirmed = i < state.confirmedHabits.count ? state.confirmedHabits[i] : false
                                Button(intent: ConfirmHabitIntent(taskId: id, currentValue: confirmed)) {
                                    Text(state.habitSymbols[i])
                                        .font(.system(size: 18))
                                        .opacity(confirmed ? 1.0 : 0.22)
                                        .grayscale(confirmed ? 0 : 1)
                                }
                                .buttonStyle(.plain)
                                .disabled(id.isEmpty)
                            }
                        }
                    }

                    // Avoid — flower bad habit
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("הימנע")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white.opacity(0.28))
                            .kerning(1)
                        Button(intent: RecordSlipIntent(habitKey: "nofap", habitLabel: "ניקיון")) {
                            Text("🌸")
                                .font(.system(size: 22))
                        }
                        .buttonStyle(.plain)
                    }

                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.10, green: 0.11, blue: 0.14))
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - Widget configuration

struct RingsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RingsActivityAttributes.self) { context in
            // Lock screen banner
            if context.attributes.mode == .tasks {
                CoachTasksView(state: context.state, offset: context.attributes.taskOffset)
            } else {
                CoachRingsView(state: context.state)
            }
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading)  { Color.clear.frame(width: 1) }
                DynamicIslandExpandedRegion(.trailing) { Color.clear.frame(width: 1) }
                DynamicIslandExpandedRegion(.bottom)   { Color.clear.frame(height: 1) }
            } compactLeading: {
                Color.clear.frame(width: 1)
            } compactTrailing: {
                Color.clear.frame(width: 1)
            } minimal: {
                Color.clear.frame(width: 1, height: 1)
            }
        }
    }
}

// MARK: - Utilities

private func hexColor(_ hex: String) -> Color {
    let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    guard Scanner(string: h).scanHexInt64(&int), h.count == 6 else { return .blue }
    return Color(red: Double((int >> 16) & 0xFF) / 255,
                 green: Double((int >> 8)  & 0xFF) / 255,
                 blue:  Double(int         & 0xFF) / 255)
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            switch edge {
            case .top:      path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom:   path.addRect(CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading:  path.addRect(CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing: path.addRect(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }
        return path
    }
}
