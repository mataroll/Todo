import ActivityKit
import WidgetKit
import SwiftUI

// Re-declare here since widget is a separate target
struct RingState: Codable, Hashable {
    let id: String
    let progress: Double
    let colorHex: String
    let label: String
}

struct RingsActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var rings: [RingState]
        var updatedAt: Date
    }
}

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
        .padding(.horizontal, 4)
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

// MARK: - Lock screen / expanded view

private struct ExpandedRingsView: View {
    let rings: [RingState]

    var body: some View {
        HStack(spacing: 16) {
            // Mini rings stack
            ZStack {
                ForEach(rings.indices, id: \.self) { i in
                    let d = CGFloat(48 - i * 14)
                    ZStack {
                        Circle()
                            .stroke(color(rings[i].colorHex).opacity(0.2),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        Circle()
                            .trim(from: 0, to: rings[i].progress)
                            .stroke(color(rings[i].colorHex),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: d, height: d)
                }
            }
            .frame(width: 55, height: 55)

            // Labels
            VStack(alignment: .leading, spacing: 4) {
                ForEach(rings, id: \.id) { ring in
                    HStack(spacing: 6) {
                        Circle().fill(color(ring.colorHex)).frame(width: 7, height: 7)
                        Text(ring.label)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(ring.progress * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(color(ring.colorHex))
                    }
                }
            }
        }
        .padding(12)
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

// MARK: - Live Activity

struct RingsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RingsActivityAttributes.self) { context in
            // Lock screen banner
            ExpandedRingsView(rings: context.state.rings)
                .background(Color.black.opacity(0.85))
                .cornerRadius(16)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    CompactRingsView(rings: context.state.rings)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("לוח בלש")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedRingsView(rings: context.state.rings)
                }
            } compactLeading: {
                CompactRingsView(rings: Array(context.state.rings.prefix(2)))
            } compactTrailing: {
                if let first = context.state.rings.first {
                    Text("\(Int(first.progress * 100))%")
                        .font(.system(size: 11, weight: .bold))
                }
            } minimal: {
                if let first = context.state.rings.first {
                    ZStack {
                        Circle()
                            .stroke(Color.green.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        Circle()
                            .trim(from: 0, to: first.progress)
                            .stroke(Color.green,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 20, height: 20)
                }
            }
        }
    }
}
