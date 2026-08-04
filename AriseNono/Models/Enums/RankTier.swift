import Foundation

enum RankTier: String, Codable, CaseIterable, Identifiable {
    case unranked, iron, bronze, silver, gold, platinum, diamond, awakened

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unranked:  return "Unranked"
        case .iron:      return "Iron"
        case .bronze:    return "Bronze"
        case .silver:    return "Silver"
        case .gold:      return "Gold"
        case .platinum:  return "Platinum"
        case .diamond:   return "Diamond"
        case .awakened:  return "Awakened"
        }
    }

    var minimumLevel: Int {
        switch self {
        case .unranked:  return 0
        case .iron:      return 5
        case .bronze:    return 15
        case .silver:    return 30
        case .gold:      return 50
        case .platinum:  return 75
        case .diamond:   return 100
        case .awakened:  return 150
        }
    }

    static func tier(for level: Int) -> RankTier {
        if level >= 150 { return .awakened }
        if level >= 100 { return .diamond }
        if level >= 75  { return .platinum }
        if level >= 50  { return .gold }
        if level >= 30  { return .silver }
        if level >= 15  { return .bronze }
        if level >= 5   { return .iron }
        return .unranked
    }
}
