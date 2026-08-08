import Foundation

// Value-type snapshots so this file has zero SwiftData / SwiftUI imports.
struct WorkoutHistoryEntry {
    let date: Date
    let muscleGroups: Set<MuscleGroup>
    let setCount: Int
    let hasCardio: Bool
    let cardioMinutes: Int
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
        QuestDraft(templateID: "dq_log_any",   type: .daily, category: .strength,    title: "Show Up, Honored One",     description: "Log any workout today. Gojo never skips.",            targetValue: 1,  xpReward: 30,  rewardType: .xp),
        QuestDraft(templateID: "dq_3sets",      type: .daily, category: .strength,    title: "Three-Phase Strike",       description: "Complete 3 sets. Blue, Red, Purple — one each.",       targetValue: 3,  xpReward: 20,  rewardType: .xp),
        QuestDraft(templateID: "dq_2groups",    type: .daily, category: .strength,    title: "Dual Domain",              description: "Train two muscle groups. The Six Eyes see everything.", targetValue: 2,  xpReward: 30,  rewardType: .xp),
        QuestDraft(templateID: "dq_cardio",     type: .daily, category: .cardio,      title: "Infinity Dash",            description: "Log a cardio session. Even infinity has to move.",     targetValue: 1,  xpReward: 25,  rewardType: .xp),
        QuestDraft(templateID: "dq_5sets",      type: .daily, category: .strength,    title: "Five-Form Barrage",        description: "Complete 5 sets in one session. No holding back.",     targetValue: 5,  xpReward: 35,  rewardType: .xp),
        QuestDraft(templateID: "dq_streak",     type: .daily, category: .consistency, title: "Unbroken Limitless",       description: "Log a workout to keep your streak alive.",            targetValue: 1,  xpReward: 25,  rewardType: .xp),
        QuestDraft(templateID: "dq_3groups",    type: .daily, category: .strength,    title: "Omnidirectional",          description: "Train three muscle groups. Attack from all sides.",   targetValue: 3,  xpReward: 40,  rewardType: .xp),
        QuestDraft(templateID: "dq_cardio20",   type: .daily, category: .cardio,      title: "20 Minutes of Infinity",   description: "20+ minutes of cardio. Sustain the Limitless.",       targetValue: 1,  xpReward: 30,  rewardType: .xp),
    ]

    static let weeklyTemplates: [QuestDraft] = [
        QuestDraft(templateID: "wq_5days",    type: .weekly, category: .consistency, title: "Domain Week",            description: "Log workouts on 5 of 7 days. Own the week.",               targetValue: 5,  xpReward: 150, rewardType: .streakFreeze),
        QuestDraft(templateID: "wq_variety",  type: .weekly, category: .strength,    title: "Six Eyes Mastery",       description: "Train 5 distinct muscle groups. See everything, hit everything.", targetValue: 5, xpReward: 100, rewardType: .xp),
        QuestDraft(templateID: "wq_volume",   type: .weekly, category: .strength,    title: "Hollow Purple Volume",   description: "Complete 50 total sets this week. Unleash the void.",     targetValue: 50, xpReward: 100, rewardType: .xp),
        QuestDraft(templateID: "wq_cardio3",  type: .weekly, category: .cardio,      title: "Limitless Cardio",       description: "Complete 3 cardio sessions this week.",                   targetValue: 3,  xpReward: 100, rewardType: .xp),
        QuestDraft(templateID: "wq_3days",    type: .weekly, category: .consistency, title: "Three-Day Supremacy",    description: "Log workouts on 3 consecutive days.",                     targetValue: 3,  xpReward: 80,  rewardType: .xp),
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

        let strengthCandidates    = pool.filter { $0.category == .strength }
        let cardioCandidates      = pool.filter { $0.category == .cardio }
        let consistencyCandidates = pool.filter { $0.category == .consistency }

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
        case "dq_cardio":
            return (todayWorkout?.hasCardio == true) ? 1 : 0
        case "dq_cardio20":
            return (todayWorkout?.cardioMinutes ?? 0) >= 20 ? 1 : 0
        case "dq_streak":
            return todayWorkout != nil ? 1 : 0
        case "wq_5days":
            return Double(weekWorkouts.count)
        case "wq_3days":
            return Double(weekWorkouts.count)
        case "wq_variety":
            let groups = weekWorkouts.flatMap(\.muscleGroups).reduce(into: Set<MuscleGroup>()) { $0.insert($1) }
            return Double(groups.count)
        case "wq_volume":
            return Double(weekWorkouts.reduce(0) { $0 + $1.setCount })
        case "wq_cardio3":
            return Double(weekWorkouts.filter(\.hasCardio).count)
        default:
            return 0
        }
    }
}
