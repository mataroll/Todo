import Foundation

struct DailyLog: Identifiable {
    var id: String        // "yyyy-MM-dd" — set from doc.documentID
    var date: Date
    var exerciseProgress: Double
    var workProgress: Double
    var studyProgress: Double
    var hobbyProgress: Double
    var overallProgress: Double
    var isPerfect: Bool

    func progress(for category: HabitCategory) -> Double {
        switch category {
        case .exercise: return exerciseProgress
        case .work:     return workProgress
        case .study:    return studyProgress
        case .hobby:    return hobbyProgress
        case .none:     return 0
        }
    }

    static func from(id: String, data: [String: Any]) -> DailyLog? {
        let date = (data["date"] as? Date) ?? Date()
        return DailyLog(
            id: id,
            date: date,
            exerciseProgress: data["exerciseProgress"] as? Double ?? 0,
            workProgress:     data["workProgress"]     as? Double ?? 0,
            studyProgress:    data["studyProgress"]    as? Double ?? 0,
            hobbyProgress:    data["hobbyProgress"]    as? Double ?? 0,
            overallProgress:  data["overallProgress"]  as? Double ?? 0,
            isPerfect:        data["isPerfect"]        as? Bool   ?? false
        )
    }
}
