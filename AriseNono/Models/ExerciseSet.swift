import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var id: UUID
    var exerciseName: String
    var muscleGroup: MuscleGroup
    var setNumber: Int
    var reps: Int?
    var weightKg: Double?
    var durationSec: Int?
    var entry: WorkoutEntry?

    init(
        exerciseName: String,
        muscleGroup: MuscleGroup,
        setNumber: Int = 1,
        reps: Int? = nil,
        weightKg: Double? = nil,
        durationSec: Int? = nil
    ) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.muscleGroup = muscleGroup
        self.setNumber = setNumber
        self.reps = reps
        self.weightKg = weightKg
        self.durationSec = durationSec
    }

    var volumeContribution: Double {
        if muscleGroup == .cardio {
            return Double(durationSec ?? 0) * 0.2 / 60.0
        }
        if let reps, let weight = weightKg, weight > 0 {
            return Double(reps) * weight * 0.01
        }
        if let reps {
            return Double(reps) * 0.5
        }
        return 0
    }
}
