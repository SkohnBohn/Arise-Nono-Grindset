import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context

    @Query private var players: [Player]
    @Query(sort: \Quest.expiresAt) private var allQuests: [Quest]
    @Query(sort: \NutritionEntry.date, order: .reverse) private var nutritionEntries: [NutritionEntry]

    private var player: Player? { players.first }
    private var dailyQuests: [Quest] { allQuests.filter { $0.type == .daily && $0.isActive } }

    private var todayNutrition: NutritionEntry? {
        let today = Calendar.current.startOfDay(for: .now)
        return nutritionEntries.first { Calendar.current.startOfDay(for: $0.date) == today }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                ScanlineOverlay()

                ScrollView {
                    VStack(spacing: 16) {
                        if let player {
                            PlayerCardView(player: player)
                        }

                        QuestStripView(quests: Array(dailyQuests.prefix(3)))

                        // Today's nutrition ring
                        if let nutrition = todayNutrition, let player {
                            NutritionRingRow(entry: nutrition, player: player)
                        } else if let player {
                            nutritionCTA(player: player)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ARISE")
                        .font(AppTheme.T.heading(18))
                        .foregroundStyle(AppTheme.C.cyan)
                        .kerning(6)
                        .neonGlow(color: AppTheme.C.cyan, radius: 6)
                }
            }
        }
    }

    @ViewBuilder
    private func nutritionCTA(player: Player) -> some View {
        HStack {
            Image(systemName: "leaf.fill")
                .foregroundStyle(AppTheme.C.gold)
            Text("Log today's nutrition to earn Aura")
                .font(AppTheme.T.body(13))
                .foregroundStyle(AppTheme.C.smoke)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hudPanel(cut: 8, corners: .topRight, border: AppTheme.C.magDim)
    }
}

struct NutritionRingRow: View {
    let entry: NutritionEntry
    let player: Player

    var proteinFraction: Double { min(entry.totalProteinG / max(player.goalProteinG, 1), 1) }
    var calorieFraction: Double { min(Double(entry.totalCalories) / Double(max(player.goalCalories, 1)), 1) }
    var fiberFraction: Double   { min(entry.totalFiberG / max(player.goalFiberG, 1), 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S NUTRITION")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.cyan)
                .kerning(2)

            HStack(spacing: 20) {
                miniRing(label: "Protein", fraction: proteinFraction, color: AppTheme.C.cyan)
                miniRing(label: "Calories", fraction: calorieFraction, color: AppTheme.C.gold)
                miniRing(label: "Fiber", fraction: fiberFraction, color: Color(hex: "00FF88"))
                Spacer()
                adherenceScore
            }
        }
        .padding(14)
        .hudPanel(cut: 10, corners: [.topRight, .bottomLeft])
    }

    @ViewBuilder
    private func miniRing(label: String, fraction: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().stroke(AppTheme.C.rim, lineWidth: 4).frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 44, height: 44)
                    .neonGlow(color: color, radius: 4)
            }
            Text(label.uppercased())
                .font(AppTheme.T.mono(8))
                .foregroundStyle(AppTheme.C.smoke)
        }
    }

    private var adherenceScore: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("ADHERENCE")
                .font(AppTheme.T.mono(8))
                .foregroundStyle(AppTheme.C.smoke)
                .kerning(1)
            Text("\(Int(entry.adherenceScore * 100))%")
                .font(AppTheme.T.mono(22))
                .foregroundStyle(AppTheme.C.gold)
                .fontWeight(.bold)
                .neonGlow(color: AppTheme.C.gold, radius: 4)
        }
    }
}
