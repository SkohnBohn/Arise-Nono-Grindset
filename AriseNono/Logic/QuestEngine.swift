import Foundation

// Value-type snapshots so this file has zero SwiftData / SwiftUI imports.
struct WorkoutHistoryEntry {
    let date: Date
    let muscleGroups: Set<MuscleGroup>
    let setCount: Int
    let hasCardio: Bool
    let cardioMinutes: Int
    let exerciseNames: Set<String>
    let totalDurationMin: Int
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
        QuestDraft(templateID: "dq_log_any",  type: .daily, category: .strength,    title: "The Strongest Clocks In",           description: "Log any workout. Even Gojo shows up to class. Sometimes.",              targetValue: 1,  xpReward: 30, rewardType: .xp),
        QuestDraft(templateID: "dq_3sets",    type: .daily, category: .strength,    title: "Blue, Red, Purple",                 description: "Log 3 sessions today. Channel your inner Hollow Purple.",                targetValue: 3,  xpReward: 20, rewardType: .xp),
        QuestDraft(templateID: "dq_5sets",    type: .daily, category: .strength,    title: "Five-Star Domain",                  description: "Log 5 sessions in one day. The domain is expanding.",                   targetValue: 5,  xpReward: 35, rewardType: .xp),
        QuestDraft(templateID: "dq_cardio",   type: .daily, category: .cardio,      title: "Running From Responsibility",        description: "Log a cardio session. Gojo does it between naps.",                      targetValue: 1,  xpReward: 25, rewardType: .xp),
        QuestDraft(templateID: "dq_cardio20", type: .daily, category: .cardio,      title: "Sustained Infinity",                description: "20+ minutes of cardio. The Limitless never tires.",                     targetValue: 1,  xpReward: 30, rewardType: .xp),
        QuestDraft(templateID: "dq_streak",   type: .daily, category: .consistency, title: "Nah, I'd Win",                      description: "Keep your streak alive. Losing is not in Gojo's vocabulary.",            targetValue: 1,  xpReward: 25, rewardType: .xp),
        QuestDraft(templateID: "dq_stretch",  type: .daily, category: .strength,    title: "Six Eyes Mobility Check",           description: "Do a stretching session. Even the Honored One needs to limber up.",     targetValue: 1,  xpReward: 20, rewardType: .xp),
        QuestDraft(templateID: "dq_back",     type: .daily, category: .consistency, title: "Protecting the Spine of Greatness", description: "Back pain prevention. Can't flex if your back gives out.",               targetValue: 1,  xpReward: 20, rewardType: .xp),
        QuestDraft(templateID: "dq_sleep",    type: .daily, category: .consistency, title: "Gojo's Beauty Sleep Protocol",      description: "Sleep properly. The Six Eyes need rest too (allegedly).",               targetValue: 1,  xpReward: 20, rewardType: .xp),
        QuestDraft(templateID: "dq_burst",    type: .daily, category: .strength,    title: "Hollow Purple, I Guess",            description: "Do a burst workout. Short, explosive, devastatingly cool.",              targetValue: 1,  xpReward: 20, rewardType: .xp),
        QuestDraft(templateID: "dq_30min",    type: .daily, category: .strength,    title: "Half a Domain Expansion",           description: "Log 30+ minutes today. Halfway to becoming the Honored One.",            targetValue: 1,  xpReward: 30, rewardType: .xp),
    ]

    static let weeklyTemplates: [QuestDraft] = [
        QuestDraft(templateID: "wq_5days",    type: .weekly, category: .consistency, title: "Domain Expansion: Full Week",       description: "5 workout days this week. Claim the entire territory.",                  targetValue: 5,  xpReward: 150, rewardType: .streakFreeze),
        QuestDraft(templateID: "wq_3days",    type: .weekly, category: .consistency, title: "Three-Day Technique",               description: "Log workouts on 3 consecutive days. Consistency is Limitless.",          targetValue: 3,  xpReward: 80,  rewardType: .xp),
        QuestDraft(templateID: "wq_cardio3",  type: .weekly, category: .cardio,      title: "Triple Infinity Sprint",            description: "3 cardio sessions this week. Gojo would be... mildly impressed.",         targetValue: 3,  xpReward: 100, rewardType: .xp),
        QuestDraft(templateID: "wq_volume",   type: .weekly, category: .strength,    title: "Hollow Purple Volume",              description: "15 sessions this week. Quantity IS quality when you're the Honored One.", targetValue: 15, xpReward: 100, rewardType: .xp),
        QuestDraft(templateID: "wq_stretch3", type: .weekly, category: .strength,    title: "The Honored One Stays Flexible",    description: "3 stretching sessions this week. Flexibility is a Limitless technique.",  targetValue: 3,  xpReward: 80,  rewardType: .xp),
        QuestDraft(templateID: "wq_sleep5",   type: .weekly, category: .consistency, title: "Sleep Like You're Sealed in Prison", description: "Sleep properly 5 times this week. Even Gojo rests in Mugen.",           targetValue: 5,  xpReward: 100, rewardType: .xp),
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
        case "dq_cardio":
            return (todayWorkout?.hasCardio == true) ? 1 : 0
        case "dq_cardio20":
            return (todayWorkout?.cardioMinutes ?? 0) >= 20 ? 1 : 0
        case "dq_streak":
            return todayWorkout != nil ? 1 : 0
        case "dq_stretch":
            return (todayWorkout?.exerciseNames.contains("Stretching") == true) ? 1 : 0
        case "dq_back":
            return (todayWorkout?.exerciseNames.contains("Back Pain Prevention") == true) ? 1 : 0
        case "dq_sleep":
            return (todayWorkout?.exerciseNames.contains("Sleep") == true) ? 1 : 0
        case "dq_burst":
            return (todayWorkout?.exerciseNames.contains("Burst") == true) ? 1 : 0
        case "dq_30min":
            return (todayWorkout?.totalDurationMin ?? 0) >= 30 ? 1 : 0
        case "wq_5days":
            return Double(weekWorkouts.count)
        case "wq_3days":
            return Double(weekWorkouts.count)
        case "wq_cardio3":
            return Double(weekWorkouts.filter(\.hasCardio).count)
        case "wq_volume":
            return Double(weekWorkouts.reduce(0) { $0 + $1.setCount })
        case "wq_stretch3":
            return Double(weekWorkouts.filter { $0.exerciseNames.contains("Stretching") }.count)
        case "wq_sleep5":
            return Double(weekWorkouts.filter { $0.exerciseNames.contains("Sleep") }.count)
        default:
            return 0
        }
    }
}
