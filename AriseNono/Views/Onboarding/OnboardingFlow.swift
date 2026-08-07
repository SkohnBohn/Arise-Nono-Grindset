import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    let onComplete: () -> Void
    @Environment(\.modelContext) private var context

    @State private var page = 0
    @State private var playerName = ""
    @State private var bodyweightKg = ""
    @State private var accepted = false

    var body: some View {
        ZStack {
            AppTheme.C.void.ignoresSafeArea()

            // Ambient particles
            TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                Canvas { ctx, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for i in 0..<8 {
                        let x = (sin(t * 0.3 + Double(i) * 0.8) * 0.5 + 0.5) * size.width
                        let y = (cos(t * 0.2 + Double(i) * 1.1) * 0.5 + 0.5) * size.height
                        let r = CGFloat(2 + (i % 3))
                        let c = i % 2 == 0 ? Color(hex: "00CFEE") : Color(hex: "B82CF5")
                        ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                                 with: .color(c.opacity(0.3)))
                    }
                }
            }
            .ignoresSafeArea()

            switch page {
            case 0: awakeningPage
            case 1: nameSetupPage
            case 2: disclaimerPage
            default: EmptyView()
            }
        }
    }

    // MARK: - Pages

    private var awakeningPage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Notification card
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(AppTheme.C.cyan)
                        .neonGlow(color: AppTheme.C.cyan, radius: 6)
                    Text("NOTIFICATION")
                        .font(AppTheme.T.heading(16))
                        .foregroundStyle(AppTheme.C.snow)
                        .kerning(4)
                }

                Divider().background(AppTheme.C.cyanDim)

                Text("You have acquired the qualifications to be a Player.")
                    .font(AppTheme.T.body(15))
                    .foregroundStyle(AppTheme.C.ash)
                    .multilineTextAlignment(.center)

                Text("Will you accept?")
                    .font(AppTheme.T.heading(15))
                    .foregroundStyle(AppTheme.C.snow)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .hudPanel(cut: 16, corners: [.topRight, .bottomLeft])
            .padding(.horizontal, 32)
            .neonGlow(color: AppTheme.C.cyan, radius: 10)

            Spacer()

            // Headline
            VStack(spacing: 4) {
                Text("YOUR")
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(AppTheme.C.snow)
                    .kerning(-1)
                Text("AWAKENING")
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(AppTheme.C.cyan)
                    .kerning(-1)
                    .neonGlow(color: AppTheme.C.cyan, radius: 14)
                Text("STARTS HERE")
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(AppTheme.C.mag)
                    .kerning(-1)
                    .neonGlow(color: AppTheme.C.mag, radius: 14)
            }
            .padding(.bottom, 40)

            Button {
                withAnimation(.easeInOut(duration: 0.4)) { page = 1 }
            } label: {
                Text("ACCEPT")
                    .font(AppTheme.T.heading(18))
                    .foregroundStyle(AppTheme.C.void)
                    .kerning(4)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.C.cyan)
                    .neonGlow(color: AppTheme.C.cyan, radius: 10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }

    private var nameSetupPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("SET YOUR IDENTITY")
                    .font(AppTheme.T.heading(22))
                    .foregroundStyle(AppTheme.C.snow)
                    .kerning(3)
                    .padding(.top, 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text("PLAYER NAME")
                        .font(AppTheme.T.mono(10))
                        .foregroundStyle(AppTheme.C.smoke)
                        .kerning(2)
                    TextField("Enter your name", text: $playerName)
                        .font(AppTheme.T.heading(20))
                        .foregroundStyle(AppTheme.C.snow)
                        .padding(14)
                        .hudPanel()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("BODYWEIGHT (kg) — optional")
                        .font(AppTheme.T.mono(9))
                        .foregroundStyle(AppTheme.C.smoke)
                        .kerning(1)
                    TextField("75", text: $bodyweightKg)
                        .keyboardType(.decimalPad)
                        .font(AppTheme.T.mono(18))
                        .foregroundStyle(AppTheme.C.cyan)
                        .padding(14)
                        .hudPanel()
                }

                Button {
                    withAnimation { page = 2 }
                } label: {
                    Text("CONTINUE")
                        .font(AppTheme.T.heading(16))
                        .foregroundStyle(AppTheme.C.void)
                        .kerning(3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(playerName.isEmpty ? AppTheme.C.rim : AppTheme.C.cyan)
                }
                .buttonStyle(.plain)
                .disabled(playerName.isEmpty)
            }
            .padding(24)
        }
        .background(AppTheme.C.void)
    }

    private var disclaimerPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.C.mag)
                .neonGlow(color: AppTheme.C.mag, radius: 10)

            Text("IMPORTANT")
                .font(AppTheme.T.heading(20))
                .foregroundStyle(AppTheme.C.snow)
                .kerning(4)

            Text("""
Arise is a personal tracking and motivational tool.

Always consult a qualified healthcare professional before making significant changes to your exercise routine.
""")
                .font(AppTheme.T.body(14))
                .foregroundStyle(AppTheme.C.ash)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)

            Spacer()

            Button {
                createPlayer()
                onComplete()
            } label: {
                Text("I UNDERSTAND — BEGIN")
                    .font(AppTheme.T.heading(16))
                    .foregroundStyle(AppTheme.C.void)
                    .kerning(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.C.cyan)
                    .neonGlow(color: AppTheme.C.cyan, radius: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .padding(24)
    }

    private func createPlayer() {
        let kg = Double(bodyweightKg)
        let player = Player(name: playerName.isEmpty ? "Player" : playerName, bodyweightKg: kg)
        context.insert(player)
        try? context.save()
    }
}
