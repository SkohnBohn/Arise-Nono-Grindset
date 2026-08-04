import XCTest
@testable import AriseNono

final class XPEngineTests: XCTestCase {

    private func makeSet(group: MuscleGroup = .chest, reps: Int = 10, weight: Double = 80) -> WorkoutSnapshot.SetSnapshot {
        WorkoutSnapshot.SetSnapshot(muscleGroup: group, reps: reps, weightKg: weight, durationSec: nil)
    }

    private func makeCardioSet(durationSec: Int = 600) -> WorkoutSnapshot.SetSnapshot {
        WorkoutSnapshot.SetSnapshot(muscleGroup: .cardio, reps: nil, weightKg: nil, durationSec: durationSec)
    }

    func test_baseXP_is_awarded_for_empty_session() {
        let snapshot = WorkoutSnapshot(sets: [], durationMinutes: 30, streak: 0, priorMuscleGroupsThisWeek: [])
        // Base XP with no volume bonus, no streak
        XCTAssertEqual(XPEngine.computeXP(for: snapshot), XPEngine.baseXP)
    }

    func test_volume_bonus_is_positive_for_weighted_sets() {
        let sets = [makeSet(reps: 10, weight: 100), makeSet(reps: 10, weight: 100)]
        XCTAssertGreaterThan(XPEngine.volumeBonus(sets: sets), 0)
    }

    func test_volume_bonus_caps_at_50() {
        // Enormous volume should still cap
        let sets = Array(repeating: makeSet(reps: 100, weight: 1000), count: 20)
        XCTAssertEqual(XPEngine.volumeBonus(sets: sets), XPEngine.maxVolumeBonus)
    }

    func test_streak_multiplier_at_0() {
        XCTAssertEqual(XPEngine.streakMultiplier(streak: 0), 1.0, accuracy: 0.001)
    }

    func test_streak_multiplier_at_30_is_1_6() {
        XCTAssertEqual(XPEngine.streakMultiplier(streak: 30), 1.6, accuracy: 0.001)
    }

    func test_streak_multiplier_caps_at_30_days() {
        XCTAssertEqual(XPEngine.streakMultiplier(streak: 30),
                       XPEngine.streakMultiplier(streak: 100), accuracy: 0.001)
    }

    func test_variety_bonus_is_0_for_no_new_groups() {
        let priorGroups: Set<MuscleGroup> = [.chest, .back]
        let todayGroups: Set<MuscleGroup> = [.chest, .back]
        XCTAssertEqual(XPEngine.varietyBonus(priorGroups: priorGroups, todayGroups: todayGroups), 0)
    }

    func test_variety_bonus_for_one_new_group() {
        let priorGroups: Set<MuscleGroup> = [.chest]
        let todayGroups: Set<MuscleGroup> = [.chest, .legs]
        XCTAssertEqual(XPEngine.varietyBonus(priorGroups: priorGroups, todayGroups: todayGroups),
                       XPEngine.varietyBonusPerGroup)
    }

    func test_variety_bonus_caps_at_3_groups() {
        let priorGroups: Set<MuscleGroup> = []
        let todayGroups: Set<MuscleGroup> = [.chest, .back, .legs, .shoulders, .arms]
        let bonus = XPEngine.varietyBonus(priorGroups: priorGroups, todayGroups: todayGroups)
        XCTAssertEqual(bonus, XPEngine.maxVarietyGroups * XPEngine.varietyBonusPerGroup)
    }

    func test_cardio_volume_contributes() {
        let cardioSets = [makeCardioSet(durationSec: 1800)]
        XCTAssertGreaterThan(XPEngine.volumeBonus(sets: cardioSets), 0)
    }

    func test_total_xp_increases_with_streak() {
        let snapshot0 = WorkoutSnapshot(sets: [makeSet()], durationMinutes: 30, streak: 0, priorMuscleGroupsThisWeek: [])
        let snapshot10 = WorkoutSnapshot(sets: [makeSet()], durationMinutes: 30, streak: 10, priorMuscleGroupsThisWeek: [])
        XCTAssertLessThan(XPEngine.computeXP(for: snapshot0), XPEngine.computeXP(for: snapshot10))
    }
}
