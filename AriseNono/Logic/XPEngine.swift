import Foundation

// Plain-Swift snapshot types — no SwiftData dependency.
struct WorkoutSnapshot {
    struct SetSnapshot {
        let muscleGroup: MuscleGroup
        let reps: Int?
        let weightKg: Double?
        let durationSec: Int?
    }

    let sets: [SetSnapshot]
    let durationMinutes: Int
    let streak: Int
    // Muscle groups logged in other sessions this week (for variety bonus)
    let priorMuscleGroupsThisWeek: Set<MuscleGroup>
}

enum XPEngine {
    static let baseXP: Int = 20
    static let maxVolumeBonus: Int = 50
    static let varietyBonusPerGroup: Int = 5
    static let maxVarietyGroups: Int = 3

    // Duration-based XP for the simplified logger
    static func computeXP(isStrength: Bool, durationMinutes: Int, streak: Int) -> Int {
        let rate: Double = isStrength ? 1.8 : 1.2
        let base = Int(Double(durationMinutes) * rate)
        return max(10, Int(Double(base) * streakMultiplier(streak: streak)))
    }

    static func computeXP(for workout: WorkoutSnapshot) -> Int {
        let vol = volumeBonus(sets: workout.sets)
        let mult = streakMultiplier(streak: workout.streak)
        let vari = varietyBonus(priorGroups: workout.priorMuscleGroupsThisWeek,
                                todayGroups: Set(workout.sets.map(\.muscleGroup)))
        return Int(Double(baseXP + vol) * mult) + vari
    }

    static func volumeBonus(sets: [WorkoutSnapshot.SetSnapshot]) -> Int {
        let raw = sets.reduce(0.0) { acc, s in
            if s.muscleGroup == .cardio {
                return acc + Double(s.durationSec ?? 0) * 0.2 / 60.0
            } else if let reps = s.reps, let kg = s.weightKg, kg > 0 {
                return acc + Double(reps) * kg * 0.01
            } else if let reps = s.reps {
                return acc + Double(reps) * 0.5
            }
            return acc
        }
        return min(Int(raw), maxVolumeBonus)
    }

    static func streakMultiplier(streak: Int) -> Double {
        1.0 + Double(min(streak, 30)) * 0.02
    }

    static func varietyBonus(priorGroups: Set<MuscleGroup>, todayGroups: Set<MuscleGroup>) -> Int {
        // Bonus for muscle groups being hit for the first time this week
        let newGroups = todayGroups.subtracting(priorGroups)
        return min(newGroups.count, maxVarietyGroups) * varietyBonusPerGroup
    }
}
