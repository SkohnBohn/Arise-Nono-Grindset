import Foundation
import SwiftData

@Model
final class WorkoutEntry {
    var id: UUID
    var date: Date
    var notes: String
    var durationMin: Int
    var xpAwarded: Int

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.entry)
    var sets: [ExerciseSet]

    init(date: Date = .now, notes: String = "", durationMin: Int = 0) {
        self.id = UUID()
        self.date = date
        self.notes = notes
        self.durationMin = durationMin
        self.xpAwarded = 0
        self.sets = []
    }

    var muscleGroups: Set<MuscleGroup> {
        Set(sets.map(\.muscleGroup))
    }

    var totalSets: Int { sets.count }
}
