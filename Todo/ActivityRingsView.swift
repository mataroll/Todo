import SwiftUI

// MARK: - Data model for a single ring

struct RingData: Identifiable {
    let id: String
    let progress: Double   // 0.0 – 1.0
    let color: Color
    let trackColor: Color
    let label: String

    init(id: String, progress: Double, color: Color, label: String) {
        self.id = id
        self.progress = max(0, min(1, progress))
        self.color = color
        self.trackColor = color.opacity(0.15)
        self.label = label
    }
}

// MARK: - Single ring shape

private struct Ring: View {
    let data: RingData
    let diameter: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(data.trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: diameter, height: diameter)

            // Progress arc
            Circle()
                .trim(from: 0, to: data.progress)
                .stroke(data.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: data.progress)

            // Tip dot
            if data.progress > 0.01 {
                Circle()
                    .fill(data.color)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -diameter / 2)
                    .rotationEffect(.degrees(-90 + data.progress * 360))
                    .shadow(color: data.color.opacity(0.5), radius: 3)
            }
        }
    }
}

// MARK: - Stacked rings view

struct ActivityRingsView: View {
    let rings: [RingData]
    var size: CGFloat = 130      // outermost diameter
    var lineWidth: CGFloat = 14
    var spacing: CGFloat = 10    // gap between rings

    private var ringDiameters: [CGFloat] {
        rings.indices.map { i in
            size - CGFloat(i) * (lineWidth + spacing)
        }
    }

    var body: some View {
        ZStack {
            ForEach(rings.indices, id: \.self) { i in
                Ring(data: rings[i],
                     diameter: ringDiameters[i],
                     lineWidth: lineWidth)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Rings + labels row (for HomeView)

struct ActivityRingsRow: View {
    let rings: [RingData]

    var body: some View {
        HStack(spacing: 24) {
            ActivityRingsView(rings: rings)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(rings) { ring in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(ring.color)
                            .frame(width: 10, height: 10)
                        Text(ring.label)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text("\(Int(ring.progress * 100))%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ring.color)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
