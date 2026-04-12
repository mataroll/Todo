import Foundation
import SwiftUI

enum NodeStatus: String, Codable, CaseIterable {
    case blocked, open, inProgress, done

    var label: String {
        switch self {
        case .blocked:    return "חסום"
        case .open:       return "פתוח"
        case .inProgress: return "בתהליך"
        case .done:       return "הושלם"
        }
    }

    var dot: String {
        switch self {
        case .blocked:    return "⚫"
        case .open:       return "🟡"
        case .inProgress: return "🟢"
        case .done:       return "✅"
        }
    }

    var sortOrder: Int {
        switch self {
        case .inProgress: return 0
        case .open:       return 1
        case .blocked:    return 2
        case .done:       return 3
        }
    }
}

enum NodeCategory: String, Codable, CaseIterable {
    case keyBlockers, goals, doctors, friends, creative, tech, purchases, recurring, dreams, reminders, oneTime

    var label: String {
        switch self {
        case .keyBlockers: return "חוסמים מרכזיים"
        case .goals:       return "מטרות"
        case .doctors:     return "רופאים"
        case .friends:     return "חברים"
        case .creative:    return "פרויקטים יצירתיים"
        case .tech:        return "טכנולוגיה"
        case .purchases:   return "רכישות"
        case .recurring:   return "חוזרים"
        case .dreams:      return "חלומות"
        case .reminders:   return "תזכורות"
        case .oneTime:     return "חד פעמי"
        }
    }

    var sortOrder: Int {
        switch self {
        case .keyBlockers: return 0
        case .goals:       return 1
        case .doctors:     return 2
        case .friends:     return 3
        case .creative:    return 4
        case .tech:        return 5
        case .purchases:   return 6
        case .recurring:   return 7
        case .dreams:      return 8
        case .reminders:   return 9
        case .oneTime:     return 10
        }
    }
}

enum CardSize: String, Codable, CaseIterable {
    case small, medium, large

    var label: String {
        switch self {
        case .small:  return "S"
        case .medium: return "M"
        case .large:  return "L"
        }
    }

    var cardWidth: CGFloat {
        switch self {
        case .small:  return 120
        case .medium: return 160
        case .large:  return 220
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small:  return 10
        case .medium: return 12
        case .large:  return 14
        }
    }
}

enum HabitCategory: String, Codable, CaseIterable {
    case exercise, work, study, hobby, none

    var label: String {
        switch self {
        case .exercise: return "ספורט"
        case .work:     return "עבודה"
        case .study:    return "לימודים"
        case .hobby:    return "תחביב"
        case .none:     return "ללא"
        }
    }

    var icon: String {
        switch self {
        case .exercise: return "🏃"
        case .work:     return "💻"
        case .study:    return "📖"
        case .hobby:    return "🎹"
        case .none:     return ""
        }
    }

    var color: Color {
        switch self {
        case .exercise: return .green
        case .work:     return .blue
        case .study:    return .orange
        case .hobby:    return .purple
        case .none:     return .gray
        }
    }
}

enum CoachType: String, Codable, CaseIterable {
    case daily, weekly, yearly, budget, none

    var color: Color {
        switch self {
        case .daily:  return .blue
        case .weekly: return .green
        case .yearly: return .orange
        case .budget: return .yellow
        case .none:   return .gray
        }
    }
}

struct Node: Identifiable, Codable, Equatable {
    var id: String?
    var title: String
    var category: NodeCategory
    var status: NodeStatus
    var coachType: CoachType
    var dependencies: [String]
    var connections: [Connection]
    var notes: String?
    var link: String?
    var photoURL: String?
    var createdAt: Date
    var completedAt: Date?
    var priority: Int
    var type: String
    var cardSize: CardSize
    var customColor: String?
    var reminderDate: Date?
    var photoFileNames: [String]
    var attachedFileNames: [String]
    var price: Double?
    var startTime: Date?
    var endTime: Date?
    var isConfirmed: Bool
    var habitCategory: HabitCategory

    init(id: String? = nil, title: String, category: NodeCategory, status: NodeStatus = .open,
         coachType: CoachType = .none, dependencies: [String] = [], notes: String? = nil,
         link: String? = nil, priority: Int = 0, type: String = "task", cardSize: CardSize = .medium,
         customColor: String? = nil, price: Double? = nil, startTime: Date? = nil,
         endTime: Date? = nil, isConfirmed: Bool = false, habitCategory: HabitCategory = .none) {
        self.id = id
        self.title = title
        self.category = category
        self.status = status
        self.coachType = coachType
        self.dependencies = dependencies
        self.connections = []
        self.notes = notes
        self.link = link
        self.priority = priority
        self.type = type
        self.cardSize = cardSize
        self.customColor = customColor
        self.price = price
        self.startTime = startTime
        self.endTime = endTime
        self.isConfirmed = isConfirmed
        self.habitCategory = habitCategory
        self.photoFileNames = []
        self.attachedFileNames = []
        self.createdAt = Date()
    }
}

struct Connection: Codable, Equatable {
    var toId: String
    var colorHex: String

    init(toId: String, colorHex: String = "#CC1111") {
        self.toId = toId
        self.colorHex = colorHex
    }
}
