import Foundation
import SwiftData

// MARK: - Errors

enum BackupError: LocalizedError {
    case encodingFailed
    var errorDescription: String? { "Could not encode backup data." }
}

// MARK: - Codable snapshots

struct BackupData: Codable {
    var version: Int = 1
    var exportedAt: Date
    var player: BkpPlayer
    var workouts: [BkpWorkout]
    var quickActions: [BkpQuickAction]
}

struct BkpPlayer: Codable {
    var name: String
    var totalXP: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?
    var streakFreezeBalance: Int
    var bodyweightKg: Double?
    var goalStrengthDays: Int
    var goalCardioDays: Int
    var goalStretchDays: Int
    var goalBackDays: Int
    var goalSleepDays: Int
}

struct BkpWorkout: Codable {
    var date: Date
    var notes: String
    var durationMin: Int
    var xpAwarded: Int
    var sets: [BkpSet]
}

struct BkpSet: Codable {
    var exerciseName: String
    var muscleGroup: MuscleGroup
    var setNumber: Int
    var reps: Int?
    var weightKg: Double?
    var durationSec: Int?
}

struct BkpQuickAction: Codable {
    var date: Date
    var actionID: String
}

// MARK: - Engine

enum BackupEngine {

    private static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    private static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    // Serialise everything to a JSON string the user can copy into Notes.
    static func exportAsText(player: Player, context: ModelContext) throws -> String {
        let workouts     = (try? context.fetch(FetchDescriptor<WorkoutEntry>())) ?? []
        let quickActions = (try? context.fetch(FetchDescriptor<QuickActionEntry>())) ?? []

        let playerSnap = BkpPlayer(
            name: player.name,
            totalXP: player.totalXP,
            currentStreak: player.currentStreak,
            longestStreak: player.longestStreak,
            lastActiveDate: player.lastActiveDate,
            streakFreezeBalance: player.streakFreezeBalance,
            bodyweightKg: player.bodyweightKg,
            goalStrengthDays: player.goalStrengthDays,
            goalCardioDays: player.goalCardioDays,
            goalStretchDays: player.goalStretchDays,
            goalBackDays: player.goalBackDays,
            goalSleepDays: player.goalSleepDays
        )

        let workoutSnaps: [BkpWorkout] = workouts.map { w in
            BkpWorkout(
                date: w.date,
                notes: w.notes,
                durationMin: w.durationMin,
                xpAwarded: w.xpAwarded,
                sets: w.sets.map { s in
                    BkpSet(
                        exerciseName: s.exerciseName,
                        muscleGroup: s.muscleGroup,
                        setNumber: s.setNumber,
                        reps: s.reps,
                        weightKg: s.weightKg,
                        durationSec: s.durationSec
                    )
                }
            )
        }

        let quickSnaps: [BkpQuickAction] = quickActions.map {
            BkpQuickAction(date: $0.date, actionID: $0.actionID)
        }

        let backup = BackupData(
            exportedAt: Date(),
            player: playerSnap,
            workouts: workoutSnaps,
            quickActions: quickSnaps
        )

        let data = try encoder.encode(backup)
        guard let text = String(data: data, encoding: .utf8) else {
            throw BackupError.encodingFailed
        }
        return text
    }

    // Restore from a JSON string the user pasted in.
    static func restore(from text: String, player: Player, context: ModelContext) throws {
        guard let data = text.data(using: .utf8) else { throw BackupError.encodingFailed }
        let backup = try decoder.decode(BackupData.self, from: data)

        // Clear existing records
        for w in (try? context.fetch(FetchDescriptor<WorkoutEntry>())) ?? [] { context.delete(w) }
        for q in (try? context.fetch(FetchDescriptor<QuickActionEntry>())) ?? [] { context.delete(q) }

        // Restore player
        let p = backup.player
        player.name                = p.name
        player.totalXP             = p.totalXP
        player.level               = LevelCurve.level(forTotalXP: p.totalXP)
        player.rankTier            = RankTier.tier(for: player.level)
        player.currentStreak       = p.currentStreak
        player.longestStreak       = p.longestStreak
        player.lastActiveDate      = p.lastActiveDate
        player.streakFreezeBalance = p.streakFreezeBalance
        player.bodyweightKg        = p.bodyweightKg
        player.goalStrengthDays    = p.goalStrengthDays
        player.goalCardioDays      = p.goalCardioDays
        player.goalStretchDays     = p.goalStretchDays
        player.goalBackDays        = p.goalBackDays
        player.goalSleepDays       = p.goalSleepDays

        // Restore workouts
        for ws in backup.workouts {
            let entry = WorkoutEntry(date: ws.date, notes: ws.notes, durationMin: ws.durationMin)
            entry.xpAwarded = ws.xpAwarded
            context.insert(entry)
            var sets: [ExerciseSet] = []
            for ss in ws.sets {
                let set = ExerciseSet(
                    exerciseName: ss.exerciseName,
                    muscleGroup: ss.muscleGroup,
                    setNumber: ss.setNumber,
                    reps: ss.reps,
                    weightKg: ss.weightKg,
                    durationSec: ss.durationSec
                )
                set.entry = entry
                context.insert(set)
                sets.append(set)
            }
            entry.sets = sets
        }

        // Restore quick actions
        for qa in backup.quickActions {
            context.insert(QuickActionEntry(date: qa.date, actionID: qa.actionID))
        }

        try context.save()
    }
}
