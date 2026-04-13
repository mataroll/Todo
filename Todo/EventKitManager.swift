import EventKit
import Foundation
import UIKit

@MainActor
class EventKitManager {
    static let shared = EventKitManager()
    let store = EKEventStore()
    private let defaults = UserDefaults.standard

    // MARK: - Permissions

    func requestPermissions() async {
        _ = try? await store.requestFullAccessToReminders()
        _ = try? await store.requestFullAccessToEvents()
    }

    // MARK: - Dedicated "Coach" containers

    var coachRemindersList: EKCalendar {
        if let existing = store.calendars(for: .reminder).first(where: { $0.title == "Coach" }) {
            return existing
        }
        let cal = EKCalendar(for: .reminder, eventStore: store)
        cal.title = "Coach"
        cal.cgColor = UIColor.systemBlue.cgColor
        cal.source = bestSource(for: .reminder) ?? store.defaultCalendarForNewReminders()?.source
        if let source = cal.source {
            cal.source = source
            try? store.saveCalendar(cal, commit: true)
        }
        return store.calendars(for: .reminder).first(where: { $0.title == "Coach" })
            ?? store.defaultCalendarForNewReminders()!
    }

    var coachEventCalendar: EKCalendar {
        if let existing = store.calendars(for: .event).first(where: { $0.title == "Coach" }) {
            return existing
        }
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = "Coach"
        cal.cgColor = UIColor.systemBlue.cgColor
        if let source = bestSource(for: .event) {
            cal.source = source
            try? store.saveCalendar(cal, commit: true)
        }
        return store.calendars(for: .event).first(where: { $0.title == "Coach" })
            ?? store.defaultCalendarForNewEvents!
    }

    private func bestSource(for type: EKEntityType) -> EKSource? {
        let preferred: [EKSourceType] = [.calDAV, .exchange, .local]
        for pref in preferred {
            if let src = store.sources.first(where: { $0.sourceType == pref }) { return src }
        }
        return store.sources.first
    }

    // MARK: - UserDefaults keys

    private func reminderKey(_ nodeId: String) -> String { "ek_reminder_\(nodeId)" }
    private func eventKey(_ nodeId: String) -> String { "ek_event_\(nodeId)" }

    // MARK: - Reminders

    func syncReminder(for node: Node) {
        guard let nodeId = node.id, let date = node.reminderDate else { return }
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        if let existingId = defaults.string(forKey: reminderKey(nodeId)),
           let existing = store.calendarItem(withIdentifier: existingId) as? EKReminder {
            existing.title = node.title
            existing.notes = node.notes
            existing.dueDateComponents = comps
            existing.alarms = [EKAlarm(absoluteDate: date)]
            try? store.save(existing, commit: true)
        } else {
            let reminder = EKReminder(eventStore: store)
            reminder.title = node.title
            reminder.notes = node.notes
            reminder.calendar = coachRemindersList
            reminder.dueDateComponents = comps
            reminder.addAlarm(EKAlarm(absoluteDate: date))
            if (try? store.save(reminder, commit: true)) != nil {
                defaults.set(reminder.calendarItemIdentifier, forKey: reminderKey(nodeId))
            }
        }
    }

    func deleteReminder(for nodeId: String) {
        guard let id = defaults.string(forKey: reminderKey(nodeId)),
              let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else { return }
        try? store.remove(reminder, commit: true)
        defaults.removeObject(forKey: reminderKey(nodeId))
    }

    // MARK: - Calendar Events

    func syncEvent(for node: Node, start: Date, end: Date) {
        guard let nodeId = node.id else { return }

        if let existingId = defaults.string(forKey: eventKey(nodeId)),
           let existing = store.event(withIdentifier: existingId) {
            existing.title = node.title
            existing.notes = node.notes
            existing.startDate = start
            existing.endDate = end
            try? store.save(existing, span: .thisEvent)
        } else {
            let event = EKEvent(eventStore: store)
            event.title = node.title
            event.notes = node.notes
            event.startDate = start
            event.endDate = end
            event.calendar = coachEventCalendar
            if (try? store.save(event, span: .thisEvent)) != nil {
                defaults.set(event.eventIdentifier, forKey: eventKey(nodeId))
            }
        }
    }

    func deleteEvent(for nodeId: String) {
        guard let id = defaults.string(forKey: eventKey(nodeId)),
              let event = store.event(withIdentifier: id) else { return }
        try? store.remove(event, span: .thisEvent)
        defaults.removeObject(forKey: eventKey(nodeId))
    }

    // MARK: - Helpers

    func hasReminder(for nodeId: String) -> Bool {
        defaults.string(forKey: reminderKey(nodeId)) != nil
    }

    func hasEvent(for nodeId: String) -> Bool {
        defaults.string(forKey: eventKey(nodeId)) != nil
    }
}
