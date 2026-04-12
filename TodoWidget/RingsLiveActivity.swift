import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Compact ring for Dynamic Island

private struct CompactRingsView: View {
    let rings: [RingState]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(rings.prefix(3), id: \.id) { ring in
                ZStack {
                    Circle()
                        .stroke(color(ring.colorHex).opacity(0.25),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    Circle()
                        .trim(from: 0, to: ring.progress)
                        .stroke(color(ring.colorHex),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 18, height: 18)
            }
        }
    }

    func color(_ hex: String) -> Color {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&int), h.count == 6 else { return .green }
        return Color(red: Double((int >> 16) & 0xFF) / 255,
                     green: Double((int >> 8)  & 0xFF) / 255,
                     blue:  Double(int         & 0xFF) / 255)
    }
}

// MARK: - Expanded / Lock Screen View

private struct CoachLiveActivityView: View {
    let state: RingsActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 12) {
            // Top Row: Streak + Codenames
            HStack {
                Text("🔥 \(state.streakCount) ימי רצף")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.orange.opacity(0.2), lineWidth: 1))
                
                Spacer()
                
                Text(state.codenames)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1)
            }
            
            // Middle: Timeline
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(state.timeline, id: \.title) { task in
                    HStack(spacing: 8) {
                        Spacer()
                        Text("\(task.startTime)–\(task.endTime): \(task.title)")
                            .font(.system(size: task.status == "now" ? 11 : 10, weight: task.status == "now" ? .bold : .medium))
                            .foregroundColor(task.status == "now" ? .cyan : (task.status == "next" ? .white.opacity(0.7) : .white.opacity(0.4)))
                        
                        Circle()
                            .fill(task.status == "now" ? Color.cyan : (task.status == "next" ? Color.gray : Color.gray.opacity(0.3)))
                            .frame(width: 6, height: 6)
                            .shadow(color: task.status == "now" ? Color.cyan.opacity(0.6) : .clear, radius: 4)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Bottom: Habits + Pulse
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("הרגלים")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                        .kerning(1)
                    HStack(spacing: 12) {
                        ForEach(0..<state.habitSymbols.count, id: \.self) { i in
                            let id = i < state.habitIds.count ? state.habitIds[i] : ""
                            let confirmed = i < state.confirmedHabits.count ? state.confirmedHabits[i] : false
                            Button(intent: ConfirmHabitIntent(taskId: id, currentValue: confirmed)) {
                                Text(state.habitSymbols[i])
                                    .font(.system(size: 18))
                                    .opacity(confirmed ? 1.0 : 0.2)
                                    .grayscale(confirmed ? 0 : 1)
                            }
                            .buttonStyle(.plain)
                            .disabled(id.isEmpty)
                        }
                    }

                    // Negative habit quick-mark
                    Text("הימנע")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.red.opacity(0.7))
                        .kerning(1)
                    HStack(spacing: 10) {
                        ForEach(negativeHabits, id: \.key) { habit in
                            Button(intent: RecordSlipIntent(habitKey: habit.key, habitLabel: habit.label)) {
                                Text(habit.icon)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()
                
                // Pulse Rings (Small)
                ZStack {
                    ForEach(state.rings.indices, id: \.self) { i in
                        let d = CGFloat(34 - i * 10)
                        Circle()
                            .stroke(color(state.rings[i].colorHex).opacity(0.15), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: d, height: d)
                        Circle()
                            .trim(from: 0, to: state.rings[i].progress)
                            .stroke(color(state.rings[i].colorHex), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: d, height: d)
                            .rotationEffect(.degrees(-90))
                    }
                }
                .frame(width: 40, height: 40)
            }
            .padding(.top, 8)
            .border(width: 1, edges: [.top], color: Color.white.opacity(0.05))
        }
        .padding(16)
        .background(Color(red: 0.1, green: 0.11, blue: 0.14).opacity(0.95))
        .environment(\.layoutDirection, .rightToLeft)
    }

    func color(_ hex: String) -> Color {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&int), h.count == 6 else { return .green }
        return Color(red: Double((int >> 16) & 0xFF) / 255,
                     green: Double((int >> 8)  & 0xFF) / 255,
                     blue:  Double(int         & 0xFF) / 255)
    }
}

// Utility for border
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
            var x: CGFloat { rect.minX }
            var y: CGFloat { rect.minY }
            var w: CGFloat { rect.width }
            var h: CGFloat { rect.height }
            switch edge {
            case .top: path.addRect(CGRect(x: x, y: y, width: w, height: width))
            case .bottom: path.addRect(CGRect(x: x, y: y + h - width, width: w, height: width))
            case .leading: path.addRect(CGRect(x: x, y: y, width: width, height: h))
            case .trailing: path.addRect(CGRect(x: x + w - width, y: y, width: width, height: h))
            }
        }
        return path
    }
}

// MARK: - Widget

struct RingsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RingsActivityAttributes.self) { context in
            CoachLiveActivityView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    CompactRingsView(rings: context.state.rings)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("38%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.blue)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    CoachLiveActivityView(state: context.state)
                }
            } compactLeading: {
                CompactRingsView(rings: Array(context.state.rings.prefix(3)))
            } compactTrailing: {
                Text("\(Int(context.state.rings.first?.progress ?? 0 * 100))%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.blue)
            } minimal: {
                Circle()
                    .trim(from: 0, to: context.state.rings.first?.progress ?? 0)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}
