import Foundation

struct SeedData {
    static func seed(into service: SupabaseService) {
        let nodes = getSeedNodes()
        for node in nodes {
            service.addNode(node)
        }
    }

    static func getSeedNodes() -> [Node] {
        var list: [Node] = []

        // Helper to convert category string to enum
        func cat(_ s: String) -> NodeCategory {
            NodeCategory(rawValue: s) ?? .oneTime
        }
        
        // Helper to convert status string to enum
        func stat(_ s: String) -> NodeStatus {
            NodeStatus(rawValue: s) ?? .open
        }

        // KEY BLOCKERS
        list += [
            Node(id: "dad_talk", title: "דיבור עם אבא", category: cat("keyBlockers"), status: stat("open"), coachType: .weekly, notes: "שיחה אחת שפותחת: רופאים, שחייה, דירה, כירופרקט, תלתלים, ארסנל, כותל, אתרים, Apple Watch, כרית גב", priority: 1),
            Node(id: "haifa", title: "חיפה", category: cat("keyBlockers"), status: stat("open"), coachType: .weekly, notes: "אירוע אישי חד פעמי. פותח את כל מפגשי החברים", priority: 2),
            Node(id: "citron", title: "ציטרון", category: cat("keyBlockers"), status: stat("open"), coachType: .weekly, notes: "אירוע אישי חד פעמי. פותח: צמידים מוארים, פרויקטים יצירתיים", priority: 3),
            Node(id: "learning_curve", title: "עקומת למידה", category: cat("keyBlockers"), status: stat("inProgress"), coachType: .weekly, notes: "אינפי 1 → אינפי 2 → אלגברה לינארית → ... → חזרה לטכניון → הנדסה כימית. כרגע: אינפי 1", priority: 4, startTime: Date(), endTime: Date().addingTimeInterval(7200)),
            Node(id: "run_streak", title: "ריצה 90 יום", category: cat("keyBlockers"), status: stat("inProgress"), coachType: .daily, notes: "רצף ריצה. נדרש לפתוח שחייה", priority: 5, startTime: Date().addingTimeInterval(14400), endTime: Date().addingTimeInterval(18000)),
        ]

        // GOALS
        list += [
            Node(id: "move_apt", title: "מעבר דירה", category: cat("goals"), status: stat("blocked"), coachType: .weekly, dependencies: ["dad_talk"], priority: 10),
            Node(id: "swimming", title: "ללמוד לשחות", category: cat("goals"), status: stat("blocked"), coachType: .weekly, dependencies: ["dad_talk", "run_streak"], priority: 11),
            Node(id: "calisthenics", title: "קליסתניס", category: cat("goals"), status: stat("blocked"), coachType: .weekly, dependencies: ["run_streak"], priority: 12),
            Node(id: "techion", title: "חזרה לטכניון / הנדסה כימית", category: cat("dreams"), status: stat("blocked"), coachType: .weekly, dependencies: ["learning_curve"], priority: 13),
        ]

        // ... (rest of categories)
        
        // PURCHASES
        let purchases = [
            ("pants_poof", "מכנסיים ופוף", 250.0), ("socket", "שקע ותקע", 50.0), ("teeth_white", "הלבנת שיניים", 600.0),
            ("nike_shorts", "נייק מכנסי ספורט", 180.0), ("dental_kit", "מדבקות הלבנה וסילון מים דנטלי", 350.0),
        ]
        for (i, p) in purchases.enumerated() {
            list.append(Node(id: p.0, title: p.1, category: cat("purchases"), status: stat("open"), coachType: .budget, priority: 100 + i, type: "purchase", price: p.2))
        }

        // RECURRING (Habits)
        list += [
            Node(id: "clean_photos", title: "לנקות תמונות", category: cat("recurring"), status: stat("open"), coachType: .daily, priority: 300, isConfirmed: false),
            Node(id: "piano_practice", title: "פסנתר", category: cat("recurring"), status: stat("open"), coachType: .daily, priority: 301, startTime: Date().addingTimeInterval(21600), endTime: Date().addingTimeInterval(25200), isConfirmed: true),
            Node(id: "haircut", title: "להסתפר", category: cat("recurring"), status: stat("open"), coachType: .weekly, priority: 302),
        ]

        // DREAMS
        list += [
            Node(id: "skydiving", title: "צניחה חופשית", category: cat("dreams"), status: stat("open"), priority: 400),
        ]

        // REMINDERS
        list += [
            Node(id: "arsenal_july", title: "להתכונן לארסנל", category: cat("reminders"), status: stat("open"), notes: "July 1, 2026", priority: 500),
            Node(id: "zara_delivery", title: "לדבר עם Zara על משלוח", category: cat("reminders"), status: stat("open"), priority: 501),
            Node(id: "luna_visit", title: "לבקר את לונה ובתרונות רוחמה", category: cat("reminders"), status: stat("open"), notes: "מחכה לשבת שמש", priority: 502),
        ]

        return list
    }
}
