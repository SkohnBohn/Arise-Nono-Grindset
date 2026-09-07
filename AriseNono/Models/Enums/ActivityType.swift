import SwiftUI

enum ActivityType: String, CaseIterable, Identifiable {
    case strength   = "strength"
    case cardio     = "cardio"
    case stretching = "stretching"
    case back       = "back"
    case sleep      = "sleep"
    case water      = "water"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .strength:   return Color(hex: "00CFEE")
        case .cardio:     return Color(hex: "B82CF5")
        case .stretching: return Color(hex: "00D46A")
        case .back:       return Color(hex: "FF8A00")
        case .sleep:      return Color(hex: "9B6DFF")
        case .water:      return Color(hex: "1EB6FF")
        }
    }

    var label: String {
        switch self {
        case .strength:   return "STRENGTH"
        case .cardio:     return "CARDIO"
        case .stretching: return "STRETCHING"
        case .back:       return "BACK PAIN"
        case .sleep:      return "SLEEP"
        case .water:      return "WATER (1L)"
        }
    }

    var shortLabel: String {
        switch self {
        case .strength:   return "Strength"
        case .cardio:     return "Cardio"
        case .stretching: return "Stretch"
        case .back:       return "Back"
        case .sleep:      return "Sleep"
        case .water:      return "Water"
        }
    }

    var icon: String {
        switch self {
        case .strength:   return "dumbbell.fill"
        case .cardio:     return "figure.run"
        case .stretching: return "figure.flexibility"
        case .back:       return "figure.core.training"
        case .sleep:      return "moon.zzz.fill"
        case .water:      return "drop.fill"
        }
    }
}
