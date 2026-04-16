import SwiftUI
import UIKit

private let canvasWidth: CGFloat  = 4200
private let canvasHeight: CGFloat = 2200

private let categoryOrigins: [NodeCategory: CGPoint] = [
    .keyBlockers: CGPoint(x: 1700, y: 100),
    .goals:       CGPoint(x: 200,  y: 380),
    .doctors:     CGPoint(x: 200,  y: 800),
    .friends:     CGPoint(x: 3200, y: 100),
    .creative:    CGPoint(x: 200,  y: 1300),
    .tech:        CGPoint(x: 1300, y: 380),
    .purchases:   CGPoint(x: 1300, y: 820),
    .recurring:   CGPoint(x: 3200, y: 500),
    .dreams:      CGPoint(x: 1300, y: 1750),
    .reminders:   CGPoint(x: 3200, y: 950),
    .oneTime:     CGPoint(x: 3200, y: 1350),
]

private let colsPerCategory = 5
private let colSpacing: CGFloat = 185
private let rowSpacing: CGFloat = 115

// MARK: - Persistence types

private struct HeadlineEntry: Codable {
    var text: String
    var x: Double
    var y: Double
    var fontSize: Double
}

struct FreeLabel: Codable {
    var id: String
    var text: String
    var x: Double
    var y: Double
    var fontSize: Double
}

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
    @EnvironmentObject var service: SupabaseService
    @State private var livePositions: [String: CGPoint] = [:]
    @State private var defaultPositions: [String: CGPoint] = [:]
    @State private var scale: CGFloat = 0.35
    @State private var menuNode: Node? = nil
    @State private var hidePurchases: Bool = true

    // Category headlines
    @State private var headlinePositions: [NodeCategory: CGPoint] = [:]
    @State private var headlineFontSizes: [NodeCategory: CGFloat] = [:]
    @State private var headlineTexts: [NodeCategory: String] = [:]
    @State private var menuCategory: NodeCategory? = nil

    // Free labels (created by long-pressing empty board)
    @State private var freeLabels: [String: FreeLabel] = [:]
    @State private var menuFreeLabel: FreeLabel? = nil

    // Board-level actions
    @State private var boardTapPoint: CGPoint? = nil
    @State private var connectionToDelete: (fromId: String, toId: String)? = nil
    @State private var showQuickAddTask = false
    @State private var showQuickAddHeadline = false

    var displayNodes: [Node] {
        hidePurchases ? service.nodes.filter { $0.category != .purchases } : service.nodes
    }

    // MARK: - Position helpers

    func savedPosition(for node: Node) -> CGPoint {
        guard let id = node.id else { return CGPoint(x: 200, y: 200) }
        return service.positions[id] ?? defaultPositions[id] ?? CGPoint(x: 200, y: 200)
    }

    func defaultHeadlinePosition(for category: NodeCategory) -> CGPoint {
        guard let origin = categoryOrigins[category] else { return CGPoint(x: 200, y: 100) }
        return CGPoint(x: origin.x + CGFloat(colsPerCategory) * colSpacing / 2,
                       y: origin.y - 35)
    }

    func savedHeadlinePosition(for category: NodeCategory) -> CGPoint {
        headlinePositions[category] ?? defaultHeadlinePosition(for: category)
    }

    // MARK: - Connection geometry

    private func pointToSegmentDistance(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let lenSq = dx*dx + dy*dy
        guard lenSq > 0 else { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, ((p.x - a.x)*dx + (p.y - a.y)*dy) / lenSq))
        return hypot(p.x - (a.x + t*dx), p.y - (a.y + t*dy))
    }

    private func nearestConnection(to point: CGPoint, threshold: CGFloat = 28) -> (fromId: String, toId: String)? {
        let pinOffset: CGFloat = 35
        for node in displayNodes {
            guard let nodeId = node.id else { continue }
            let from = livePositions[nodeId] ?? service.positions[nodeId] ?? defaultPositions[nodeId] ?? CGPoint(x: 200, y: 200)
            let p1 = CGPoint(x: from.x, y: from.y + 40)
            for conn in node.connections {
                guard displayNodes.contains(where: { $0.id == conn.toId }) else { continue }
                let to = livePositions[conn.toId] ?? service.positions[conn.toId] ?? defaultPositions[conn.toId] ?? CGPoint(x: 200, y: 200)
                let p2 = CGPoint(x: to.x, y: to.y - pinOffset)
                if pointToSegmentDistance(point, p1, p2) < threshold {
                    return (nodeId, conn.toId)
                }
            }
        }
        return nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                ZoomableScrollView(content: { boardCanvas }, scale: $scale)

                // Card action menu
                if let node = menuNode {
                    CardActionMenu(node: node, onDismiss: { menuNode = nil })
                        .environmentObject(service)
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }

                // Category headline editor
                if let category = menuCategory {
                    HeadlineActionMenu(
                        text: headlineTexts[category] ?? category.label,
                        fontSize: headlineFontSizes[category] ?? 20,
                        onDismiss: { menuCategory = nil },
                        onSave: { text, size in
                            headlineTexts[category] = text
                            headlineFontSizes[category] = size
                            saveHeadlineData()
                        }
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }

                // Free label editor (with delete)
                if let label = menuFreeLabel {
                    HeadlineActionMenu(
                        text: label.text,
                        fontSize: CGFloat(label.fontSize),
                        onDismiss: { menuFreeLabel = nil },
                        onSave: { text, size in
                            var updated = label
                            updated.text = text
                            updated.fontSize = Double(size)
                            freeLabels[label.id] = updated
                            saveFreeLabels()
                        },
                        onDelete: {
                            freeLabels.removeValue(forKey: label.id)
                            saveFreeLabels()
                            menuFreeLabel = nil
                        }
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }

                // Board long-press context menu (create task / headline)
                if boardTapPoint != nil {
                    BoardTapMenu(
                        onDismiss: { boardTapPoint = nil },
                        onCreateTask: {
                            boardTapPoint = boardTapPoint  // keep so sheet can read it
                            showQuickAddTask = true
                        },
                        onCreateHeadline: {
                            showQuickAddHeadline = true
                        }
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }

                // Connection delete confirmation
                if let conn = connectionToDelete {
                    ConnectionDeleteMenu(
                        fromNode: service.node(byId: conn.fromId),
                        toNode: service.node(byId: conn.toId),
                        onDismiss: { connectionToDelete = nil },
                        onDelete: {
                            service.removeConnection(from: conn.fromId, to: conn.toId)
                            connectionToDelete = nil
                        }
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            .navigationTitle("לוח בלש")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation { hidePurchases.toggle() }
                    } label: {
                        Label(hidePurchases ? "הצג רכישות" : "הסתר רכישות",
                              systemImage: hidePurchases ? "cart.badge.plus" : "cart.fill")
                            .font(.footnote)
                    }
                }
            }
            .onAppear {
                computeDefaultPositions()
                service.startListeningPositions()
                loadHeadlineData()
                loadFreeLabels()
            }
            .onChange(of: service.nodes) { _, _ in
                computeDefaultPositions()
                service.initializePositions(defaultPositions)
            }
            .onChange(of: service.positions) { _, _ in
                service.initializePositions(defaultPositions)
            }
            .onDisappear {
                service.stopListeningPositions()
            }
            .sheet(isPresented: $showQuickAddTask) {
                if let pt = boardTapPoint {
                    BoardQuickAddSheet(canvasPosition: pt)
                        .environmentObject(service)
                        .onDisappear { boardTapPoint = nil }
                }
            }
            .sheet(isPresented: $showQuickAddHeadline) {
                BoardQuickHeadlineSheet(canvasPosition: boardTapPoint ?? CGPoint(x: 600, y: 600)) { label in
                    freeLabels[label.id] = label
                    saveFreeLabels()
                }
                .onDisappear { boardTapPoint = nil }
            }
        }
    }

    // MARK: - Board canvas

    var boardCanvas: some View {
        ZStack(alignment: .topLeading) {

            // Cork background — long press here to create or delete connections
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
            .contentShape(Rectangle())
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                    .onEnded { val in
                        guard case .second(true, let d?) = val else { return }
                        let pt = d.startLocation
                        if let conn = nearestConnection(to: pt) {
                            connectionToDelete = conn
                        } else {
                            boardTapPoint = pt
                        }
                    }
            )

            // Category headlines (draggable + editable)
            ForEach(NodeCategory.allCases, id: \.self) { category in
                if displayNodes.contains(where: { $0.category == category }) {
                    DraggableHeadline(
                        text: headlineTexts[category] ?? category.label,
                        fontSize: headlineFontSizes[category] ?? 20,
                        savedPosition: savedHeadlinePosition(for: category),
                        onDrop: { pos in
                            headlinePositions[category] = pos
                            saveHeadlineData()
                        },
                        onMenu: { menuCategory = category }
                    )
                }
            }

            // Free labels (draggable + editable + deletable)
            ForEach(Array(freeLabels.values), id: \.id) { label in
                DraggableHeadline(
                    text: label.text,
                    fontSize: CGFloat(label.fontSize),
                    savedPosition: CGPoint(x: label.x, y: label.y),
                    onDrop: { pos in
                        var updated = label
                        updated.x = Double(pos.x)
                        updated.y = Double(pos.y)
                        freeLabels[label.id] = updated
                        saveFreeLabels()
                    },
                    onMenu: { menuFreeLabel = label }
                )
            }

            // Draggable node cards
            ForEach(displayNodes) { node in
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

            // String lines
            Canvas { context, _ in
                for node in displayNodes {
                    guard let nodeId = node.id else { continue }
                    let from = livePositions[nodeId]
                        ?? service.positions[nodeId]
                        ?? defaultPositions[nodeId]
                        ?? CGPoint(x: 200, y: 200)

                    for conn in node.connections {
                        guard displayNodes.contains(where: { $0.id == conn.toId }) else { continue }
                        let to = livePositions[conn.toId]
                            ?? service.positions[conn.toId]
                            ?? defaultPositions[conn.toId]
                            ?? CGPoint(x: 200, y: 200)

                        let lineColor = Color(hex: conn.colorHex) ?? .red
                        let pinOffset: CGFloat = 35
                        let p1 = CGPoint(x: from.x, y: from.y + 40)   // bottom center of source card
                        let p2 = CGPoint(x: to.x,   y: to.y - pinOffset) // top/pin of destination card

                        let dx = p2.x - p1.x, dy = p2.y - p1.y
                        let length = sqrt(dx*dx + dy*dy)
                        guard length > 1 else { continue }
                        let ux = dx / length, uy = dy / length

                        var shadow = Path(); shadow.move(to: p1); shadow.addLine(to: p2)
                        context.stroke(shadow, with: .color(.black.opacity(0.35)),
                                       style: StrokeStyle(lineWidth: 8, lineCap: .round))

                        var path = Path(); path.move(to: p1); path.addLine(to: p2)
                        context.stroke(path, with: .color(lineColor.opacity(0.95)),
                                       style: StrokeStyle(lineWidth: 5, lineCap: .round))

                        let arrowLen: CGFloat = 16, arrowAngle: CGFloat = 0.42
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
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: - Default positions

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

    // MARK: - Category headline persistence

    private func loadHeadlineData() {
        guard let data = UserDefaults.standard.data(forKey: "board_headlines_v1"),
              let dict = try? JSONDecoder().decode([String: HeadlineEntry].self, from: data)
        else { return }
        for (key, entry) in dict {
            guard let category = NodeCategory(rawValue: key) else { continue }
            headlinePositions[category] = CGPoint(x: entry.x, y: entry.y)
            headlineFontSizes[category] = CGFloat(entry.fontSize)
            headlineTexts[category] = entry.text
        }
    }

    private func saveHeadlineData() {
        var dict: [String: HeadlineEntry] = [:]
        for category in NodeCategory.allCases {
            let pos = headlinePositions[category] ?? defaultHeadlinePosition(for: category)
            dict[category.rawValue] = HeadlineEntry(
                text: headlineTexts[category] ?? category.label,
                x: Double(pos.x), y: Double(pos.y),
                fontSize: Double(headlineFontSizes[category] ?? 20)
            )
        }
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: "board_headlines_v1")
        }
    }

    // MARK: - Free label persistence

    private func loadFreeLabels() {
        guard let data = UserDefaults.standard.data(forKey: "board_free_labels_v1"),
              let list = try? JSONDecoder().decode([FreeLabel].self, from: data)
        else { return }
        freeLabels = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
    }

    private func saveFreeLabels() {
        let list = Array(freeLabels.values)
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: "board_free_labels_v1")
        }
    }
}

// MARK: - Draggable Headline

struct DraggableHeadline: View {
    let text: String
    let fontSize: CGFloat
    let savedPosition: CGPoint
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
                case .first(true): state = .pressing
                case .second(true, let d): state = .dragging(d?.translation ?? .zero)
                default: break
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

        Text(text)
            .font(.system(size: fontSize, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(dragState.isActive ? 0.55 : 0.35))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.5), radius: dragState.isActive ? 8 : 4, x: 1, y: 1)
            .scaleEffect(dragState.isDragging ? 1.06 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: dragState.isActive)
            .position(currentPosition)
            .zIndex(dragState.isActive ? 998 : 0)
            .gesture(gesture)
    }
}

// MARK: - Headline Action Menu

struct HeadlineActionMenu: View {
    let text: String
    let fontSize: CGFloat
    let onDismiss: () -> Void
    let onSave: (String, CGFloat) -> Void
    var onDelete: (() -> Void)? = nil

    @State private var editText: String
    @State private var editFontSize: CGFloat
    @FocusState private var isFocused: Bool

    init(text: String, fontSize: CGFloat,
         onDismiss: @escaping () -> Void,
         onSave: @escaping (String, CGFloat) -> Void,
         onDelete: (() -> Void)? = nil) {
        self.text = text
        self.fontSize = fontSize
        self.onDismiss = onDismiss
        self.onSave = onSave
        self.onDelete = onDelete
        _editText = State(initialValue: text)
        _editFontSize = State(initialValue: fontSize)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 24) {
                Text(editText.isEmpty ? "כותרת" : editText)
                    .font(.system(size: editFontSize, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 1, y: 1)
                    .padding(.bottom, 4)

                TextField("כותרת", text: $editText)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
                    .padding(.horizontal, 48)

                HStack(spacing: 24) {
                    Button { editFontSize = max(10, editFontSize - 4) } label: {
                        Image(systemName: "textformat.size.smaller")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                    }
                    Text("\(Int(editFontSize))pt")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 52)
                    Button { editFontSize = min(56, editFontSize + 4) } label: {
                        Image(systemName: "textformat.size.larger")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                    }
                }

                HStack(spacing: 32) {
                    Button("ביטול") { onDismiss() }
                        .foregroundColor(.secondary)
                    Button("שמור") {
                        onSave(editText.isEmpty ? text : editText, editFontSize)
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }

                if let onDelete = onDelete {
                    Button {
                        onDelete()
                    } label: {
                        Label("מחק כותרת", systemImage: "trash")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(32)
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - Board tap context menu (create task / headline)

struct BoardTapMenu: View {
    let onDismiss: () -> Void
    let onCreateTask: () -> Void
    let onCreateHeadline: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 12) {
                Text("הוסף ללוח")
                    .font(.headline)
                    .padding(.bottom, 8)

                MenuButton(title: "משימה חדשה", icon: "plus.circle.fill", color: .blue) {
                    onCreateTask()
                }
                MenuButton(title: "כותרת חדשה", icon: "textformat.size", color: .orange) {
                    onCreateHeadline()
                }

                Button("ביטול") { onDismiss() }
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 48)
        }
    }
}

// MARK: - Connection delete menu

struct ConnectionDeleteMenu: View {
    let fromNode: Node?
    let toNode: Node?
    let onDismiss: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                Image(systemName: "arrow.forward")
                    .font(.system(size: 32))
                    .foregroundColor(Color(red: 0.7, green: 0.15, blue: 0.15))

                VStack(spacing: 6) {
                    Text(fromNode?.title ?? "?")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(toNode?.title ?? "?")
                        .font(.system(size: 16, weight: .semibold))
                }

                Button {
                    onDelete()
                } label: {
                    Label("מחק חיבור", systemImage: "trash")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 48)

                Button("ביטול") { onDismiss() }
                    .foregroundColor(.secondary)
            }
            .padding(32)
        }
    }
}

// MARK: - Quick add task sheet (from board long press)

struct BoardQuickAddSheet: View {
    @EnvironmentObject var service: SupabaseService
    @Environment(\.dismiss) var dismiss
    let canvasPosition: CGPoint

    @State private var title = ""
    @State private var coachType: CoachType = .weekly
    @State private var category: NodeCategory = .goals
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("שם") {
                    TextField("שם המשימה", text: $title)
                        .multilineTextAlignment(.trailing)
                        .focused($isFocused)
                }
                Section("סוג") {
                    Picker("סוג", selection: $coachType) {
                        ForEach(CoachType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("קטגוריה") {
                    Picker("קטגוריה", selection: $category) {
                        ForEach(NodeCategory.allCases, id: \.self) { c in
                            Text(c.label).tag(c)
                        }
                    }
                }
            }
            .navigationTitle("משימה חדשה")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("הוסף") {
                        let id = UUID().uuidString
                        let node = Node(id: id,
                                        title: title.trimmingCharacters(in: .whitespaces),
                                        category: category, coachType: coachType)
                        // Set position in memory first so initializePositions() won't overwrite it
                        service.positions[id] = canvasPosition
                        service.addNode(node)
                        service.savePosition(nodeId: id, position: canvasPosition)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}

// MARK: - Quick add free headline sheet

struct BoardQuickHeadlineSheet: View {
    @Environment(\.dismiss) var dismiss
    let canvasPosition: CGPoint
    let onCreate: (FreeLabel) -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("טקסט הכותרת") {
                    TextField("כותרת", text: $text)
                        .multilineTextAlignment(.trailing)
                        .focused($isFocused)
                }
            }
            .navigationTitle("כותרת חדשה")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("הוסף") {
                        let label = FreeLabel(
                            id: UUID().uuidString,
                            text: text.trimmingCharacters(in: .whitespaces),
                            x: Double(canvasPosition.x),
                            y: Double(canvasPosition.y),
                            fontSize: 20
                        )
                        onCreate(label)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
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
                case .first(true):         state = .pressing
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
        if let hex = node.customColor, let c = Color(hex: hex) { return c }
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
