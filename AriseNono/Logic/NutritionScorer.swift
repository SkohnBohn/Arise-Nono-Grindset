import Foundation

struct NutritionGoals {
    var calories: Int
    var proteinG: Double
    var fiberG: Double
    var maxSugarG: Double
    var eatingWindowHours: Int
}

struct NutritionDayData {
    var totalCalories: Int
    var totalProteinG: Double
    var totalFiberG: Double
    var addedSugarG: Double
    var eatingWindowHours: Double?
}

enum NutritionScorer {
    static func adherenceScore(day: NutritionDayData, goals: NutritionGoals) -> Double {
        let cal     = calorieScore(actual: day.totalCalories, goal: goals.calories)
        let protein = ratioScore(actual: day.totalProteinG, goal: goals.proteinG)
        let fiber   = ratioScore(actual: day.totalFiberG,   goal: goals.fiberG)
        let sugar   = invertedScore(actual: day.addedSugarG, limit: goals.maxSugarG)
        let window  = windowScore(actual: day.eatingWindowHours, goal: Double(goals.eatingWindowHours))

        return cal     * 0.20
             + protein * 0.30
             + fiber   * 0.25
             + sugar   * 0.15
             + window  * 0.10
    }

    private static func calorieScore(actual: Int, goal: Int) -> Double {
        let ratio = Double(actual) / Double(max(goal, 1))
        let dev = abs(ratio - 1.0)
        if dev <= 0.10 { return 1.0 }
        return max(0, 1.0 - (dev - 0.10) / 0.40)
    }

    private static func ratioScore(actual: Double, goal: Double) -> Double {
        min(actual / max(goal, 1), 1.0)
    }

    private static func invertedScore(actual: Double, limit: Double) -> Double {
        guard actual > limit else { return 1.0 }
        return max(0, 1.0 - (actual - limit) / max(limit, 1))
    }

    private static func windowScore(actual: Double?, goal: Double) -> Double {
        guard let actual else { return 0.5 }
        guard actual > goal else { return 1.0 }
        return max(0, 1.0 - (actual - goal) / 4.0)
    }
}
