import SwiftUI
import EventKit

struct CardEditSheet: View {
    @EnvironmentObject var service: FirebaseService
    @Environment(\.dismiss) var dismiss

    let node: Node

    @State private var title: String
    @State private var status: NodeStatus
    @State private var size: CardSize
    @State private var link: String
    @State private var notes: String
    @State private var cardColor: Color
    @State private var reminderDate: Date
    @State private var hasReminder: Bool
    @State private var photoFileNames: [String]
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var attachedFileNames: [String]
    @State private var showFilePicker = false
    @State private var calendarMessage: String? = nil
    @State private var reminderMessage: String? = nil

    init(node: Node) {
        self.node = node
        _title          = State(initialValue: node.title)
        _status         = State(initialValue: node.status)
        _size           = State(initialValue: node.cardSize)
        _link           = State(initialValue: node.link ?? "")
        _notes          = State(initialValue: node.notes ?? "")
        _cardColor      = State(initialValue: Color(hex: node.customColor ?? "") ?? Color(red: 0.98, green: 0.96, blue: 0.82))
        _reminderDate      = State(initialValue: node.reminderDate ?? Date().addingTimeInterval(3600))
        _hasReminder       = State(initialValue: node.reminderDate != nil)
        _photoFileNames    = State(initialValue: node.photoFileNames)
        _attachedFileNames = State(initialValue: node.attachedFileNames)
    }

    // Connections where this node is the source (this → other)
    var outgoing: [Connection] {
        node.connections
    }

    // Connections where this node is the target (other → this)
    var incoming: [(node: Node, conn: Connection)] {
        service.nodes.compactMap { other in
            guard other.id != node.id,
                  let conn = other.connections.first(where: { $0.toId == node.id })
            else { return nil }
            return (other, conn)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("שם") {
                    TextField("שם המשימה", text: $title)
                        .multilineTextAlignment(.trailing)
                }

                Section("סטטוס") {
                    Picker("סטטוס", selection: $status) {
                        ForEach(NodeStatus.allCases, id: \.self) { s in
                            Text("\(s.dot) \(s.label)").tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("גודל") {
                    Picker("גודל", selection: $size) {
                        ForEach(CardSize.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("צבע כרטיסייה") {
                    ColorPicker("בחר צבע", selection: $cardColor, supportsOpacity: false)
                }

                Section("לינק") {
                    TextField("https://...", text: $link)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .multilineTextAlignment(.trailing)
                }

                Section("הערות") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .multilineTextAlignment(.trailing)
                }

                Section("תמונות") {
                    if !photoFileNames.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(photoFileNames, id: \.self) { name in
                                    if let img = PhotoManager.load(name) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipped()
                                                .cornerRadius(8)
                                            Button {
                                                PhotoManager.delete(name)
                                                photoFileNames.removeAll { $0 == name }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Color.white.clipShape(Circle()))
                                            }
                                            .offset(x: 4, y: -4)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    HStack {
                        Button { showPhotoPicker = true } label: {
                            Label("ספרייה", systemImage: "photo.on.rectangle")
                        }
                        Spacer()
                        Button { showCamera = true } label: {
                            Label("מצלמה", systemImage: "camera")
                        }
                    }
                }
                .sheet(isPresented: $showPhotoPicker) {
                    PhotoPicker { img in
                        if let name = PhotoManager.save(img) {
                            photoFileNames.append(name)
                        }
                    }
                }
                .sheet(isPresented: $showCamera) {
                    CameraPicker { img in
                        if let name = PhotoManager.save(img) {
                            photoFileNames.append(name)
                        }
                    }
                }

                Section("קבצים") {
                    ForEach(attachedFileNames, id: \.self) { name in
                        HStack {
                            Image(systemName: name.hasSuffix(".pdf") || name.contains(".pdf") ? "doc.fill" : "doc")
                                .foregroundColor(.red)
                            Text(name.components(separatedBy: "_").dropFirst().joined(separator: "_"))
                                .lineLimit(1)
                                .font(.footnote)
                            Spacer()
                        }
                        .swipeActions {
                            Button("מחק", role: .destructive) {
                                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                try? FileManager.default.removeItem(at: docs.appendingPathComponent(name))
                                attachedFileNames.removeAll { $0 == name }
                            }
                        }
                    }
                    Button { showFilePicker = true } label: {
                        Label("הוסף קובץ", systemImage: "paperclip")
                    }
                }
                .sheet(isPresented: $showFilePicker) {
                    FilePicker { _, name in attachedFileNames.append(name) }
                }

                Section("תזכורת") {
                    Toggle("הגדר תזכורת", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker("", selection: $reminderDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .environment(\.locale, Locale(identifier: "he"))
                    }
                }

                Section("תזכורות Apple") {
                    Button {
                        addToReminders()
                    } label: {
                        Label("הוסף לתזכורות", systemImage: "checklist")
                    }
                    if let msg = reminderMessage {
                        Text(msg)
                            .font(.footnote)
                            .foregroundColor(msg.contains("✓") ? .green : .red)
                    }
                }

                Section("יומן") {
                    Button {
                        addToCalendar()
                    } label: {
                        Label("הוסף ליומן Apple", systemImage: "calendar.badge.plus")
                    }
                    if let msg = calendarMessage {
                        Text(msg)
                            .font(.footnote)
                            .foregroundColor(msg.contains("✓") ? .green : .red)
                    }
                }

                if !outgoing.isEmpty {
                    Section("יוצא מכאן →") {
                        ForEach(outgoing, id: \.toId) { conn in
                            if let target = service.node(byId: conn.toId) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: conn.colorHex) ?? .red)
                                        .frame(width: 10, height: 10)
                                    Text(target.title)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.secondary)
                                }
                                .swipeActions {
                                    Button("מחק", role: .destructive) {
                                        service.removeConnection(from: node.id ?? "", to: conn.toId)
                                    }
                                }
                            }
                        }
                    }
                }

                if !incoming.isEmpty {
                    Section("נכנס לכאן ←") {
                        ForEach(incoming, id: \.node.id) { other, conn in
                            HStack {
                                Circle()
                                    .fill(Color(hex: conn.colorHex) ?? .red)
                                    .frame(width: 10, height: 10)
                                Text(other.title)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.left")
                                    .foregroundColor(.secondary)
                            }
                            .swipeActions {
                                Button("מחק", role: .destructive) {
                                    service.removeConnection(from: other.id ?? "", to: node.id ?? "")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("עריכה")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, .rightToLeft)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("שמור") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    func addToReminders() {
        let store = EKEventStore()
        store.requestFullAccessToReminders { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    reminderMessage = "❌ אין גישה לתזכורות"
                    return
                }
                let reminder = EKReminder(eventStore: store)
                reminder.title = title.isEmpty ? node.title : title
                reminder.notes = notes.isEmpty ? nil : notes
                reminder.calendar = store.defaultCalendarForNewReminders()
                if hasReminder {
                    let alarm = EKAlarm(absoluteDate: reminderDate)
                    reminder.addAlarm(alarm)
                    let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                    reminder.dueDateComponents = comps
                }
                do {
                    try store.save(reminder, commit: true)
                    reminderMessage = "✓ נוסף לתזכורות"
                } catch {
                    reminderMessage = "❌ שגיאה: \(error.localizedDescription)"
                }
            }
        }
    }

    func addToCalendar() {
        let store = EKEventStore()
        store.requestFullAccessToEvents { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    calendarMessage = "❌ אין גישה ליומן"
                    return
                }
                let event = EKEvent(eventStore: store)
                event.title = title.isEmpty ? node.title : title
                event.notes = notes.isEmpty ? nil : notes
                let start = hasReminder ? reminderDate : Date().addingTimeInterval(3600)
                event.startDate = start
                event.endDate = start.addingTimeInterval(3600)
                event.calendar = store.defaultCalendarForNewEvents
                do {
                    try store.save(event, span: .thisEvent)
                    calendarMessage = "✓ נוסף ליומן"
                } catch {
                    calendarMessage = "❌ שגיאה: \(error.localizedDescription)"
                }
            }
        }
    }

    func save() {
        var updated = node
        updated.title       = title.trimmingCharacters(in: .whitespaces)
        updated.status      = status
        updated.cardSize    = size
        updated.link        = link.isEmpty ? nil : link
        updated.notes       = notes.isEmpty ? nil : notes
        updated.customColor = cardColor.hexString
        updated.reminderDate      = hasReminder ? reminderDate : nil
        updated.photoFileNames    = photoFileNames
        updated.attachedFileNames = attachedFileNames
        service.updateNode(updated)
        dismiss()
    }
}
