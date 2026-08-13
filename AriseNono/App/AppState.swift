import SwiftUI
import SwiftData

@Observable
class AppState {

    enum MomentType: Equatable {
        case levelUp(level: Int)
        case rankUp(rank: RankTier)
        case streakMilestone(days: Int)
    }

    var activeMoment: MomentType?
    var streakFreezePending = false

    var todayXP: Int = 0
    var monthlyXP: Int = 0
    private var todayXPDate: Date = Calendar.current.startOfDay(for: .now)
    private var monthlyXPMonth: Int = Calendar.current.component(.month, from: .now)

    // Opacity for the daily background image:
    //   <30 XP  → invisible
    //   30 XP   → 5% (just barely there)
    //   ~220 XP → 50% (approx 2h strength session — "amazing day")
    //   ~370 XP → 85% max
    var todayBgOpacity: Double {
        guard todayXP >= 30 else { return 0 }
        let raw = 0.05 + Double(todayXP - 30) / 190.0 * 0.45
        return min(raw, 0.85)
    }

    // Call once on launch to seed todayXP and monthlyXP from persisted workout entries
    func initializeTodayXP(from workouts: [WorkoutEntry]) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)
        let monthStart = calendar.dateInterval(of: .month, for: .now)?.start ?? todayStart
        todayXP = workouts.filter { $0.date >= todayStart }.reduce(0) { $0 + $1.xpAwarded }
        monthlyXP = workouts.filter { $0.date >= monthStart }.reduce(0) { $0 + $1.xpAwarded }
        todayXPDate = todayStart
        monthlyXPMonth = calendar.component(.month, from: .now)
    }

    private static let streakMilestones: Set<Int> = [7, 14, 30, 60, 100, 365]
    // Award a free freeze at these streak milestones as a bonus
    private static let freezeMilestones: Set<Int> = [7, 14, 30]

    func checkForMoments(oldXP: Int, newXP: Int, oldStreak: Int, newStreak: Int) {
        let oldLevel = LevelCurve.level(forTotalXP: oldXP)
        let newLevel = LevelCurve.level(forTotalXP: newXP)

        if newLevel > oldLevel {
            let newRank = RankTier.tier(for: newLevel)
            let oldRank = RankTier.tier(for: oldLevel)
            if newRank != oldRank {
                triggerMoment(.rankUp(rank: newRank))
            } else {
                triggerMoment(.levelUp(level: newLevel))
            }
        }

        if Self.streakMilestones.contains(newStreak) && newStreak > oldStreak {
            triggerMoment(.streakMilestone(days: newStreak))
        }
    }

    func triggerMoment(_ moment: MomentType) {
        switch (activeMoment, moment) {
        case (.rankUp, _):                   return
        case (_, .rankUp):                   activeMoment = moment
        case (.levelUp, .streakMilestone):   return
        default:                             activeMoment = moment
        }
    }

    func dismissMoment() {
        withAnimation(.easeOut(duration: 0.3)) { activeMoment = nil }
    }

    // MARK: - Player Helpers

    func awardXP(_ amount: Int, to player: Player, context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        if today > todayXPDate {
            todayXP = 0
            todayXPDate = today
        }
        let currentMonth = calendar.component(.month, from: .now)
        if currentMonth != monthlyXPMonth {
            monthlyXP = 0
            monthlyXPMonth = currentMonth
        }
        todayXP += amount
        monthlyXP += amount

        let oldXP = player.totalXP
        let oldStreak = player.currentStreak
        player.totalXP += amount
        player.level = LevelCurve.level(forTotalXP: player.totalXP)
        player.rankTier = RankTier.tier(for: player.level)
        try? context.save()
        checkForMoments(oldXP: oldXP, newXP: player.totalXP,
                        oldStreak: oldStreak, newStreak: player.currentStreak)
    }

    func updateStreak(for player: Player, context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let oldStreak = player.currentStreak
        var newDayStarted = false  // true when this is the first activity of a new day

        if let last = player.lastActiveDate {
            let lastDay = calendar.startOfDay(for: last)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            switch diff {
            case 0:
                break  // same day — streak already counted, no bonus
            case 1:
                player.currentStreak += 1
                newDayStarted = true
                if Self.freezeMilestones.contains(player.currentStreak) {
                    player.streakFreezeBalance += 1
                }
            default:
                // Streak broke — prompt user to use a freeze if they have one
                if player.streakFreezeBalance > 0 && !streakFreezePending {
                    streakFreezePending = true
                    player.lastActiveDate = today
                    player.longestStreak = max(player.longestStreak, player.currentStreak)
                    try? context.save()
                    return
                } else {
                    player.currentStreak = 1
                    newDayStarted = true
                }
            }
        } else {
            player.currentStreak = 1
            newDayStarted = true
        }

        player.lastActiveDate = today
        player.longestStreak = max(player.longestStreak, player.currentStreak)
        try? context.save()

        if Self.streakMilestones.contains(player.currentStreak) && player.currentStreak > oldStreak {
            triggerMoment(.streakMilestone(days: player.currentStreak))
        }

        // Daily streak bonus: streak × 2 XP, awarded once per day
        if newDayStarted {
            awardXP(player.currentStreak * 2, to: player, context: context)
        }
    }

    func confirmUseFreeze(for player: Player, context: ModelContext) {
        player.streakFreezeBalance -= 1
        streakFreezePending = false
        try? context.save()
    }

    func declineFreeze(for player: Player, context: ModelContext) {
        player.currentStreak = 1
        streakFreezePending = false
        try? context.save()
    }

    // MARK: - Quest & Aura

    // Evaluate all active quests against today's and this week's workout data,
    // update progress values, complete quests that hit their target, and refresh aura.
    func refreshQuestProgress(player: Player?, context: ModelContext) {
        let calendar   = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)
        let weekStart  = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? todayStart

        guard let allWorkouts    = try? context.fetch(FetchDescriptor<WorkoutEntry>()),
              let allQuests      = try? context.fetch(FetchDescriptor<Quest>()),
              let allQuickActions = try? context.fetch(FetchDescriptor<QuickActionEntry>()) else { return }

        let activeQuests = allQuests.filter { $0.isActive }
        let todayEntries = allWorkouts.filter { $0.date >= todayStart }
        let weekEntries  = allWorkouts.filter { $0.date >= weekStart }

        let todayQAIDs = allQuickActions.filter { $0.date >= todayStart }.map(\.actionID)
        let weekQAIDs  = allQuickActions.filter { $0.date >= weekStart  }.map(\.actionID)

        let todayHistory: WorkoutHistoryEntry? = todayEntries.isEmpty ? nil : WorkoutHistoryEntry(
            date: .now,
            muscleGroups: Set(todayEntries.flatMap { $0.sets.map(\.muscleGroup) }),
            setCount: todayEntries.reduce(0) { $0 + $1.totalSets },
            hasCardio: todayEntries.contains { $0.sets.contains { $0.muscleGroup == .cardio } },
            cardioMinutes: todayEntries.reduce(0) { acc, entry in
                acc + entry.sets
                    .filter { $0.muscleGroup == .cardio }
                    .reduce(0) { $0 + ($1.durationSec ?? 0) / 60 }
            },
            exerciseNames: Set(todayEntries.flatMap { $0.sets.map(\.exerciseName) }),
            totalDurationMin: todayEntries.reduce(0) { $0 + $1.durationMin },
            strengthDurationMin: todayEntries.reduce(0) { acc, entry in
                acc + entry.sets
                    .filter { $0.exerciseName == "Strength" }
                    .reduce(0) { $0 + ($1.durationSec ?? 0) / 60 }
            }
        )
        let weekHistory = weekEntries.map { entry in
            WorkoutHistoryEntry(
                date: entry.date,
                muscleGroups: entry.muscleGroups,
                setCount: entry.totalSets,
                hasCardio: entry.sets.contains { $0.muscleGroup == .cardio },
                cardioMinutes: entry.sets
                    .filter { $0.muscleGroup == .cardio }
                    .reduce(0) { $0 + ($1.durationSec ?? 0) / 60 },
                exerciseNames: Set(entry.sets.map(\.exerciseName)),
                totalDurationMin: entry.durationMin,
                strengthDurationMin: entry.sets
                    .filter { $0.exerciseName == "Strength" }
                    .reduce(0) { $0 + ($1.durationSec ?? 0) / 60 }
            )
        }

        for quest in activeQuests {
            let newValue = QuestEngine.evaluateProgress(
                templateID: quest.templateID,
                todayWorkout: todayHistory,
                weekWorkouts: weekHistory,
                todayQuickActionIDs: todayQAIDs,
                weekQuickActionIDs: weekQAIDs
            )
            quest.currentValue = newValue
            guard !quest.isCompleted, newValue >= quest.targetValue else { continue }
            quest.isCompleted  = true
            quest.completedAt  = .now
            if let player {
                awardXP(quest.xpReward, to: player, context: context)
                if quest.rewardType == .streakFreeze {
                    player.streakFreezeBalance += 1
                }
            }
        }

        // Recompute aura from consistency (streak) + variety (weekly goal balance)
        if let player {
            let consistencyFraction = min(Double(player.currentStreak) / 30.0, 1.0)
            let varietyFraction = computeVariety(player: player, weekEntries: weekEntries)
            player.auraScore = AuraCalculator.compute(
                consistencyFraction: consistencyFraction,
                varietyFraction: varietyFraction
            )
        }

        try? context.save()
    }

    // Variety: how balanced the user is across all 5 activity types vs their weekly goals.
    // Score = 60% average completion + 40% weakest-link, so neglecting one type drags it down.
    private func computeVariety(player: Player, weekEntries: [WorkoutEntry]) -> Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        func uniqueDays(matching: (WorkoutEntry) -> Bool) -> Int {
            Set(weekEntries.filter(matching).map { formatter.string(from: $0.date) }).count
        }

        var ratios: [Double] = []
        for type in ActivityType.allCases {
            let goal = player.goal(for: type)
            guard goal > 0 else { continue }

            let actual: Int
            switch type {
            case .strength:
                actual = uniqueDays { $0.sets.contains { $0.exerciseName == "Strength" } }
            case .cardio:
                actual = uniqueDays { $0.sets.contains { $0.muscleGroup == .cardio } }
            case .stretching:
                actual = uniqueDays { $0.sets.contains { $0.exerciseName == "Stretching" } }
            case .back:
                actual = uniqueDays { $0.sets.contains { $0.exerciseName == "Back Pain Prevention" } }
            case .sleep:
                actual = uniqueDays { $0.sets.contains { $0.exerciseName == "Sleep" } }
            }

            ratios.append(min(Double(actual) / Double(goal), 1.0))
        }

        guard !ratios.isEmpty else { return 0 }
        let avg = ratios.reduce(0, +) / Double(ratios.count)
        let minRatio = ratios.min() ?? 0
        return avg * 0.6 + minRatio * 0.4
    }
}
