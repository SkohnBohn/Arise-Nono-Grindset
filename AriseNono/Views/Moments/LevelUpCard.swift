import SwiftUI

struct LevelUpCard: View {
    let level: Int
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Dark background with vignette
            Color.black.opacity(0.92).ignoresSafeArea()

            // Particle canvas
            LightningCanvas()
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 0) {
                Spacer()

                // Notification card strip
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(AppTheme.C.cyan)
                        .neonGlow(color: AppTheme.C.cyan, radius: 6)
                    Text("NOTIFICATION")
                        .font(AppTheme.T.mono(11))
                        .foregroundStyle(AppTheme.C.ash)
                        .kerning(3)
                    Spacer()
                }
                .padding(14)
                .hudPanel(cut: 6, corners: .topRight)
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -20)

                Spacer().frame(height: 24)

                // Big level number
                Text("LVL \(level)")
                    .font(.system(size: 88, weight: .black))
                    .foregroundStyle(AppTheme.C.cyan)
                    .kerning(-2)
                    .neonGlow(color: AppTheme.C.cyan, radius: 20)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                Text("DAY \(dayNumber())")
                    .font(AppTheme.T.mono(16))
                    .foregroundStyle(AppTheme.C.smoke)
                    .kerning(4)
                    .padding(.top, 4)
                    .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 40)

                // "LEVEL UP" text
                VStack(spacing: -8) {
                    Text("LEVEL")
                        .font(.system(size: 64, weight: .black))
                        .foregroundStyle(AppTheme.C.snow)
                        .kerning(-1)
                    Text("UP")
                        .font(.system(size: 64, weight: .black))
                        .foregroundStyle(AppTheme.C.gold)
                        .kerning(-1)
                        .neonGlow(color: AppTheme.C.gold, radius: 12)
                }
                .scaleEffect(appeared ? 1 : 1.3)
                .opacity(appeared ? 1 : 0)

                Spacer()

                // Dismiss
                Button(action: onDismiss) {
                    Text("TAP TO CONTINUE")
                        .font(AppTheme.T.mono(12))
                        .foregroundStyle(AppTheme.C.smoke)
                        .kerning(3)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 60)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onTapGesture { onDismiss() }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    private func dayNumber() -> Int {
        max(1, Calendar.current.dateComponents([.day], from: Date.distantPast, to: .now).day ?? 1)
    }
}

struct RankUpCard: View {
    let rank: RankTier
    let onDismiss: () -> Void

    @State private var appeared = false
    private var accent: Color { AppTheme.C.rank(rank) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            // Background glow burst
            Circle()
                .fill(accent.opacity(0.1))
                .frame(width: appeared ? 600 : 0)
                .blur(radius: 60)
                .animation(.easeOut(duration: 1.2), value: appeared)

            LightningCanvas(color: accent)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 20) {
                Spacer()

                // Animated rank name
                Text(rank.displayName.uppercased())
                    .font(.system(size: 72, weight: .black))
                    .foregroundStyle(accent)
                    .kerning(-1)
                    .neonGlow(color: accent, radius: 24)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)

                Text("RANK ACHIEVED")
                    .font(AppTheme.T.mono(14))
                    .foregroundStyle(AppTheme.C.ash)
                    .kerning(6)
                    .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 16)

                // Notification-style card
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(accent)
                        Text("YOU HAVE BEEN PROMOTED")
                            .font(AppTheme.T.heading(14))
                            .foregroundStyle(AppTheme.C.snow)
                            .kerning(2)
                        Spacer()
                    }
                    Text("Your relentless grind has been acknowledged. A new rank awaits.")
                        .font(AppTheme.T.body(13))
                        .foregroundStyle(AppTheme.C.ash)
                }
                .padding(18)
                .hudPanel(cut: 12, corners: [.topRight, .bottomLeft], border: accent.opacity(0.6))
                .padding(.horizontal, 24)
                .offset(y: appeared ? 0 : 40)
                .opacity(appeared ? 1 : 0)

                Spacer()

                Button(action: onDismiss) {
                    Text("TAP TO CONTINUE")
                        .font(AppTheme.T.mono(12))
                        .foregroundStyle(AppTheme.C.smoke)
                        .kerning(3)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 60)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onTapGesture { onDismiss() }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) { appeared = true }
        }
    }
}

struct StreakMilestoneCard: View {
    let days: Int
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            LightningCanvas(color: AppTheme.C.gold).ignoresSafeArea().opacity(appeared ? 1 : 0)

            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.C.gold)
                    .neonGlow(color: AppTheme.C.gold, radius: 20)
                    .scaleEffect(appeared ? 1 : 0)
                    .opacity(appeared ? 1 : 0)

                Text("DAY \(days)")
                    .font(.system(size: 80, weight: .black))
                    .foregroundStyle(AppTheme.C.gold)
                    .kerning(-2)
                    .neonGlow(color: AppTheme.C.gold, radius: 16)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                Text("THE GRIND CONTINUES")
                    .font(AppTheme.T.heading(18))
                    .foregroundStyle(AppTheme.C.snow)
                    .kerning(3)
                    .opacity(appeared ? 1 : 0)

                Text("+1 Streak Freeze earned")
                    .font(AppTheme.T.mono(13))
                    .foregroundStyle(AppTheme.C.cyan)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                Button(action: onDismiss) {
                    Text("TAP TO CONTINUE")
                        .font(AppTheme.T.mono(12))
                        .foregroundStyle(AppTheme.C.smoke)
                        .kerning(3)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 60)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onTapGesture { onDismiss() }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appeared = true }
        }
    }
}

// MARK: - Particle canvas shared by all moment cards
struct LightningCanvas: View {
    var color: Color = AppTheme.C.cyan

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                // Falling particles
                for i in 0..<24 {
                    let seed = Double(i) * 1.618
                    let x = ((sin(seed * 3.7) + 1) / 2) * size.width
                    let speed = 60 + (seed.truncatingRemainder(dividingBy: 40))
                    let y = (t * speed + seed * 80).truncatingRemainder(dividingBy: size.height)
                    let r: CGFloat = 2 + CGFloat(i % 3)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                        with: .color(color.opacity(0.6))
                    )
                }

                // Subtle horizontal lines
                for i in 0..<5 {
                    let y = (t * 20 + Double(i) * 140).truncatingRemainder(dividingBy: size.height)
                    var p = Path()
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(p, with: .color(color.opacity(0.06)), lineWidth: 1)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
