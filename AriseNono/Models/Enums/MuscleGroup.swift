import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, legs, shoulders, arms, core, cardio

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest:     return "Chest"
        case .back:      return "Back"
        case .legs:      return "Legs"
        case .shoulders: return "Shoulders"
        case .arms:      return "Arms"
        case .core:      return "Core"
        case .cardio:    return "Cardio"
        }
    }

    var systemImage: String {
        switch self {
        case .chest:     return "figure.strengthtraining.traditional"
        case .back:      return "figure.rowing"
        case .legs:      return "figure.run"
        case .shoulders: return "figure.arms.open"
        case .arms:      return "dumbbell"
        case .core:      return "bolt"
        case .cardio:    return "heart.fill"
        }
    }
}
