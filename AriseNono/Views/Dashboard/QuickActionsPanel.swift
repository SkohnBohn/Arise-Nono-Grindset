import SwiftUI
import SwiftData

struct QuickActionsPanel: View {
    let player: Player
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context

    @State private var pressed: String? = nil

    private struct Action: Identifiable {
        let id: String
        let label: String
        let icon: String
        let xp: Int
    }

    private let upper: [Action] = [
        Action(id: "stretch",  label: "stretching\n5 min",          icon: "figure.flexibility",    xp: 10),
        Action(id: "cardio",   label: "casual cardio\n10 min",      icon: "figure.outdoor.cycle",  xp: 10),
        Action(id: "burst",    label: "burst",                       icon: "bolt.fill",             xp: 10),
    ]

    private let lower: [Action] = [
        Action(id: "back",     label: "back pain\nprevention 15 min", icon: "figure.core.training", xp: 10),
        Action(id: "sleep",    label: "slept\nproperly",              icon: "moon.zzz.fill",         xp: 10),
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
        let isLarge = height > 80
        Button {
            triggerAction(action)
        } label: {
            VStack(spacing: isLarge ? 6 : 4) {
                Image(systemName: action.icon)
                    .font(.system(size: isLarge ? 26 : 18, weight: .light))
                    .foregroundStyle(pressed == action.id ? AppTheme.C.gold : AppTheme.C.cyan)
                    .neonGlow(color: pressed == action.id ? AppTheme.C.gold : AppTheme.C.cyan, radius: pressed == action.id ? 8 : 4)
                Text(action.label)
                    .font(AppTheme.T.mono(isLarge ? 9 : 8))
                    .foregroundStyle(AppTheme.C.ash)
                    .multilineTextAlignment(.center)
                    .kerning(0.3)
                    .lineSpacing(1)
                Text("+\(action.xp) XP")
                    .font(AppTheme.T.mono(8))
                    .foregroundStyle(AppTheme.C.gold.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .hudPanel(cut: isLarge ? 10 : 6,
                      corners: isLarge ? [.topRight, .bottomLeft] : .topRight,
                      border: pressed == action.id ? AppTheme.C.gold.opacity(0.6) : AppTheme.C.cyanDim.opacity(0.5))
            .scaleEffect(pressed == action.id ? 0.95 : 1.0)
            .animation(.spring(duration: 0.15), value: pressed)
        }
        .buttonStyle(.plain)
    }

    private func triggerAction(_ action: Action) {
        pressed = action.id
        appState.awardXP(action.xp, to: player, context: context)
        let entry = QuickActionEntry(actionID: action.id)
        context.insert(entry)
        try? context.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            pressed = nil
        }
    }
}
