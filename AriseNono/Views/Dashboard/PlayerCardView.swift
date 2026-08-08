import SwiftUI

struct PlayerCardView: View {
    let player: Player
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // mid background image matching current avatar tier
            let midName = "mid_\(AvatarEngine.avatarNumber(for: appState.monthlyXP))"

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

            AvatarView(monthlyXP: appState.monthlyXP, rankTier: player.rankTier, size: 100)
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
        .background {
            Image(midName)
                .resizable()
                .scaledToFill()
                .opacity(0.25)
                .clipped()
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
