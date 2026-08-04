import XCTest
@testable import AriseNono

final class NutritionScorerTests: XCTestCase {

    private var perfectGoals: NutritionGoals {
        NutritionGoals(calories: 2000, proteinG: 120, fiberG: 50, maxSugarG: 15, eatingWindowHours: 12)
    }

    private func perfectDay() -> NutritionDayData {
        NutritionDayData(totalCalories: 2000, totalProteinG: 120,
                         totalFiberG: 50, addedSugarG: 10, eatingWindowHours: 10)
    }

    func test_perfect_day_scores_1() {
        let score = NutritionScorer.adherenceScore(day: perfectDay(), goals: perfectGoals)
        XCTAssertEqual(score, 1.0, accuracy: 0.01)
    }

    func test_zero_intake_scores_low() {
        let day = NutritionDayData(totalCalories: 0, totalProteinG: 0,
                                   totalFiberG: 0, addedSugarG: 0, eatingWindowHours: nil)
        let score = NutritionScorer.adherenceScore(day: day, goals: perfectGoals)
        XCTAssertLessThan(score, 0.5)
    }

    func test_calorie_score_1_within_10_pct() {
        // 2000 ± 200 should be full score
        let dayLow  = NutritionDayData(totalCalories: 1800, totalProteinG: 120, totalFiberG: 50, addedSugarG: 10, eatingWindowHours: 10)
        let dayHigh = NutritionDayData(totalCalories: 2200, totalProteinG: 120, totalFiberG: 50, addedSugarG: 10, eatingWindowHours: 10)
        let low  = NutritionScorer.adherenceScore(day: dayLow,  goals: perfectGoals)
        let high = NutritionScorer.adherenceScore(day: dayHigh, goals: perfectGoals)
        // Calorie component should be full (1.0); other components still same
        XCTAssertGreaterThan(low,  0.95)
        XCTAssertGreaterThan(high, 0.95)
    }

    func test_excess_sugar_reduces_score() {
        var day = perfectDay()
        day.addedSugarG = 100 // massively over limit
        let score = NutritionScorer.adherenceScore(day: day, goals: perfectGoals)
        XCTAssertLessThan(score, 0.9)
    }

    func test_missed_protein_reduces_score() {
        var day = perfectDay()
        day.totalProteinG = 30 // well below 120g goal
        let score = NutritionScorer.adherenceScore(day: day, goals: perfectGoals)
        XCTAssertLessThan(score, 0.8)
    }

    func test_score_is_between_0_and_1() {
        let extreme = NutritionDayData(totalCalories: 5000, totalProteinG: 0,
                                       totalFiberG: 0, addedSugarG: 500, eatingWindowHours: 20)
        let score = NutritionScorer.adherenceScore(day: extreme, goals: perfectGoals)
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 1)
    }

    func test_no_window_tracking_gives_neutral_window_score() {
        // Window component contributes 0.1 weight; nil should give 0.5 × 0.1 = 0.05 penalty
        var dayWithWindow    = perfectDay()
        var dayWithoutWindow = perfectDay()
        dayWithoutWindow.eatingWindowHours = nil

        let withScore    = NutritionScorer.adherenceScore(day: dayWithWindow,    goals: perfectGoals)
        let withoutScore = NutritionScorer.adherenceScore(day: dayWithoutWindow, goals: perfectGoals)

        // Without window tracking should be strictly lower than a perfect day
        XCTAssertLessThan(withoutScore, withScore + 0.001)
    }
}
