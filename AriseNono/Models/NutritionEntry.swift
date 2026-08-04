import Foundation
import SwiftData

@Model
final class NutritionEntry {
    var id: UUID
    var date: Date
    var firstMealTime: Date?
    var lastMealTime: Date?
    var hadOmega3: Bool
    var hadVitaminD: Bool
    var hadMagnesium: Bool
    var hadZinc: Bool
    var totalCalories: Int
    var totalProteinG: Double
    var totalCarbsG: Double
    var totalFatG: Double
    var totalFiberG: Double
    var addedSugarG: Double
    var adherenceScore: Double

    @Relationship(deleteRule: .cascade, inverse: \MealItem.entry)
    var meals: [MealItem]

    init(date: Date = Calendar.current.startOfDay(for: .now)) {
        self.id = UUID()
        self.date = date
        self.hadOmega3 = false
        self.hadVitaminD = false
        self.hadMagnesium = false
        self.hadZinc = false
        self.totalCalories = 0
        self.totalProteinG = 0
        self.totalCarbsG = 0
        self.totalFatG = 0
        self.totalFiberG = 0
        self.addedSugarG = 0
        self.adherenceScore = 0
        self.meals = []
    }

    var micronutrientCount: Int {
        [hadOmega3, hadVitaminD, hadMagnesium, hadZinc].filter { $0 }.count
    }

    var eatingWindowHours: Double? {
        guard let first = firstMealTime, let last = lastMealTime else { return nil }
        return last.timeIntervalSince(first) / 3600
    }

    func recompute(from meals: [MealItem]) {
        totalCalories  = meals.reduce(0) { $0 + $1.calories }
        totalProteinG  = meals.reduce(0) { $0 + $1.proteinG }
        totalCarbsG    = meals.reduce(0) { $0 + $1.carbsG }
        totalFatG      = meals.reduce(0) { $0 + $1.fatG }
        totalFiberG    = meals.reduce(0) { $0 + $1.fiberG }
        addedSugarG    = meals.reduce(0) { $0 + $1.addedSugarG }
        if let first = meals.map(\.loggedAt).min() { firstMealTime = first }
        if let last  = meals.map(\.loggedAt).max() { lastMealTime  = last }
    }
}
