import Foundation

// Value-type snapshots so this file has zero SwiftData / SwiftUI imports.
struct WorkoutHistoryEntry {
    let date: Date
    let muscleGroups: Set<MuscleGroup>
    let setCount: Int
    let hasCardio: Bool
}

struct QuestDraft {
    let templateID: String
    let type: QuestType
    let category: QuestCategory
    let title: String
    let description: String
    let targetValue: Double
    let xpReward: Int
    let rewardType: QuestRewardType
}

enum QuestEngine {

    // MARK: - Template Definitions

    static let dailyTemplates: [QuestDraft] = [
        QuestDraft(templateID: "dq_log_any",   type: .daily, category: .strength,    title: "Log Today's Session",    description: "Record any workout today.",                   targetValue: 1,  xpReward: 30,  rewardType: .xp),
        QuestDraft(templateID: "dq_3sets",      type: .daily, category: .strength,    title: "Complete 3 Sets",        description: "Log at least 3 sets in any session.",        targetValue: 3,  xpReward: 20,  rewardType: .xp),
        QuestDraft(templateID: "dq_2groups",    type: .daily, category: .strength,    title: "Train 2 Muscle Groups",  description: "Hit two distinct muscle groups today.",       targetValue: 2,  xpReward: 30,  rewardType: .xp),
        QuestDraft(templateID: "dq_cardio",     type: .daily, category: .cardio,      title: "Cardio Activation",      description: "Log one cardio session.",                     targetValue: 1,  xpReward: 25,  rewardType: .xp),
        QuestDraft(templateID: "dq_5sets",      type: .daily, category: .strength,    title: "5-Set Push",             description: "Log at least 5 sets in one session.",        targetValue: 5,  xpReward: 35,  rewardType: .xp),
        QuestDraft(templateID: "dq_streak",     type: .daily, category: .consistency, title: "Keep the Chain",         description: "Log a workout to maintain your streak.",     targetValue: 1,  xpReward: 25,  rewardType: .xp),
        QuestDraft(templateID: "dq_3groups",    type: .daily, category: .strength,    title: "Full Body Day",          description: "Hit three distinct muscle groups today.",     targetValue: 3,  xpReward: 40,  rewardType: .xp),
        QuestDraft(templateID: "dq_cardio20",   type: .daily, category: .cardio,      title: "20-Min Cardio",          description: "Log at least 20 minutes of cardio.",         targetValue: 1,  xpReward: 30,  rewardType: .xp),
    ]

    static let weeklyTemplates: [QuestDraft] = [
        QuestDraft(templateID: "wq_5days",    type: .weekly, category: .consistency, title: "5-Day Warrior",   description: "Log workouts on 5 of 7 days.",           targetValue: 5,  xpReward: 150, rewardType: .streakFreeze),
        QuestDraft(templateID: "wq_variety",  type: .weekly, category: .strength,    title: "Full Spectrum",   description: "Log 5 distinct muscle groups this week.", targetValue: 5,  xpReward: 100, rewardType: .xp),
        QuestDraft(templateID: "wq_volume",   type: .weekly, category: .strength,    title: "High Volume",     description: "Complete 50 total sets this week.",       targetValue: 50, xpReward: 100, rewardType: .xp),
        QuestDraft(templateID: "wq_cardio3",  type: .weekly, category: .cardio,      title: "Cardio Streak",   description: "Complete 3 cardio sessions this week.",   targetValue: 3,  xpReward: 100, rewardType: .xp),
        QuestDraft(templateID: "wq_3days",    type: .weekly, category: .consistency, title: "3-Day Streak",    description: "Log workouts on 3 consecutive days.",     targetValue: 3,  xpReward: 80,  rewardType: .xp),
    ]

    // MARK: - Generation

    static func generateDailyQuests(
        workoutHistory: [WorkoutHistoryEntry],
        recentlyCompletedIDs: Set<String>
    ) -> [QuestDraft] {
        let pool = dailyTemplates.filter { !recentlyCompletedIDs.contains($0.templateID) }

        func pick(from filtered: [QuestDraft], excluding used: [QuestDraft]) -> QuestDraft? {
            let candidates = filtered.filter { t in !used.contains(where: { $0.templateID == t.templateID }) }
            return candidates.randomElement()
        }

        let strengthCandidates     = pool.filter { $0.category == .strength }
        let cardioCandidates       = pool.filter { $0.category == .cardio }
        let consistencyCandidates  = pool.filter { $0.category == .consistency }

        var chosen: [QuestDraft] = []
        if let s = pick(from: strengthCandidates,    excluding: chosen) { chosen.append(s) }
        if let c = pick(from: cardioCandidates,      excluding: chosen) { chosen.append(c) }
        let wildPool = consistencyCandidates.isEmpty ? pool : consistencyCandidates
        if let w = pick(from: wildPool, excluding: chosen) { chosen.append(w) }

        return Array(chosen.prefix(3))
    }

    static func generateWeeklyQuests(recentlyCompletedIDs: Set<String>) -> [QuestDraft] {
        weeklyTemplates
            .filter { !recentlyCompletedIDs.contains($0.templateID) }
            .shuffled()
            .prefix(2)
            .map { $0 }
    }

    // MARK: - Progress Evaluation

    static func evaluateProgress(
        templateID: String,
        todayWorkout: WorkoutHistoryEntry?,
        weekWorkouts: [WorkoutHistoryEntry]
    ) -> Double {
        switch templateID {
        case "dq_log_any":
            return todayWorkout != nil ? 1 : 0
        case "dq_3sets":
            return Double(todayWorkout?.setCount ?? 0)
        case "dq_5sets":
            return Double(todayWorkout?.setCount ?? 0)
        case "dq_2groups":
            return Double(todayWorkout?.muscleGroups.count ?? 0)
        case "dq_3groups":
            return Double(todayWorkout?.muscleGroups.count ?? 0)
        case "dq_cardio", "dq_cardio20":
            return (todayWorkout?.hasCardio == true) ? 1 : 0
        case "dq_streak":
            return todayWorkout != nil ? 1 : 0
        case "wq_5days":
            return Double(weekWorkouts.count)
        case "wq_3days":
            return Double(weekWorkouts.count)
        case "wq_variety":
            return Double(weekWorkouts.flatMap(\.muscleGroups).reduce(into: Set<MuscleGroup>()) { $0.insert($1) }.count)
        case "wq_volume":
            return Double(weekWorkouts.reduce(0) { $0 + $1.setCount })
        case "wq_cardio3":
            return Double(weekWorkouts.filter(\.hasCardio).count)
        default:
            return 0
        }
    }
}
