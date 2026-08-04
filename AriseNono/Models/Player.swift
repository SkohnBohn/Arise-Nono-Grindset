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

    // Nutrition goals
    var goalCalories: Int
    var goalProteinG: Double
    var goalFiberG: Double
    var goalEatingWindowH: Int
    var goalMaxSugarG: Double

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

        // Blueprint-inspired defaults
        let kg = bodyweightKg ?? 75.0
        self.goalCalories = 2000
        self.goalProteinG = kg * 1.5
        self.goalFiberG = 50
        self.goalEatingWindowH = 12
        self.goalMaxSugarG = 15
    }

    var xpForCurrentLevel: Int { LevelCurve.cumulativeXP(forLevel: level) }
    var xpForNextLevel: Int    { LevelCurve.xpRequired(toReach: level + 1) }
    var xpProgressInLevel: Int { totalXP - xpForCurrentLevel }
    var levelFraction: Double  { Double(xpProgressInLevel) / Double(max(xpForNextLevel, 1)) }
}
