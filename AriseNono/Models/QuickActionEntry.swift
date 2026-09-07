import Foundation
import SwiftData

@Model
final class QuickActionEntry {
    var id: UUID
    var date: Date
    var actionID: String

    init(date: Date = .now, actionID: String) {
        self.id = UUID()
        self.date = date
        self.actionID = actionID
    }

    var activityType: ActivityType? {
        switch actionID {
        case "stretch": return .stretching
        case "cardio":  return .cardio
        case "burst":   return nil
        case "back":    return .back
        case "sleep":   return .sleep
        case "water":   return .water
        default:        return nil
        }
    }
}
