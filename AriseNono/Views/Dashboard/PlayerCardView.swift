import SwiftUI

struct PlayerCardView: View {
    let player: Player

    var body: some View {
        VStack(spacing: 0) {
            // Rank strip
            HStack {
                Text(player.rankTier.displayName.uppercased())
                    .font(AppTheme.T.mono(10))
                    .foregroundStyle(AppTheme.C.rank(player.rankTier))
                    .kerning(3)
                    .neonGlow(color: AppTheme.C.rank(player.rankTier), radius: 6)
                Spacer()
                Text("LVL \(player.level)")
                    .font(AppTheme.T.heading(22))
                    .foregroundStyle(AppTheme.C.snow)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Avatar placeholder + aura ring
            ZStack {
                Circle()
                    .stroke(AppTheme.C.rank(player.rankTier).opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .neonGlow(color: AppTheme.C.rank(player.rankTier), radius: 8)

                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .foregroundStyle(AppTheme.C.smoke)
            }
            .padding(.vertical, 16)

            // Player name
            Text(player.name.uppercased())
                .font(AppTheme.T.heading(20))
                .foregroundStyle(AppTheme.C.snow)
                .kerning(2)

            // XP bar
            VStack(spacing: 6) {
                XPBarView(fraction: player.levelFraction,
                          label: "XP — \(player.xpProgressInLevel) / \(player.xpForNextLevel)")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Stats row
            HStack(spacing: 0) {
                statCell(label: "Streak", value: "\(player.currentStreak)d")
                Divider().background(AppTheme.C.rim).frame(height: 32)
                statCell(label: "Aura", value: String(format: "%.0f", player.auraScore))
                Divider().background(AppTheme.C.rim).frame(height: 32)
                statCell(label: "Freezes", value: "\(player.streakFreezeBalance)")
            }
            .padding(.vertical, 14)
        }
        .hudPanel(cut: 14, corners: [.topRight, .bottomLeft])
    }

    @ViewBuilder
    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label.uppercased())
                .font(AppTheme.T.mono(9))
                .foregroundStyle(AppTheme.C.smoke)
                .kerning(1.5)
            Text(value)
                .font(AppTheme.T.mono(16))
                .foregroundStyle(AppTheme.C.cyan)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
    }
}
