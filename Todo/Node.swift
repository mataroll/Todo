import Foundation
import FirebaseFirestore

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

struct Node: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var title: String
    var category: NodeCategory
    var status: NodeStatus
    var dependencies: [String]          // kept for backwards compat / blocking logic
    var connections: [Connection]        // rich connections with color
    var notes: String?
    var link: String?
    var photoURL: String?
    var createdAt: Date
    var completedAt: Date?
    var priority: Int
    var type: String
    var cardSize: CardSize
    var customColor: String?             // hex e.g. "#F5E6C8"

    init(id: String? = nil, title: String, category: NodeCategory, status: NodeStatus = .open, dependencies: [String] = [], notes: String? = nil, link: String? = nil, priority: Int = 0, type: String = "task", cardSize: CardSize = .medium, customColor: String? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.status = status
        self.dependencies = dependencies
        self.connections = []
        self.notes = notes
        self.link = link
        self.priority = priority
        self.type = type
        self.cardSize = cardSize
        self.customColor = customColor
        self.createdAt = Date()
    }
}

struct Connection: Codable, Equatable {
    var toId: String         // the node this line points TO
    var colorHex: String     // e.g. "#CC1111"

    init(toId: String, colorHex: String = "#CC1111") {
        self.toId = toId
        self.colorHex = colorHex
    }
}
