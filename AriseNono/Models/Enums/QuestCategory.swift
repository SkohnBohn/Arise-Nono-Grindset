import Foundation

enum QuestCategory: String, Codable, CaseIterable, Identifiable {
    case strength, cardio, nutrition, consistency

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength:    return "Strength"
        case .cardio:      return "Cardio"
        case .nutrition:   return "Nutrition"
        case .consistency: return "Consistency"
        }
    }
}
