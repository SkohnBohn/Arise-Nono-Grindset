import SwiftUI
import SwiftData

struct QuickActionsPanel: View {
    let player: Player
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Query private var allQuickActions: [QuickActionEntry]

    @State private var pendingCounts: [String: Int] = [:]
    @State private var debounceTasks: [String: Task<Void, Never>] = [:]
    @State private var firstTapDate: [String: Date] = [:]
    @State private var streakBonusResult: StreakBonusResult?

    private var todayLoggedIDs: Set<String> {
        let start = Calendar.current.startOfDay(for: .now)
        return Set(allQuickActions.filter { $0.date >= start }.map(\.actionID))
    }

    private struct Action: Identifiable {
        let id: String
        let label: String
        let icon: String
        let xp: Int
        let baseDurationMin: Int
        let exerciseName: String
        let muscleGroup: MuscleGroup
    }

    private let upper: [Action] = [
        Action(id: "stretch", label: "stretching\n5 min",           icon: "figure.flexibility",   xp: 10, baseDurationMin: 5,  exerciseName: "Stretching",           muscleGroup: .core),
        Action(id: "cardio",  label: "casual cardio\n10 min",       icon: "figure.outdoor.cycle", xp: 10, baseDurationMin: 10, exerciseName: "Cardio",               muscleGroup: .cardio),
        Action(id: "burst",   label: "burst",                        icon: "bolt.fill",            xp: 10, baseDurationMin: 5,  exerciseName: "Burst",                muscleGroup: .core),
    ]

    private let lower: [Action] = [
        Action(id: "back",  label: "back pain\nprevention 15 min", icon: "figure.core.training", xp: 10, baseDurationMin: 15, exerciseName: "Back Pain Prevention", muscleGroup: .core),
        Action(id: "sleep", label: "slept\nproperly",              icon: "moon.zzz.fill",        xp: 10, baseDurationMin: 0,  exerciseName: "Sleep",                muscleGroup: .core),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUICK ACTIONS")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.cyan)
                .kerning(2)

            HStack(spacing: 8) {
                ForEach(upper) { action in
                    actionButton(action, height: 92)
                }
            }

            HStack(spacing: 8) {
                ForEach(lower) { action in
                    actionButton(action, height: 68)
                }
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
        .fullScreenCover(item: $streakBonusResult) { result in
            StreakBonusView(streak: result.streak, bonusXP: result.bonusXP) {
                streakBonusResult = nil
            }
        }
    }

    @ViewBuilder
    private func actionButton(_ action: Action, height: CGFloat) -> some View {
        let count     = pendingCounts[action.id] ?? 0
        let isPending = count > 0
        let isDone    = todayLoggedIDs.contains(action.id)
        let isLarge   = height > 80

        // Colour priority: pending tap (gold) > done today (mag) > default (cyan)
        let accentColor: Color = isPending ? AppTheme.C.gold : isDone ? AppTheme.C.mag : AppTheme.C.cyan
        let iconRadius: CGFloat = isPending ? 8 : isDone ? 5 : 4

        Button {
            triggerAction(action)
        } label: {
            VStack(spacing: isLarge ? 6 : 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: action.icon)
                        .font(.system(size: isLarge ? 26 : 18, weight: .light))
                        .foregroundStyle(accentColor)
                        .neonGlow(color: accentColor, radius: iconRadius)

                    if isDone && !isPending {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.C.mag)
                            .offset(x: 6, y: -4)
                    }
                }
                Text(action.label)
                    .font(AppTheme.T.mono(isLarge ? 9 : 8))
                    .foregroundStyle(isDone && !isPending ? AppTheme.C.mag.opacity(0.8) : AppTheme.C.ash)
                    .multilineTextAlignment(.center)
                    .kerning(0.3)
                    .lineSpacing(1)
                if count > 1 {
                    Text("×\(count)  +\(count * action.xp) XP")
                        .font(AppTheme.T.mono(8))
                        .foregroundStyle(AppTheme.C.gold)
                        .neonGlow(color: AppTheme.C.gold, radius: 3)
                        .monospacedDigit()
                } else {
                    Text("+\(action.xp) XP")
                        .font(AppTheme.T.mono(8))
                        .foregroundStyle(accentColor.opacity(isPending ? 1.0 : 0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .hudPanel(
                cut: isLarge ? 10 : 6,
                corners: isLarge ? [.topRight, .bottomLeft] : .topRight,
                border: accentColor.opacity(isDone || isPending ? 0.6 : 0.5)
            )
            .scaleEffect(isPending ? 0.97 : 1.0)
            .animation(.spring(duration: 0.15), value: count)
            .animation(.easeInOut(duration: 0.3), value: isDone)
        }
        .buttonStyle(.plain)
    }

    private func triggerAction(_ action: Action) {
        let count = (pendingCounts[action.id] ?? 0) + 1
        pendingCounts[action.id] = count

        if count == 1 {
            firstTapDate[action.id] = .now
        }

        // Award XP immediately per tap for instant feedback
        appState.awardXP(action.xp, to: player, context: context)

        // Cancel any existing debounce and restart the 1-second window
        debounceTasks[action.id]?.cancel()
        debounceTasks[action.id] = Task {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return  // cancelled — another tap came in
            }
            await MainActor.run { commitAction(action) }
        }
    }

    // MARK: - Streak bonus types

    struct StreakBonusResult: Identifiable {
        let id = UUID()
        let streak: Int
        let bonusXP: Int
    }

    @MainActor
    private func commitAction(_ action: Action) {
        let count = pendingCounts[action.id] ?? 1
        let date = firstTapDate[action.id] ?? .now
        let totalDuration = count * action.baseDurationMin
        let totalXP = count * action.xp

        // WorkoutEntry so it appears in the log
        let entry = WorkoutEntry(date: date, notes: "", durationMin: totalDuration)
        entry.xpAwarded = totalXP
        context.insert(entry)

        let s = ExerciseSet(
            exerciseName: action.exerciseName,
            muscleGroup: action.muscleGroup,
            setNumber: 1,
            durationSec: totalDuration > 0 ? totalDuration * 60 : nil
        )
        s.entry = entry
        context.insert(s)
        entry.sets = [s]

        // QuickActionEntry for the heatmap (one per committed session)
        let qe = QuickActionEntry(date: date, actionID: action.id)
        context.insert(qe)

        try? context.save()

        let streakResult = appState.updateStreak(for: player, context: context)
        appState.refreshQuestProgress(player: player, context: context)
        if streakResult.bonusXP > 0 {
            streakBonusResult = StreakBonusResult(streak: streakResult.streak, bonusXP: streakResult.bonusXP)
        }

        // Reset debounce state
        pendingCounts[action.id] = 0
        debounceTasks[action.id] = nil
        firstTapDate[action.id] = nil
    }
}

// MARK: - Streak Bonus Screen

struct StreakBonusView: View {
    let streak: Int
    let bonusXP: Int
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("STREAK EXTENDED")
                    .font(AppTheme.T.mono(11))
                    .foregroundStyle(AppTheme.C.gold)
                    .kerning(4)
                    .neonGlow(color: AppTheme.C.gold, radius: 4)
                    .padding(.top, 72)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                Spacer()

                VStack(spacing: 20) {
                    Text("🔥")
                        .font(.system(size: 72))
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.5, bounce: 0.4), value: appeared)

                    Text("DAY \(streak)")
                        .font(AppTheme.T.mono(52))
                        .foregroundStyle(AppTheme.C.gold)
                        .fontWeight(.bold)
                        .neonGlow(color: AppTheme.C.gold, radius: 12)
                        .monospacedDigit()
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
                }

                Spacer()

                VStack(spacing: 14) {
                    Text("+\(bonusXP) STREAK XP")
                        .font(AppTheme.T.mono(22))
                        .foregroundStyle(AppTheme.C.gold.opacity(0.85))
                        .monospacedDigit()
                        .neonGlow(color: AppTheme.C.gold, radius: 5)

                    Button(action: onDismiss) {
                        Text("NAH, I'D GRIND")
                            .font(AppTheme.T.heading(15))
                            .foregroundStyle(AppTheme.C.void)
                            .kerning(3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.C.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .neonGlow(color: AppTheme.C.gold, radius: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 32)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
                .padding(.bottom, 52)
            }
        }
        .onTapGesture { onDismiss() }
        .onAppear { appeared = true }
    }
}
