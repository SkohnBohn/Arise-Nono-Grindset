import Foundation

enum QuestCategory: String, Codable, CaseIterable, Identifiable {
    case strength, cardio, consistency

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength:    return "Strength"
        case .cardio:      return "Cardio"
        case .consistency: return "Consistency"
        }
    }
}
