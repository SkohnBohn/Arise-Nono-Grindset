import Foundation

struct AuraInput {
    var activeDays30: Int          // days with any log in last 30 days
    var currentStreak: Int
    var uniqueMuscleGroups14d: Int // distinct groups in last 14 days (0–7)
    var avgNutritionAdherence7d: Double // 0–1 average
}

enum AuraCalculator {
    static func compute(input: AuraInput) -> Double {
        let consistency = consistencyScore(activeDays: input.activeDays30, streak: input.currentStreak)
        let variety     = varietyScore(uniqueGroups: input.uniqueMuscleGroups14d)
        let nutrition   = min(max(input.avgNutritionAdherence7d, 0), 1.0)

        return (consistency * 0.40 + variety * 0.25 + nutrition * 0.35) * 1000
    }

    private static func consistencyScore(activeDays: Int, streak: Int) -> Double {
        let base = Double(min(activeDays, 30)) / 30.0
        // Streak pushes the score above the raw base — capped at 1.0
        let boost = 1.0 + (Double(min(streak, 30)) / 30.0) * 0.2
        return min(base * boost, 1.0)
    }

    private static func varietyScore(uniqueGroups: Int) -> Double {
        Double(min(uniqueGroups, 7)) / 7.0
    }
}
