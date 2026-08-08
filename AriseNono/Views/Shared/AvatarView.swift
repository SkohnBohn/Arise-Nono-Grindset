import SwiftUI

// MARK: - Thresholds

enum AvatarEngine {
    static let thresholds: [(xp: Int, number: Int)] = [
        (0,    1),
        (400,  2),
        (900,  3),
        (1500, 4),
        (2200, 5),
        (3000, 6),
        (3700, 7),
        (4400, 8),
        (5200, 9),
        (6200, 10),
    ]

    static func avatarNumber(for monthlyXP: Int) -> Int {
        thresholds.last(where: { monthlyXP >= $0.xp })?.number ?? 1
    }

    static func avatarName(for monthlyXP: Int) -> String {
        "avatar_\(avatarNumber(for: monthlyXP))"
    }

    static func nextThreshold(for monthlyXP: Int) -> Int? {
        thresholds.first(where: { $0.xp > monthlyXP })?.xp
    }
}

// MARK: - Reusable circle avatar

struct AvatarView: View {
    let monthlyXP: Int
    let rankTier: RankTier
    let size: CGFloat

    @State private var showingFullScreen = false

    var body: some View {
        Button {
            showingFullScreen = true
        } label: {
            ZStack {
                Circle()
                    .stroke(AppTheme.C.rank(rankTier), lineWidth: 3)
                    .frame(width: size, height: size)
                    .neonGlow(color: AppTheme.C.rank(rankTier), radius: 12)
                Image(AvatarEngine.avatarName(for: monthlyXP))
                    .resizable()
                    .scaledToFill()
                    .frame(width: size - 6, height: size - 6)
                    .clipShape(Circle())
            }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingFullScreen) {
            AvatarFullScreenView(monthlyXP: monthlyXP, onDismiss: { showingFullScreen = false })
        }
    }
}

// MARK: - Full-screen expand

struct AvatarFullScreenView: View {
    let monthlyXP: Int
    let onDismiss: () -> Void

    @State private var appeared = false

    private var number: Int { AvatarEngine.avatarNumber(for: monthlyXP) }
    private var nextXP: Int? { AvatarEngine.nextThreshold(for: monthlyXP) }
    private var progressFraction: Double {
        guard let next = nextXP else { return 1.0 }
        let prev = AvatarEngine.thresholds.last(where: { $0.xp <= monthlyXP })?.xp ?? 0
        guard next > prev else { return 1.0 }
        return min(Double(monthlyXP - prev) / Double(next - prev), 1.0)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("AVATAR \(number) / 10")
                    .font(AppTheme.T.mono(11))
                    .foregroundStyle(AppTheme.C.cyan)
                    .kerning(4)
                    .neonGlow(color: AppTheme.C.cyan, radius: 4)
                    .padding(.top, 56)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)

                Spacer()

                Image(AvatarEngine.avatarName(for: monthlyXP))
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .padding(.horizontal, 48)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: appeared)

                Spacer()

                VStack(spacing: 16) {
                    Text("\(monthlyXP) XP THIS MONTH")
                        .font(AppTheme.T.mono(20))
                        .foregroundStyle(AppTheme.C.gold)
                        .fontWeight(.bold)
                        .neonGlow(color: AppTheme.C.gold, radius: 6)
                        .monospacedDigit()

                    if let next = nextXP {
                        VStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(AppTheme.C.rim)
                                        .frame(height: 4)
                                    Rectangle()
                                        .fill(AppTheme.C.cyan)
                                        .frame(width: geo.size.width * progressFraction, height: 4)
                                        .neonGlow(color: AppTheme.C.cyan, radius: 3)
                                }
                            }
                            .frame(height: 4)
                            Text("\(next - monthlyXP) XP to avatar \(number + 1)")
                                .font(AppTheme.T.mono(11))
                                .foregroundStyle(AppTheme.C.smoke)
                                .kerning(1)
                        }
                        .padding(.horizontal, 32)
                    } else {
                        Text("MAXIMUM AVATAR UNLOCKED")
                            .font(AppTheme.T.mono(11))
                            .foregroundStyle(AppTheme.C.gold)
                            .kerning(2)
                            .neonGlow(color: AppTheme.C.gold, radius: 4)
                    }

                    Button(action: onDismiss) {
                        Text("CLOSE")
                            .font(AppTheme.T.heading(14))
                            .foregroundStyle(AppTheme.C.smoke)
                            .kerning(3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(Rectangle().stroke(AppTheme.C.rim, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 32)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
                .padding(.bottom, 52)
            }
        }
        .onTapGesture { onDismiss() }
        .onAppear { appeared = true }
    }
}
