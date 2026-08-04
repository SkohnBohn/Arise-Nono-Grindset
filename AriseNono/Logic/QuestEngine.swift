import Foundation

// Value-type snapshots so this file has zero SwiftData / SwiftUI imports.
struct WorkoutHistoryEntry {
    let date: Date
    let muscleGroups: Set<MuscleGroup>
    let setCount: Int
    let hasCardio: Bool
}

struct NutritionHistoryEntry {
    let date: Date
    let adherenceScore: Double
    let proteinG: Double
    let proteinGoal: Double
    let fiberG: Double
    let fiberGoal: Double
    let sugarG: Double
    let sugarGoal: Double
    let windowHours: Double?
    let windowGoal: Double
    let micronutrientCount: Int
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
        QuestDraft(templateID: "dq_log_any",       type: .daily, category: .strength,    title: "Log Today's Session",    description: "Record any workout today.",                   targetValue: 1,  xpReward: 30,  rewardType: .xp),
        QuestDraft(templateID: "dq_3sets",          type: .daily, category: .strength,    title: "Complete 3 Sets",        description: "Log at least 3 sets in any session.",        targetValue: 3,  xpReward: 20,  rewardType: .xp),
        QuestDraft(templateID: "dq_2groups",        type: .daily, category: .strength,    title: "Train 2 Muscle Groups",  description: "Hit two distinct muscle groups today.",       targetValue: 2,  xpReward: 30,  rewardType: .xp),
        QuestDraft(templateID: "dq_cardio",         type: .daily, category: .cardio,      title: "Cardio Activation",      description: "Log one cardio session.",                     targetValue: 1,  xpReward: 25,  rewardType: .xp),
        QuestDraft(templateID: "dq_protein",        type: .daily, category: .nutrition,   title: "Hit Protein Target",     description: "Reach your daily protein goal.",              targetValue: 1,  xpReward: 25,  rewardType: .xp),
        QuestDraft(templateID: "dq_fiber",          type: .daily, category: .nutrition,   title: "Fiber Loaded",           description: "Hit at least 40g of fiber today.",            targetValue: 1,  xpReward: 20,  rewardType: .xp),
        QuestDraft(templateID: "dq_sugar",          type: .daily, category: .nutrition,   title: "Low Sugar Day",          description: "Keep added sugar under your daily limit.",    targetValue: 1,  xpReward: 20,  rewardType: .xp),
        QuestDraft(templateID: "dq_window",         type: .daily, category: .nutrition,   title: "Eating Window Kept",     description: "Stay inside your eating window.",             targetValue: 1,  xpReward: 20,  rewardType: .xp),
        QuestDraft(templateID: "dq_micronutrient",  type: .daily, category: .nutrition,   title: "Micro Check",            description: "Tick 3 or more micronutrient sources.",       targetValue: 3,  xpReward: 15,  rewardType: .xp),
        QuestDraft(templateID: "dq_no_skip",        type: .daily, category: .consistency, title: "Full Streak Day",        description: "Log both a workout and nutrition today.",     targetValue: 2,  xpReward: 35,  rewardType: .xp),
    ]

    static let weeklyTemplates: [QuestDraft] = [
        QuestDraft(templateID: "wq_5days",      type: .weekly, category: .consistency, title: "5-Day Warrior",   description: "Log workouts on 5 of 7 days.",           targetValue: 5,  xpReward: 150, rewardType: .streakFreeze),
        QuestDraft(templateID: "wq_nutrition4", type: .weekly, category: .nutrition,   title: "Clean Week",      description: "Hit nutrition goals 4 of 7 days.",       targetValue: 4,  xpReward: 120, rewardType: .auraBoost),
        QuestDraft(templateID: "wq_variety",    type: .weekly, category: .strength,    title: "Full Spectrum",   description: "Log 5 distinct muscle groups this week.", targetValue: 5,  xpReward: 100, rewardType: .xp),
        QuestDraft(templateID: "wq_volume",     type: .weekly, category: .strength,    title: "High Volume",     description: "Complete 50 total sets this week.",       targetValue: 50, xpReward: 100, rewardType: .xp),
        QuestDraft(templateID: "wq_cardio3",    type: .weekly, category: .cardio,      title: "Cardio Streak",   description: "Complete 3 cardio sessions this week.",   targetValue: 3,  xpReward: 100, rewardType: .xp),
    ]

    // MARK: - Generation

    static func generateDailyQuests(
        workoutHistory: [WorkoutHistoryEntry],
        nutritionHistory: [NutritionHistoryEntry],
        recentlyCompletedIDs: Set<String>
    ) -> [QuestDraft] {
        let weights = categoryWeights(workout: workoutHistory, nutrition: nutritionHistory)
        let pool = dailyTemplates.filter { !recentlyCompletedIDs.contains($0.templateID) }

        // Always guarantee one from each pillar
        func pick(from filtered: [QuestDraft], excluding used: [QuestDraft]) -> QuestDraft? {
            let candidates = filtered.filter { t in !used.contains(where: { $0.templateID == t.templateID }) }
            return candidates.randomElement()
        }

        let strengthCandidates  = pool.filter { $0.category == .strength }
        let nutritionCandidates = pool.filter { $0.category == .nutrition }
        let wildCandidates      = pool.filter { $0.category == .cardio || $0.category == .consistency }

        var chosen: [QuestDraft] = []
        if let s = pick(from: strengthCandidates,  excluding: chosen) { chosen.append(s) }
        if let n = pick(from: nutritionCandidates, excluding: chosen) { chosen.append(n) }
        let wildPool = wildCandidates.isEmpty ? pool : wildCandidates
        if let w = pick(from: wildPool, excluding: chosen) { chosen.append(w) }

        // Weight toward highest-deficit category for the wild slot if we got fewer than 3
        _ = weights
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
        todayNutrition: NutritionHistoryEntry?,
        weekWorkouts: [WorkoutHistoryEntry],
        weekNutritionDays: [NutritionHistoryEntry]
    ) -> Double {
        switch templateID {
        case "dq_log_any":
            return todayWorkout != nil ? 1 : 0
        case "dq_3sets":
            return Double(todayWorkout?.setCount ?? 0)
        case "dq_2groups":
            return Double(todayWorkout?.muscleGroups.count ?? 0)
        case "dq_cardio":
            return (todayWorkout?.hasCardio == true) ? 1 : 0
        case "dq_protein":
            guard let n = todayNutrition else { return 0 }
            return n.proteinG >= n.proteinGoal ? 1 : 0
        case "dq_fiber":
            return (todayNutrition?.fiberG ?? 0) >= 40 ? 1 : 0
        case "dq_sugar":
            guard let n = todayNutrition else { return 0 }
            return n.sugarG <= n.sugarGoal ? 1 : 0
        case "dq_window":
            guard let n = todayNutrition, let w = n.windowHours else { return 0 }
            return w <= n.windowGoal ? 1 : 0
        case "dq_micronutrient":
            return Double(todayNutrition?.micronutrientCount ?? 0)
        case "dq_no_skip":
            var count = 0.0
            if todayWorkout != nil { count += 1 }
            if todayNutrition != nil { count += 1 }
            return count
        case "wq_5days":
            return Double(weekWorkouts.count)
        case "wq_nutrition4":
            return Double(weekNutritionDays.filter { $0.adherenceScore >= 0.6 }.count)
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

    // MARK: - Helpers

    private static func categoryWeights(
        workout: [WorkoutHistoryEntry],
        nutrition: [NutritionHistoryEntry]
    ) -> [QuestCategory: Double] {
        let last14 = workout.filter { Calendar.current.dateComponents([.day], from: $0.date, to: .now).day ?? 0 <= 14 }
        let workoutFreq  = Double(last14.count) / 14.0
        let cardioFreq   = Double(last14.filter(\.hasCardio).count) / 14.0
        let nutritionAdh = nutrition.prefix(7).map(\.adherenceScore).reduce(0, +) / Double(max(nutrition.prefix(7).count, 1))

        return [
            .strength:    1.0 - workoutFreq,
            .cardio:      1.0 - cardioFreq,
            .nutrition:   1.0 - nutritionAdh,
            .consistency: max(1.0 - workoutFreq, 1.0 - nutritionAdh),
        ]
    }
}
