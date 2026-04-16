import Foundation
import UserNotifications
import CoreLocation

// MARK: - In-app reminder system using local UNUserNotificationCenter.
// Configs stored in UserDefaults — no Supabase schema change needed.

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    private let defaults = UserDefaults.standard

    // MARK: - Config model

    struct ReminderConfig: Codable {
        enum ReminderType: String, Codable, CaseIterable {
            case once        = "פעם אחת"
            case weekly      = "שבועי"
            case monthly     = "חודשי"
            case location    = "לפי מיקום"
            case customDates = "תאריכים"
        }

        var nodeId: String
        var nodeTitle: String
        var type: ReminderType = .once

        // once
        var date: Date?

        // weekly / monthly
        var weekdays: [Int] = []   // 1=Sun … 7=Sat (UNCalendar weekday numbering)
        var monthDay: Int   = 28   // day of month for monthly repeat (1–28)
        var hour: Int       = 9
        var minute: Int     = 0

        // location
        var locationName: String   = ""
        var latitude: Double?
        var longitude: Double?
        var locationRadius: Double = 300   // meters
        var onEntry: Bool          = true  // true = arriving, false = leaving

        // customDates
        var customDates: [Date] = []
    }

    // MARK: - Storage helpers

    private func storageKey(_ nodeId: String) -> String { "notif_\(nodeId)" }

    func config(for nodeId: String) -> ReminderConfig? {
        guard let data = defaults.data(forKey: storageKey(nodeId)) else { return nil }
        return try? JSONDecoder().decode(ReminderConfig.self, from: data)
    }

    func hasConfig(for nodeId: String) -> Bool { config(for: nodeId) != nil }

    private func persist(_ config: ReminderConfig) {
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: storageKey(config.nodeId))
        }
    }

    // MARK: - Schedule

    func schedule(_ config: ReminderConfig) {
        cancel(nodeId: config.nodeId)   // wipe old requests first

        let content = UNMutableNotificationContent()
        content.title = config.nodeTitle
        content.body  = "הגיע הזמן ✓"
        content.sound = .default
        content.userInfo = ["nodeId": config.nodeId]

        switch config.type {

        case .once:
            guard let date = config.date, date > Date() else { return }
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            add(id: "\(config.nodeId)_once",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))

        case .weekly:
            guard !config.weekdays.isEmpty else { return }
            for day in config.weekdays {
                var comps = DateComponents()
                comps.weekday = day
                comps.hour    = config.hour
                comps.minute  = config.minute
                add(id: "\(config.nodeId)_w\(day)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true))
            }

        case .location:
            guard let lat = config.latitude, let lon = config.longitude else { return }
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                radius: config.locationRadius,
                identifier: config.nodeId
            )
            region.notifyOnEntry = config.onEntry
            region.notifyOnExit  = !config.onEntry
            add(id: "\(config.nodeId)_loc",
                content: content,
                trigger: UNLocationNotificationTrigger(region: region, repeats: true))

        case .monthly:
            var comps = DateComponents()
            comps.day    = config.monthDay
            comps.hour   = config.hour
            comps.minute = config.minute
            add(id: "\(config.nodeId)_monthly",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true))

        case .customDates:
            for (i, date) in config.customDates.enumerated() where date > Date() {
                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                add(id: "\(config.nodeId)_cd\(i)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            }
        }

        persist(config)
    }

    func cancel(nodeId: String) {
        var ids = ["\(nodeId)_once", "\(nodeId)_loc", "\(nodeId)_monthly"]
        ids += (1...7).map    { "\(nodeId)_w\($0)" }
        ids += (0...49).map   { "\(nodeId)_cd\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        defaults.removeObject(forKey: storageKey(nodeId))
    }

    // MARK: - Reschedule all on launch

    func rescheduleAll() {
        let prefix = "notif_"
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            guard let data = defaults.data(forKey: key),
                  let cfg  = try? JSONDecoder().decode(ReminderConfig.self, from: data)
            else { continue }
            schedule(cfg)
        }
    }

    // MARK: - Geocode helper (async)

    func geocode(address: String) async throws -> CLLocationCoordinate2D {
        let placemarks = try await CLGeocoder().geocodeAddressString(address)
        guard let loc = placemarks.first?.location?.coordinate else {
            throw NSError(domain: "NotificationManager", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Address not found"])
        }
        return loc
    }

    // MARK: - Private

    private func add(id: String, content: UNNotificationContent, trigger: UNNotificationTrigger) {
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { err in
            if let err { print("Notification error: \(err)") }
        }
    }
}
