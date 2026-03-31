import SwiftUI
import UIKit

private let canvasWidth: CGFloat  = 4200
private let canvasHeight: CGFloat = 2200

// Layout: 3 broad columns (left ~200, middle ~1400, right ~3100)
// Categories spread horizontally so board is wide not tall
private let categoryOrigins: [NodeCategory: CGPoint] = [
    .keyBlockers: CGPoint(x: 1700, y: 100),  // top center — most important
    .goals:       CGPoint(x: 200,  y: 380),  // left
    .doctors:     CGPoint(x: 200,  y: 800),  // left below goals
    .friends:     CGPoint(x: 3200, y: 100),  // right
    .creative:    CGPoint(x: 200,  y: 1300), // left bottom
    .tech:        CGPoint(x: 1300, y: 380),  // middle
    .purchases:   CGPoint(x: 1300, y: 820),  // middle — biggest cluster
    .recurring:   CGPoint(x: 3200, y: 500),  // right
    .dreams:      CGPoint(x: 1300, y: 1750), // middle bottom
    .reminders:   CGPoint(x: 3200, y: 950),  // right
    .oneTime:     CGPoint(x: 3200, y: 1350), // right bottom
]

private let colsPerCategory = 5
private let colSpacing: CGFloat = 185
private let rowSpacing: CGFloat = 115

// MARK: - Zoomable UIScrollView wrapper

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    var content: () -> Content
    @Binding var scale: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator(scale: $scale) }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 4.0
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = UIColor(red: 0.37, green: 0.23, blue: 0.13, alpha: 1)

        // Plain UIView as zoom target — UIScrollView transforms this, not the host directly
        let container = UIView()
        container.backgroundColor = .clear
        container.frame = CGRect(origin: .zero, size: CGSize(width: canvasWidth, height: canvasHeight))

        let host = UIHostingController(rootView: content())
        host.view.backgroundColor = .clear
        host.view.frame = container.bounds
        host.view.autoresizingMask = []
        container.addSubview(host.view)

        scrollView.addSubview(container)
        scrollView.contentSize = CGSize(width: canvasWidth, height: canvasHeight)
        scrollView.contentInsetAdjustmentBehavior = .never

        context.coordinator.container = container
        context.coordinator.host = host

        DispatchQueue.main.async {
            scrollView.zoomScale = 0.35
            let midX = max(0, canvasWidth * scrollView.zoomScale / 2 - scrollView.bounds.width / 2)
            let midY = max(0, canvasHeight * scrollView.zoomScale / 2 - scrollView.bounds.height / 2)
            scrollView.contentOffset = CGPoint(x: midX, y: midY)
        }

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.host?.rootView = content()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var container: UIView?
        var host: UIHostingController<Content>?
        @Binding var scale: CGFloat
        init(scale: Binding<CGFloat>) { _scale = scale }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { container }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            scale = scrollView.zoomScale
        }
    }
}

// MARK: - Detective Board

struct DetectiveBoardView: View {
    @EnvironmentObject var service: FirebaseService
    @State private var livePositions: [String: CGPoint] = [:]
    @State private var defaultPositions: [String: CGPoint] = [:]
    @State private var scale: CGFloat = 0.35
    @State private var menuNode: Node? = nil

    func savedPosition(for node: Node) -> CGPoint {
        guard let id = node.id else { return CGPoint(x: 200, y: 200) }
        return service.positions[id] ?? defaultPositions[id] ?? CGPoint(x: 200, y: 200)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ZoomableScrollView(content: { boardCanvas }, scale: $scale)

                if let node = menuNode {
                    CardActionMenu(node: node, onDismiss: { menuNode = nil })
                        .environmentObject(service)
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            .navigationTitle("לוח בלש")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, .rightToLeft)
            .onAppear {
                computeDefaultPositions()
                service.startListeningPositions()
            }
            .onChange(of: service.nodes) { _ in
                computeDefaultPositions()
                service.initializePositions(defaultPositions)
            }
            .onChange(of: service.positions) { _ in
                // positions loaded from Firestore — initialize any missing ones
                service.initializePositions(defaultPositions)
            }
            .onDisappear {
                service.stopListeningPositions()
            }
        }
    }

    var boardCanvas: some View {
        ZStack(alignment: .topLeading) {

            // Cork background
            LinearGradient(
                colors: [
                    Color(red: 0.44, green: 0.29, blue: 0.17),
                    Color(red: 0.37, green: 0.23, blue: 0.13),
                    Color(red: 0.40, green: 0.26, blue: 0.15),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: canvasWidth, height: canvasHeight)

            // Category titles
            ForEach(NodeCategory.allCases, id: \.self) { category in
                if service.nodes.contains(where: { $0.category == category }),
                   let origin = categoryOrigins[category] {
                    Text(category.label)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 1, y: 1)
                        .position(x: origin.x + CGFloat(colsPerCategory) * colSpacing / 2, y: origin.y - 35)
                        .environment(\.layoutDirection, .rightToLeft)
                }
            }

            // Draggable node cards
            ForEach(service.nodes) { node in
                DraggableBoardCard(
                    node: node,
                    savedPosition: savedPosition(for: node),
                    onLiveDrag: { pos in livePositions[node.id ?? ""] = pos },
                    onDrop: { pos in
                        guard let id = node.id else { return }
                        service.savePosition(nodeId: id, position: pos)
                        livePositions.removeValue(forKey: id)
                    },
                    onMenu: { menuNode = node }
                )
            }

            // String lines on top of everything
            Canvas { context, _ in
                for node in service.nodes {
                    guard let nodeId = node.id else { continue }
                    let from = livePositions[nodeId]
                        ?? service.positions[nodeId]
                        ?? defaultPositions[nodeId]
                        ?? CGPoint(x: 200, y: 200)

                    for conn in node.connections {
                        guard service.nodes.contains(where: { $0.id == conn.toId }) else { continue }
                        let to = livePositions[conn.toId]
                            ?? service.positions[conn.toId]
                            ?? defaultPositions[conn.toId]
                            ?? CGPoint(x: 200, y: 200)

                        let lineColor = Color(hex: conn.colorHex) ?? .red

                        let pinOffset: CGFloat = 35
                        let p1 = CGPoint(x: from.x, y: from.y - pinOffset)
                        let p2 = CGPoint(x: to.x,   y: to.y   - pinOffset)

                        let dx = p2.x - p1.x
                        let dy = p2.y - p1.y
                        let length = sqrt(dx*dx + dy*dy)
                        guard length > 1 else { continue }

                        let ux = dx / length, uy = dy / length

                        var shadow = Path()
                        shadow.move(to: p1)
                        shadow.addLine(to: p2)
                        context.stroke(shadow, with: .color(.black.opacity(0.35)),
                                       style: StrokeStyle(lineWidth: 8, lineCap: .round))

                        var path = Path()
                        path.move(to: p1)
                        path.addLine(to: p2)
                        context.stroke(path, with: .color(lineColor.opacity(0.95)),
                                       style: StrokeStyle(lineWidth: 5, lineCap: .round))

                        let arrowLen: CGFloat = 16
                        let arrowAngle: CGFloat = 0.42
                        let ax1 = p2.x - arrowLen * (ux * cos(arrowAngle) - uy * sin(arrowAngle))
                        let ay1 = p2.y - arrowLen * (uy * cos(arrowAngle) + ux * sin(arrowAngle))
                        let ax2 = p2.x - arrowLen * (ux * cos(arrowAngle) + uy * sin(arrowAngle))
                        let ay2 = p2.y - arrowLen * (uy * cos(arrowAngle) - ux * sin(arrowAngle))
                        var arrow = Path()
                        arrow.move(to: CGPoint(x: ax1, y: ay1))
                        arrow.addLine(to: p2)
                        arrow.addLine(to: CGPoint(x: ax2, y: ay2))
                        context.stroke(arrow, with: .color(lineColor.opacity(0.95)),
                                       style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    }
                }
            }
            .frame(width: canvasWidth, height: canvasHeight)
            .allowsHitTesting(false)
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .environment(\.layoutDirection, .leftToRight)  // canvas uses LTR coords; cards handle their own RTL
    }

    func computeDefaultPositions() {
        var result: [String: CGPoint] = [:]
        var categoryCount: [NodeCategory: Int] = [:]

        let sorted = service.nodes.sorted {
            if $0.category.sortOrder != $1.category.sortOrder {
                return $0.category.sortOrder < $1.category.sortOrder
            }
            return $0.title < $1.title
        }

        for node in sorted {
            guard let id = node.id else { continue }
            let idx = categoryCount[node.category, default: 0]
            categoryCount[node.category] = idx + 1
            let origin = categoryOrigins[node.category] ?? CGPoint(x: 600, y: 600)
            let col = CGFloat(idx % colsPerCategory)
            let row = CGFloat(idx / colsPerCategory)
            result[id] = CGPoint(x: origin.x + col * colSpacing, y: origin.y + row * rowSpacing)
        }
        defaultPositions = result
    }
}

// MARK: - Draggable Card (long press → drag)

struct DraggableBoardCard: View {
    let node: Node
    let savedPosition: CGPoint
    let onLiveDrag: (CGPoint) -> Void
    let onDrop: (CGPoint) -> Void
    let onMenu: () -> Void

    @GestureState private var dragState: DragState = .idle

    enum DragState {
        case idle, pressing, dragging(CGSize)
        var translation: CGSize {
            if case .dragging(let t) = self { return t }
            return .zero
        }
        var isActive: Bool { if case .idle = self { return false }; return true }
        var isDragging: Bool { if case .dragging = self { return true }; return false }
    }

    var currentPosition: CGPoint {
        CGPoint(x: savedPosition.x + dragState.translation.width,
                y: savedPosition.y + dragState.translation.height)
    }

    var body: some View {
        let gesture = LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .updating($dragState) { value, state, _ in
                switch value {
                case .first(true):       state = .pressing
                case .second(true, let d): state = .dragging(d?.translation ?? .zero)
                default: break
                }
            }
            .onChanged { value in
                if case .second(true, let drag) = value, let drag = drag {
                    onLiveDrag(CGPoint(x: savedPosition.x + drag.translation.width,
                                      y: savedPosition.y + drag.translation.height))
                }
            }
            .onEnded { value in
                if case .second(true, let drag) = value, let drag = drag {
                    let t = drag.translation
                    if abs(t.width) < 8 && abs(t.height) < 8 {
                        onMenu()
                    } else {
                        onDrop(CGPoint(x: savedPosition.x + t.width,
                                       y: savedPosition.y + t.height))
                    }
                }
            }

        BoardNoteCard(node: node, isActive: dragState.isActive)
            .scaleEffect(dragState.isDragging ? 1.08 : 1.0)
            .shadow(color: dragState.isActive ? .black.opacity(0.6) : .clear, radius: 12)
            .animation(.easeInOut(duration: 0.15), value: dragState.isActive)
            .position(currentPosition)
            .zIndex(dragState.isActive ? 999 : 0)
            .gesture(gesture)
    }
}

// MARK: - Card

struct BoardNoteCard: View {
    let node: Node
    var isActive: Bool = false

    var cardColor: Color {
        switch node.status {
        case .blocked:    return Color(red: 0.95, green: 0.82, blue: 0.82)
        case .open:       return Color(red: 0.98, green: 0.96, blue: 0.82)
        case .inProgress: return Color(red: 0.82, green: 0.94, blue: 0.82)
        case .done:       return Color(red: 0.78, green: 0.78, blue: 0.78)
        }
    }

    var tiltAngle: Double {
        if isActive { return 0 }
        let hash = node.title.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Double(hash % 9 - 4) * 0.4
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(node.title)
                    .font(.system(size: node.cardSize.fontSize, weight: isActive ? .bold : .medium))
                    .foregroundColor(node.status == .done ? .gray : Color(red: 0.12, green: 0.08, blue: 0.03))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Spacer()
                    Text(node.category.label)
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                    Text(node.status.dot)
                        .font(.system(size: 9))
                }
            }
            .padding(.horizontal, 9)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .frame(width: node.cardSize.cardWidth)
            .background(cardColor)
            .cornerRadius(2)
            .shadow(
                color: .black.opacity(isActive ? 0 : 0.4),
                radius: isActive ? 0 : 4, x: 2, y: 2
            )

            // Pin
            Circle()
                .fill(Color(red: 0.7, green: 0.15, blue: 0.15))
                .frame(width: 12, height: 12)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                .offset(y: -6)
        }
        .rotationEffect(.degrees(tiltAngle))
        .animation(.easeInOut(duration: 0.15), value: isActive)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
