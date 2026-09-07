import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var name: String
    var totalXP: Int
    var level: Int
    var rankTier: RankTier
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?
    var auraScore: Double
    var streakFreezeBalance: Int
    var bodyweightKg: Double?

    // Weekly activity goals (days per week)
    var goalStrengthDays: Int = 2
    var goalCardioDays: Int = 5
    var goalStretchDays: Int = 3
    var goalBackDays: Int = 6
    var goalSleepDays: Int = 6
    var goalWaterDays: Int = 6

    func goal(for type: ActivityType) -> Int {
        switch type {
        case .strength:   return goalStrengthDays
        case .cardio:     return goalCardioDays
        case .stretching: return goalStretchDays
        case .back:       return goalBackDays
        case .sleep:      return goalSleepDays
        case .water:      return goalWaterDays
        }
    }

    init(name: String, bodyweightKg: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.totalXP = 0
        self.level = 0
        self.rankTier = .unranked
        self.currentStreak = 0
        self.longestStreak = 0
        self.auraScore = 0
        self.streakFreezeBalance = 0
        self.bodyweightKg = bodyweightKg
    }

    var xpForCurrentLevel: Int { LevelCurve.cumulativeXP(forLevel: level) }
    var xpForNextLevel: Int    { LevelCurve.xpRequired(toReach: level + 1) }
    var xpProgressInLevel: Int { totalXP - xpForCurrentLevel }
    var levelFraction: Double  { Double(xpProgressInLevel) / Double(max(xpForNextLevel, 1)) }
}
