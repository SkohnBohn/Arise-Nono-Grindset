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

    @discardableResult
    func updateStreak(for player: Player, context: ModelContext) -> (streak: Int, bonusXP: Int) {
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
                    return (player.currentStreak, 0)
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
            let bonus = player.currentStreak * 2
            awardXP(bonus, to: player, context: context)
            return (player.currentStreak, bonus)
        }
        return (player.currentStreak, 0)
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
        let weekEntries  = allWorkouts.filter { $0.date >= weekStart }

        for quest in activeQuests {
            // Only count activities that happened after this quest was created.
            // This prevents freshly generated quests from instantly completing
            // because the user already logged something earlier in the day.
            let effectiveTodayStart = max(todayStart, quest.createdAt)
            let effectiveWeekStart  = max(weekStart,  quest.createdAt)

            let qTodayEntries = allWorkouts.filter { $0.date >= effectiveTodayStart }
            let qWeekEntries  = allWorkouts.filter { $0.date >= effectiveWeekStart  }
            let qTodayQAIDs   = allQuickActions.filter { $0.date >= effectiveTodayStart }.map(\.actionID)
            let qWeekQAIDs    = allQuickActions.filter { $0.date >= effectiveWeekStart  }.map(\.actionID)

            let qTodayHistory: WorkoutHistoryEntry? = qTodayEntries.isEmpty ? nil : WorkoutHistoryEntry(
                date: .now,
                muscleGroups: Set(qTodayEntries.flatMap { $0.sets.map(\.muscleGroup) }),
                setCount: qTodayEntries.reduce(0) { $0 + $1.totalSets },
                hasCardio: qTodayEntries.contains { $0.sets.contains { $0.muscleGroup == .cardio } },
                cardioMinutes: qTodayEntries.reduce(0) { acc, e in
                    acc + e.sets.filter { $0.muscleGroup == .cardio }.reduce(0) { $0 + ($1.durationSec ?? 0) / 60 }
                },
                exerciseNames: Set(qTodayEntries.flatMap { $0.sets.map(\.exerciseName) }),
                totalDurationMin: qTodayEntries.reduce(0) { $0 + $1.durationMin },
                strengthDurationMin: qTodayEntries.reduce(0) { acc, e in
                    acc + e.sets.filter { $0.exerciseName == "Strength" }.reduce(0) { $0 + ($1.durationSec ?? 0) / 60 }
                }
            )
            let qWeekHistory = qWeekEntries.map { e in
                WorkoutHistoryEntry(
                    date: e.date,
                    muscleGroups: e.muscleGroups,
                    setCount: e.totalSets,
                    hasCardio: e.sets.contains { $0.muscleGroup == .cardio },
                    cardioMinutes: e.sets.filter { $0.muscleGroup == .cardio }.reduce(0) { $0 + ($1.durationSec ?? 0) / 60 },
                    exerciseNames: Set(e.sets.map(\.exerciseName)),
                    totalDurationMin: e.durationMin,
                    strengthDurationMin: e.sets.filter { $0.exerciseName == "Strength" }.reduce(0) { $0 + ($1.durationSec ?? 0) / 60 }
                )
            }

            let newValue = QuestEngine.evaluateProgress(
                templateID: quest.templateID,
                todayWorkout: qTodayHistory,
                weekWorkouts: qWeekHistory,
                todayQuickActionIDs: qTodayQAIDs,
                weekQuickActionIDs: qWeekQAIDs
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
            let weekQAs = allQuickActions.filter { $0.date >= weekStart }
            let varietyFraction = computeVariety(player: player, weekEntries: weekEntries, weekQuickActions: weekQAs)
            player.auraScore = AuraCalculator.compute(
                consistencyFraction: consistencyFraction,
                varietyFraction: varietyFraction
            )
        }

        try? context.save()
    }

    // Variety: how balanced the user is across all 5 activity types vs their weekly goals.
    // Score = 60% average completion + 40% weakest-link, so neglecting one type drags it down.
    private func computeVariety(player: Player, weekEntries: [WorkoutEntry], weekQuickActions: [QuickActionEntry] = []) -> Double {
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
            case .water:
                var dayCounts: [String: Int] = [:]
                for q in weekQuickActions where q.actionID == "water" {
                    dayCounts[formatter.string(from: q.date), default: 0] += 1
                }
                actual = dayCounts.values.filter { $0 >= 2 }.count
            }

            ratios.append(min(Double(actual) / Double(goal), 1.0))
        }

        guard !ratios.isEmpty else { return 0 }
        let avg = ratios.reduce(0, +) / Double(ratios.count)
        let minRatio = ratios.min() ?? 0
        return avg * 0.6 + minRatio * 0.4
    }
}
