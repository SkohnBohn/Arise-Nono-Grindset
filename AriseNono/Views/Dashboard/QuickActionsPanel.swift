import SwiftUI
import SwiftData

struct QuickActionsPanel: View {
    let player: Player
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context

    @State private var pendingCounts: [String: Int] = [:]
    @State private var debounceTasks: [String: Task<Void, Never>] = [:]
    @State private var firstTapDate: [String: Date] = [:]

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
    }

    @ViewBuilder
    private func actionButton(_ action: Action, height: CGFloat) -> some View {
        let count = pendingCounts[action.id] ?? 0
        let isActive = count > 0
        let isLarge = height > 80

        Button {
            triggerAction(action)
        } label: {
            VStack(spacing: isLarge ? 6 : 4) {
                Image(systemName: action.icon)
                    .font(.system(size: isLarge ? 26 : 18, weight: .light))
                    .foregroundStyle(isActive ? AppTheme.C.gold : AppTheme.C.cyan)
                    .neonGlow(color: isActive ? AppTheme.C.gold : AppTheme.C.cyan, radius: isActive ? 8 : 4)
                Text(action.label)
                    .font(AppTheme.T.mono(isLarge ? 9 : 8))
                    .foregroundStyle(AppTheme.C.ash)
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
                        .foregroundStyle(AppTheme.C.gold.opacity(isActive ? 1.0 : 0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .hudPanel(
                cut: isLarge ? 10 : 6,
                corners: isLarge ? [.topRight, .bottomLeft] : .topRight,
                border: isActive ? AppTheme.C.gold.opacity(0.6) : AppTheme.C.cyanDim.opacity(0.5)
            )
            .scaleEffect(isActive ? 0.97 : 1.0)
            .animation(.spring(duration: 0.15), value: count)
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

        // Reset debounce state
        pendingCounts[action.id] = 0
        debounceTasks[action.id] = nil
        firstTapDate[action.id] = nil
    }
}
