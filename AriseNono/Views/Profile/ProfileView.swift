import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var players: [Player]
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var workouts: [WorkoutEntry]
    @Environment(\.modelContext) private var context

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
            statCard("Total XP",    value: "\(player.totalXP)",               accent: AppTheme.C.gold)
            statCard("Sessions",    value: "\(workouts.count)",                accent: AppTheme.C.cyan)
            statCard("Best Streak", value: "\(player.longestStreak)d",        accent: AppTheme.C.mag)
            statCard("Cur. Streak", value: "\(player.currentStreak)d",        accent: AppTheme.C.cyan)
            statCard("Freezes",     value: "\(player.streakFreezeBalance)",    accent: AppTheme.C.smoke)
            statCard("Aura",        value: String(format: "%.0f", player.auraScore), accent: AppTheme.C.mag)
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
                .monospacedDigit()
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
            auraBar("Variety",     fraction: varietyFraction, color: AppTheme.C.mag)

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
                .monospacedDigit()
        }
    }

    private var varietyFraction: Double {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -14, to: .now)!
        let groups = Set(workouts.filter { $0.date >= cutoff }.flatMap { $0.sets.map(\.muscleGroup) })
        return Double(groups.count) / 7.0
    }
}
