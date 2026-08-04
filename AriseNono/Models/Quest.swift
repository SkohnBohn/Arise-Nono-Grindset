import Foundation
import SwiftData

@Model
final class Quest {
    var id: UUID
    var templateID: String
    var type: QuestType
    var category: QuestCategory
    var title: String
    var questDescription: String
    var targetValue: Double
    var currentValue: Double
    var xpReward: Int
    var isCompleted: Bool
    var completedAt: Date?
    var expiresAt: Date
    var rewardType: QuestRewardType

    init(
        templateID: String,
        type: QuestType,
        category: QuestCategory,
        title: String,
        description: String,
        targetValue: Double,
        xpReward: Int,
        rewardType: QuestRewardType = .xp,
        expiresAt: Date
    ) {
        self.id = UUID()
        self.templateID = templateID
        self.type = type
        self.category = category
        self.title = title
        self.questDescription = description
        self.targetValue = targetValue
        self.currentValue = 0
        self.xpReward = xpReward
        self.isCompleted = false
        self.expiresAt = expiresAt
        self.rewardType = rewardType
    }

    var progressFraction: Double {
        guard targetValue > 0 else { return isCompleted ? 1 : 0 }
        return min(currentValue / targetValue, 1.0)
    }

    var isExpired: Bool { !isCompleted && Date.now > expiresAt }
    var isActive: Bool  { !isCompleted && !isExpired }
}
