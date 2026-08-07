import Foundation

struct AuraInput {
    var activeDays30: Int          // days with any log in last 30 days
    var currentStreak: Int
    var uniqueMuscleGroups14d: Int // distinct groups in last 14 days (0–7)
}

enum AuraCalculator {
    static func compute(input: AuraInput) -> Double {
        let consistency = consistencyScore(activeDays: input.activeDays30, streak: input.currentStreak)
        let variety     = varietyScore(uniqueGroups: input.uniqueMuscleGroups14d)

        return (consistency * 0.55 + variety * 0.45) * 1000
    }

    private static func consistencyScore(activeDays: Int, streak: Int) -> Double {
        let base = Double(min(activeDays, 30)) / 30.0
        let boost = 1.0 + (Double(min(streak, 30)) / 30.0) * 0.2
        return min(base * boost, 1.0)
    }

    private static func varietyScore(uniqueGroups: Int) -> Double {
        Double(min(uniqueGroups, 7)) / 7.0
    }
}
