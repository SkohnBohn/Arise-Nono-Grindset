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
