import SwiftUI
import CoreLocation

private typealias Config = NotificationManager.ReminderConfig
private typealias RType  = NotificationManager.ReminderConfig.ReminderType

struct CardEditSheet: View {
    @EnvironmentObject var service: SupabaseService
    @Environment(\.dismiss) var dismiss

    let node: Node

    @State private var title: String
    @State private var status: NodeStatus
    @State private var size: CardSize
    @State private var link: String
    @State private var notes: String
    @State private var cardColor: Color
    @State private var photoFileNames: [String]
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var attachedFileNames: [String]
    @State private var showFilePicker = false

    // Reminder state
    @State private var hasReminder: Bool
    @State private var reminderType: RType
    @State private var reminderDate: Date
    @State private var reminderWeekdays: [Int]
    @State private var reminderHour: Int
    @State private var reminderMinute: Int
    @State private var locationName: String
    @State private var locationLat: Double?
    @State private var locationLon: Double?
    @State private var locationOnEntry: Bool
    @State private var reminderMonthDay: Int
    @State private var customDates: [Date]
    @State private var pendingCustomDate: Date = Date().addingTimeInterval(3600)
    @State private var isGeocoding = false
    @State private var geocodeError: String?

    init(node: Node) {
        self.node = node
        let cfg = node.id.flatMap { NotificationManager.shared.config(for: $0) }

        _title           = State(initialValue: node.title)
        _status          = State(initialValue: node.status)
        _size            = State(initialValue: node.cardSize)
        _link            = State(initialValue: node.link ?? "")
        _notes           = State(initialValue: node.notes ?? "")
        _cardColor       = State(initialValue: Color(hex: node.customColor ?? "") ?? Color(red: 0.98, green: 0.96, blue: 0.82))
        _photoFileNames  = State(initialValue: node.photoFileNames)
        _attachedFileNames = State(initialValue: node.attachedFileNames)

        _hasReminder     = State(initialValue: cfg != nil)
        _reminderType    = State(initialValue: cfg?.type ?? .once)
        _reminderDate    = State(initialValue: cfg?.date ?? Date().addingTimeInterval(3600))
        _reminderWeekdays = State(initialValue: cfg?.weekdays ?? [])
        _reminderHour    = State(initialValue: cfg?.hour ?? 9)
        _reminderMinute  = State(initialValue: cfg?.minute ?? 0)
        _locationName    = State(initialValue: cfg?.locationName ?? "")
        _locationLat     = State(initialValue: cfg?.latitude)
        _locationLon     = State(initialValue: cfg?.longitude)
        _locationOnEntry  = State(initialValue: cfg?.onEntry ?? true)
        _reminderMonthDay = State(initialValue: cfg?.monthDay ?? 28)
        _customDates      = State(initialValue: cfg?.customDates ?? [])
    }

    // MARK: - Connections

    var outgoing: [Connection] { node.connections }

    var incoming: [(node: Node, conn: Connection)] {
        service.nodes.compactMap { other in
            guard other.id != node.id,
                  let conn = other.connections.first(where: { $0.toId == node.id })
            else { return nil }
            return (other, conn)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {

                // Title
                Section("שם") {
                    TextField("שם המשימה", text: $title)
                        .multilineTextAlignment(.trailing)
                }

                // Status
                Section("סטטוס") {
                    Picker("סטטוס", selection: $status) {
                        ForEach(NodeStatus.allCases, id: \.self) { s in
                            Text("\(s.dot) \(s.label)").tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Size
                Section("גודל") {
                    Picker("גודל", selection: $size) {
                        ForEach(CardSize.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Color
                Section("צבע") {
                    ColorPicker("בחר צבע", selection: $cardColor, supportsOpacity: false)
                }

                // Link
                Section("לינק") {
                    TextField("https://...", text: $link)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .multilineTextAlignment(.trailing)
                }

                // Notes
                Section("הערות") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .multilineTextAlignment(.trailing)
                }

                // Photos
                Section("תמונות") {
                    if !photoFileNames.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(photoFileNames, id: \.self) { name in
                                    if let img = PhotoManager.load(name) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: img)
                                                .resizable().scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipped().cornerRadius(8)
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
                        Button { showPhotoPicker = true } label: { Label("ספרייה", systemImage: "photo.on.rectangle") }
                        Spacer()
                        Button { showCamera = true }     label: { Label("מצלמה",  systemImage: "camera") }
                    }
                }
                .sheet(isPresented: $showPhotoPicker) {
                    PhotoPicker { img in if let name = PhotoManager.save(img) { photoFileNames.append(name) } }
                }
                .sheet(isPresented: $showCamera) {
                    CameraPicker { img in if let name = PhotoManager.save(img) { photoFileNames.append(name) } }
                }

                // Files
                Section("קבצים") {
                    ForEach(attachedFileNames, id: \.self) { name in
                        HStack {
                            Image(systemName: name.contains(".pdf") ? "doc.fill" : "doc").foregroundColor(.red)
                            Text(name.components(separatedBy: "_").dropFirst().joined(separator: "_"))
                                .lineLimit(1).font(.footnote)
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
                    Button { showFilePicker = true } label: { Label("הוסף קובץ", systemImage: "paperclip") }
                }
                .sheet(isPresented: $showFilePicker) {
                    FilePicker { _, name in attachedFileNames.append(name) }
                }

                // Reminder
                reminderSection

                // Connections
                if !outgoing.isEmpty {
                    Section("יוצא מכאן →") {
                        ForEach(outgoing, id: \.toId) { conn in
                            if let target = service.node(byId: conn.toId) {
                                HStack {
                                    Circle().fill(Color(hex: conn.colorHex) ?? .red).frame(width: 10, height: 10)
                                    Text(target.title).foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.right").foregroundColor(.secondary)
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
                                Circle().fill(Color(hex: conn.colorHex) ?? .red).frame(width: 10, height: 10)
                                Text(other.title).foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.left").foregroundColor(.secondary)
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
                ToolbarItem(placement: .navigationBarLeading) { Button("ביטול") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("שמור") { save() }.fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Reminder section

    @ViewBuilder
    var reminderSection: some View {
        Section("תזכורת") {
            Toggle("הפעל תזכורת", isOn: $hasReminder.animation())

            if hasReminder {
                // Type picker
                Picker("סוג", selection: $reminderType) {
                    ForEach(RType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }

                // Type-specific UI
                switch reminderType {
                case .once:
                    DatePicker("תאריך ושעה", selection: $reminderDate, in: Date()...,
                               displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, Locale(identifier: "he"))

                case .weekly:
                    weekdayPicker
                    DatePicker("שעה", selection: weekdayTime,
                               displayedComponents: .hourAndMinute)
                    .environment(\.locale, Locale(identifier: "he"))

                case .monthly:
                    Stepper("יום בחודש: \(reminderMonthDay)", value: $reminderMonthDay, in: 1...28)
                    DatePicker("שעה", selection: weekdayTime,
                               displayedComponents: .hourAndMinute)
                    .environment(\.locale, Locale(identifier: "he"))

                case .location:
                    locationFields

                case .customDates:
                    customDatesFields
                }
            }
        }
    }

    // MARK: - Weekly day picker

    private let dayInfo: [(Int, String)] = [
        (1,"א"), (2,"ב"), (3,"ג"), (4,"ד"), (5,"ה"), (6,"ו"), (7,"ש")
    ]

    var weekdayPicker: some View {
        HStack(spacing: 8) {
            Spacer()
            ForEach(dayInfo, id: \.0) { weekday, label in
                let selected = reminderWeekdays.contains(weekday)
                Button {
                    if selected { reminderWeekdays.removeAll { $0 == weekday } }
                    else { reminderWeekdays.append(weekday) }
                } label: {
                    Text(label)
                        .font(.system(size: 15, weight: selected ? .bold : .regular))
                        .frame(width: 34, height: 34)
                        .background(selected ? Color.blue : Color(.systemGray5))
                        .foregroundColor(selected ? .white : .primary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // Binding that reads/writes hour+minute from a single Date
    var weekdayTime: Binding<Date> {
        Binding(
            get: {
                var comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
                comps.hour   = reminderHour
                comps.minute = reminderMinute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { date in
                let comps    = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderHour   = comps.hour   ?? 9
                reminderMinute = comps.minute ?? 0
            }
        )
    }

    // MARK: - Location fields

    var locationFields: some View {
        Group {
            HStack {
                TextField("שם מקום (לדוג' חדר כושר)", text: $locationName)
                    .multilineTextAlignment(.trailing)

                Button {
                    Task { await geocodeLocation() }
                } label: {
                    if isGeocoding {
                        ProgressView().frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                    }
                }
                .disabled(locationName.isEmpty || isGeocoding)
            }

            if let lat = locationLat, let lon = locationLon {
                HStack {
                    Spacer()
                    Label(String(format: "%.4f, %.4f", lat, lon), systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            if let err = geocodeError {
                Text(err).font(.caption).foregroundColor(.red)
            }

            Toggle("התראה בכניסה למיקום", isOn: $locationOnEntry)
        }
    }

    // MARK: - Custom dates fields

    var customDatesFields: some View {
        Group {
            if !customDates.isEmpty {
                ForEach(customDates.indices, id: \.self) { i in
                    HStack {
                        Text(formatDate(customDates[i]))
                            .font(.subheadline)
                        Spacer()
                        Button {
                            customDates.remove(at: i)
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            DatePicker("תאריך חדש", selection: $pendingCustomDate, in: Date()...,
                       displayedComponents: [.date, .hourAndMinute])
            .environment(\.locale, Locale(identifier: "he"))

            Button {
                customDates.append(pendingCustomDate)
                pendingCustomDate = Date().addingTimeInterval(3600)
            } label: {
                Label("הוסף תאריך", systemImage: "plus.circle.fill")
            }
        }
    }

    // MARK: - Save

    func save() {
        var updated = node
        updated.title             = title.trimmingCharacters(in: .whitespaces)
        updated.status            = status
        updated.cardSize          = size
        updated.link              = link.isEmpty  ? nil : link
        updated.notes             = notes.isEmpty ? nil : notes
        updated.customColor       = cardColor.hexString
        updated.photoFileNames    = photoFileNames
        updated.attachedFileNames = attachedFileNames
        service.updateNode(updated)

        guard let nodeId = updated.id else { dismiss(); return }

        if hasReminder {
            var cfg = Config(nodeId: nodeId, nodeTitle: updated.title, type: reminderType)
            switch reminderType {
            case .once:
                cfg.date = reminderDate
            case .weekly:
                cfg.weekdays = reminderWeekdays
                cfg.hour     = reminderHour
                cfg.minute   = reminderMinute
            case .monthly:
                cfg.monthDay = reminderMonthDay
                cfg.hour     = reminderHour
                cfg.minute   = reminderMinute
            case .location:
                cfg.locationName = locationName
                cfg.latitude     = locationLat
                cfg.longitude    = locationLon
                cfg.onEntry      = locationOnEntry
            case .customDates:
                cfg.customDates  = customDates
            }
            NotificationManager.shared.schedule(cfg)
        } else {
            NotificationManager.shared.cancel(nodeId: nodeId)
        }

        dismiss()
    }

    // MARK: - Helpers

    func geocodeLocation() async {
        guard !locationName.isEmpty else { return }
        isGeocoding  = true
        geocodeError = nil
        do {
            let coords   = try await NotificationManager.shared.geocode(address: locationName)
            locationLat  = coords.latitude
            locationLon  = coords.longitude
        } catch {
            geocodeError = "מיקום לא נמצא — נסה שם אחר"
        }
        isGeocoding = false
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM HH:mm"
        f.locale = Locale(identifier: "he")
        return f.string(from: date)
    }
}

