import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var players: [Player]
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var workouts: [WorkoutEntry]
    @Query(sort: \NutritionEntry.date, order: .reverse) private var nutritionEntries: [NutritionEntry]
    @Environment(\.modelContext) private var context
    @State private var showingGoals = false

    private var player: Player? { players.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                ScanlineOverlay()

                ScrollView {
                    VStack(spacing: 16) {
                        if let player {
                            rankBadgeSection(player)
                            statsGrid(player)
                            auraBreakdown(player)
                            goalsSection(player)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PROFILE")
                        .font(AppTheme.T.heading(15))
                        .foregroundStyle(AppTheme.C.snow)
                        .kerning(3)
                }
            }
            .sheet(isPresented: $showingGoals) {
                if let player { GoalsSheet(player: player) }
            }
        }
    }

    @ViewBuilder
    private func rankBadgeSection(_ player: Player) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(AppTheme.C.rank(player.rankTier), lineWidth: 3)
                    .frame(width: 90, height: 90)
                    .neonGlow(color: AppTheme.C.rank(player.rankTier), radius: 12)
                Image(systemName: "person.fill")
                    .resizable().scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(AppTheme.C.smoke)
            }
            Text(player.name.uppercased())
                .font(AppTheme.T.heading(22))
                .foregroundStyle(AppTheme.C.snow)
                .kerning(2)
            Text(player.rankTier.displayName.uppercased())
                .font(AppTheme.T.mono(12))
                .foregroundStyle(AppTheme.C.rank(player.rankTier))
                .kerning(4)
                .neonGlow(color: AppTheme.C.rank(player.rankTier), radius: 5)
            XPBarView(fraction: player.levelFraction)
                .frame(width: 200)
            Text("Level \(player.level) — \(player.xpProgressInLevel) / \(player.xpForNextLevel) XP")
                .font(AppTheme.T.mono(11))
                .foregroundStyle(AppTheme.C.smoke)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .hudPanel(cut: 16, corners: [.topRight, .bottomLeft])
    }

    @ViewBuilder
    private func statsGrid(_ player: Player) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            statCard("Total XP", value: "\(player.totalXP)", accent: AppTheme.C.gold)
            statCard("Sessions", value: "\(workouts.count)", accent: AppTheme.C.cyan)
            statCard("Best Streak", value: "\(player.longestStreak)d", accent: AppTheme.C.mag)
            statCard("Current Streak", value: "\(player.currentStreak)d", accent: AppTheme.C.cyan)
            statCard("Freezes", value: "\(player.streakFreezeBalance)", accent: AppTheme.C.smoke)
            statCard("Aura", value: String(format: "%.0f", player.auraScore), accent: AppTheme.C.mag)
        }
    }

    @ViewBuilder
    private func statCard(_ label: String, value: String, accent: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.T.mono(20))
                .foregroundStyle(accent)
                .fontWeight(.bold)
                .neonGlow(color: accent, radius: 4)
                .fontVariantNumeric(.tabularNums)
            Text(label.uppercased())
                .font(AppTheme.T.mono(8))
                .foregroundStyle(AppTheme.C.smoke)
                .kerning(1)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .hudPanel(cut: 6, corners: .topRight)
    }

    @ViewBuilder
    private func auraBreakdown(_ player: Player) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AURA BREAKDOWN")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.mag)
                .kerning(2)

            auraBar("Consistency", fraction: min(Double(player.currentStreak) / 30.0, 1), color: AppTheme.C.cyan)
            auraBar("Variety", fraction: varietyFraction, color: AppTheme.C.mag)
            auraBar("Nutrition", fraction: nutritionAdherence, color: AppTheme.C.gold)

            Text("Overall Aura: \(Int(player.auraScore)) / 1000")
                .font(AppTheme.T.mono(13))
                .foregroundStyle(AppTheme.C.ash)
        }
        .padding(14)
        .hudPanel(cut: 10, corners: [.topRight, .bottomLeft], border: AppTheme.C.magDim)
    }

    @ViewBuilder
    private func auraBar(_ label: String, fraction: Double, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(label.uppercased())
                .font(AppTheme.T.mono(9))
                .foregroundStyle(AppTheme.C.smoke)
                .frame(width: 88, alignment: .leading)
                .kerning(1)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(AppTheme.C.rim).frame(height: 4)
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * fraction, height: 4)
                        .neonGlow(color: color, radius: 3)
                }
            }
            .frame(height: 4)
            Text("\(Int(fraction * 100))%")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.smoke)
                .frame(width: 32, alignment: .trailing)
                .fontVariantNumeric(.tabularNums)
        }
    }

    private var varietyFraction: Double {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -14, to: .now)!
        let groups = Set(workouts.filter { $0.date >= cutoff }.flatMap { $0.sets.map(\.muscleGroup) })
        return Double(groups.count) / 7.0
    }

    private var nutritionAdherence: Double {
        let recent = nutritionEntries.prefix(7).map(\.adherenceScore)
        guard !recent.isEmpty else { return 0 }
        return recent.reduce(0, +) / Double(recent.count)
    }

    @ViewBuilder
    private func goalsSection(_ player: Player) -> some View {
        Button {
            showingGoals = true
        } label: {
            HStack {
                Text("NUTRITION GOALS")
                    .font(AppTheme.T.heading(13))
                    .foregroundStyle(AppTheme.C.ash)
                    .kerning(2)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.C.cyanDim)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .hudPanel(cut: 8, corners: .topRight)
    }
}

struct GoalsSheet: View {
    @Bindable var player: Player
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        goalField("Calories (kcal)", value: Binding(
                            get: { String(player.goalCalories) },
                            set: { player.goalCalories = Int($0) ?? player.goalCalories }
                        ))
                        goalField("Protein (g)", value: Binding(
                            get: { String(format: "%.0f", player.goalProteinG) },
                            set: { player.goalProteinG = Double($0) ?? player.goalProteinG }
                        ))
                        goalField("Fiber (g)", value: Binding(
                            get: { String(format: "%.0f", player.goalFiberG) },
                            set: { player.goalFiberG = Double($0) ?? player.goalFiberG }
                        ))
                        goalField("Max Added Sugar (g)", value: Binding(
                            get: { String(format: "%.0f", player.goalMaxSugarG) },
                            set: { player.goalMaxSugarG = Double($0) ?? player.goalMaxSugarG }
                        ))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("EATING WINDOW")
                                .font(AppTheme.T.mono(9))
                                .foregroundStyle(AppTheme.C.smoke)
                                .kerning(2)
                            Stepper("\(player.goalEatingWindowH) hours", value: $player.goalEatingWindowH, in: 6...24)
                                .foregroundStyle(AppTheme.C.ash)
                        }
                        .padding(14)
                        .hudPanel()

                        Text("⚠️ These are personal goals, not medical advice. Consult a healthcare professional before making significant dietary changes.")
                            .font(AppTheme.T.body(11))
                            .foregroundStyle(AppTheme.C.smoke)
                            .multilineTextAlignment(.center)
                            .padding(14)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.C.cyan)
                }
            }
        }
    }

    @ViewBuilder
    private func goalField(_ label: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(AppTheme.T.mono(9))
                .foregroundStyle(AppTheme.C.smoke)
                .kerning(1.5)
            TextField("", text: value)
                .keyboardType(.numberPad)
                .font(AppTheme.T.mono(18))
                .foregroundStyle(AppTheme.C.cyan)
        }
        .padding(12)
        .hudPanel()
    }
}
