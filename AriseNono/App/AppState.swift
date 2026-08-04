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

    private static let streakMilestones: Set<Int> = [7, 14, 30, 60, 100, 365]

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
        // Rank-up always wins; streak milestone defers to level events
        switch (activeMoment, moment) {
        case (.rankUp, _):           return
        case (_, .rankUp):           activeMoment = moment
        case (.levelUp, .streakMilestone): return
        default:                     activeMoment = moment
        }
    }

    func dismissMoment() {
        withAnimation(.easeOut(duration: 0.3)) { activeMoment = nil }
    }

    // MARK: - Player Helpers

    func awardXP(_ amount: Int, to player: Player, context: ModelContext) {
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

        if let last = player.lastActiveDate {
            let lastDay = calendar.startOfDay(for: last)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            switch diff {
            case 0:  break // already logged today
            case 1:  player.currentStreak += 1
            default:
                if player.streakFreezeBalance > 0 {
                    player.streakFreezeBalance -= 1
                } else {
                    player.currentStreak = 1
                }
            }
        } else {
            player.currentStreak = 1
        }

        player.lastActiveDate = today
        player.longestStreak = max(player.longestStreak, player.currentStreak)
        try? context.save()

        if AppState.streakMilestones.contains(player.currentStreak) && player.currentStreak > oldStreak {
            triggerMoment(.streakMilestone(days: player.currentStreak))
        }
    }

    func updateAura(for player: Player, workoutHistory: [WorkoutEntry],
                    nutritionHistory: [NutritionEntry], context: ModelContext) {
        let calendar = Calendar.current
        let now = Date.now

        let days30 = workoutHistory.filter {
            (calendar.dateComponents([.day], from: $0.date, to: now).day ?? 0) <= 30
        }.count

        let uniqueGroups14d = Set(
            workoutHistory
                .filter { (calendar.dateComponents([.day], from: $0.date, to: now).day ?? 0) <= 14 }
                .flatMap { $0.sets.map(\.muscleGroup) }
        ).count

        let recentNutrition = nutritionHistory.prefix(7).map(\.adherenceScore)
        let avgAdherence = recentNutrition.isEmpty ? 0 :
            recentNutrition.reduce(0, +) / Double(recentNutrition.count)

        let input = AuraInput(
            activeDays30: days30,
            currentStreak: player.currentStreak,
            uniqueMuscleGroups14d: uniqueGroups14d,
            avgNutritionAdherence7d: avgAdherence
        )
        player.auraScore = AuraCalculator.compute(input: input)
        try? context.save()
    }
}
