import Foundation
import SwiftData

@Model
final class MealItem {
    var id: UUID
    var name: String
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double
    var addedSugarG: Double
    var loggedAt: Date
    var entry: NutritionEntry?

    init(
        name: String,
        calories: Int,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        fiberG: Double = 0,
        addedSugarG: Double = 0,
        loggedAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
        self.addedSugarG = addedSugarG
        self.loggedAt = loggedAt
    }
}
