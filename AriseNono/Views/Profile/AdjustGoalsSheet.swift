import SwiftUI
import SwiftData

struct AdjustGoalsSheet: View {
    let player: Player
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var strengthGoal: Int
    @State private var cardioGoal: Int
    @State private var stretchGoal: Int
    @State private var backGoal: Int
    @State private var sleepGoal: Int

    init(player: Player) {
        self.player = player
        _strengthGoal = State(initialValue: player.goalStrengthDays)
        _cardioGoal   = State(initialValue: player.goalCardioDays)
        _stretchGoal  = State(initialValue: player.goalStretchDays)
        _backGoal     = State(initialValue: player.goalBackDays)
        _sleepGoal    = State(initialValue: player.goalSleepDays)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 10) {
                        Text("Set how many days per week you want to complete each activity.")
                            .font(AppTheme.T.body(13))
                            .foregroundStyle(AppTheme.C.smoke)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 4)

                        goalRow(.strength, value: $strengthGoal)
                        goalRow(.cardio,   value: $cardioGoal)
                        goalRow(.stretching, value: $stretchGoal)
                        goalRow(.back,     value: $backGoal)
                        goalRow(.sleep,    value: $sleepGoal)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ADJUST GOALS")
                        .font(AppTheme.T.heading(14))
                        .foregroundStyle(AppTheme.C.snow)
                        .kerning(3)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.C.smoke)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(AppTheme.C.cyan)
                        .fontWeight(.bold)
                }
            }
        }
    }

    @ViewBuilder
    private func goalRow(_ type: ActivityType, value: Binding<Int>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundStyle(type.color)
                .neonGlow(color: type.color, radius: 4)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(type.label)
                    .font(AppTheme.T.mono(10))
                    .foregroundStyle(AppTheme.C.ash)
                    .kerning(1)
                Text("days / week")
                    .font(AppTheme.T.mono(9))
                    .foregroundStyle(AppTheme.C.smoke)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    if value.wrappedValue > 0 { value.wrappedValue -= 1 }
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(value.wrappedValue > 0 ? AppTheme.C.cyanDim : AppTheme.C.rim)
                }
                .buttonStyle(.plain)

                Text("\(value.wrappedValue)")
                    .font(AppTheme.T.mono(22))
                    .foregroundStyle(type.color)
                    .fontWeight(.bold)
                    .neonGlow(color: type.color, radius: 3)
                    .frame(width: 28, alignment: .center)
                    .monospacedDigit()

                Button {
                    if value.wrappedValue < 7 { value.wrappedValue += 1 }
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(value.wrappedValue < 7 ? AppTheme.C.cyan : AppTheme.C.rim)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .hudPanel(cut: 8, corners: [.topRight, .bottomLeft])
    }

    private func save() {
        player.goalStrengthDays = strengthGoal
        player.goalCardioDays   = cardioGoal
        player.goalStretchDays  = stretchGoal
        player.goalBackDays     = backGoal
        player.goalSleepDays    = sleepGoal
        try? context.save()
        dismiss()
    }
}
