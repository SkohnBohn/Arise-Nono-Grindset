import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AdjustGoalsSheet: View {
    let player: Player
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var strengthGoal: Int
    @State private var cardioGoal: Int
    @State private var stretchGoal: Int
    @State private var backGoal: Int
    @State private var sleepGoal: Int
    @State private var showingLevelWarning = false

    // Backup / restore
    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var importError: String?
    @State private var importSucceeded = false

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

                        // Divider
                        Rectangle()
                            .fill(AppTheme.C.rim)
                            .frame(height: 1)
                            .padding(.vertical, 6)

                        // Export save data
                        Button {
                            do {
                                exportURL = try BackupEngine.export(player: player, context: context)
                            } catch {
                                importError = "Export failed: \(error.localizedDescription)"
                            }
                        } label: {
                            backupRow(
                                icon: "square.and.arrow.up",
                                title: "EXPORT SAVE DATA",
                                subtitle: "Share a backup file",
                                color: AppTheme.C.cyan
                            )
                        }
                        .buttonStyle(.plain)
                        .sheet(item: $exportURL) { url in
                            ActivityView(url: url)
                        }

                        // Import save data
                        Button {
                            showingImporter = true
                        } label: {
                            backupRow(
                                icon: "square.and.arrow.down",
                                title: "IMPORT SAVE DATA",
                                subtitle: "Restore from a backup file",
                                color: AppTheme.C.mag
                            )
                        }
                        .buttonStyle(.plain)
                        .fileImporter(
                            isPresented: $showingImporter,
                            allowedContentTypes: [.json]
                        ) { result in
                            switch result {
                            case .success(let url):
                                do {
                                    guard url.startAccessingSecurityScopedResource() else {
                                        importError = "Permission denied for that file."
                                        return
                                    }
                                    defer { url.stopAccessingSecurityScopedResource() }
                                    try BackupEngine.restore(from: url, player: player, context: context)
                                    importSucceeded = true
                                } catch {
                                    importError = "Import failed: \(error.localizedDescription)"
                                }
                            case .failure(let error):
                                importError = error.localizedDescription
                            }
                        }
                        .alert("Import successful!", isPresented: $importSucceeded) {
                            Button("OK") { dismiss() }
                        } message: {
                            Text("Your stats, workout history, and goals have been restored.")
                        }
                        .alert("Something went wrong", isPresented: Binding(
                            get: { importError != nil },
                            set: { if !$0 { importError = nil } }
                        )) {
                            Button("OK", role: .cancel) { importError = nil }
                        } message: {
                            Text(importError ?? "")
                        }

                        // Divider
                        Rectangle()
                            .fill(AppTheme.C.rim)
                            .frame(height: 1)
                            .padding(.vertical, 6)

                        // Manual level override
                        Button {
                            showingLevelWarning = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.C.gold)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SET LEVEL MANUALLY")
                                        .font(AppTheme.T.mono(10))
                                        .foregroundStyle(AppTheme.C.gold)
                                        .kerning(1.5)
                                    Text("Emergency data recovery only")
                                        .font(AppTheme.T.mono(9))
                                        .foregroundStyle(AppTheme.C.smoke)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(AppTheme.C.smoke)
                            }
                            .padding(14)
                            .hudPanel(cut: 8, corners: [.topRight, .bottomLeft], border: AppTheme.C.gold.opacity(0.3))
                        }
                        .buttonStyle(.plain)
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
            .fullScreenCover(isPresented: $showingLevelWarning) {
                GojoLevelWarningView(player: player) {
                    showingLevelWarning = false
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

    @ViewBuilder
    private func backupRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.T.mono(10))
                    .foregroundStyle(color)
                    .kerning(1.5)
                Text(subtitle)
                    .font(AppTheme.T.mono(9))
                    .foregroundStyle(AppTheme.C.smoke)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.C.smoke)
        }
        .padding(14)
        .hudPanel(cut: 8, corners: [.topRight, .bottomLeft])
    }
}

// Make URL identifiable so it works with sheet(item:)
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// Thin UIKit wrapper for the system share sheet
struct ActivityView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Gojo Level Warning + Picker

struct GojoLevelWarningView: View {
    let player: Player
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var context
    @State private var confirmed = false
    @State private var appeared = false
    @State private var selectedLevel: Int

    init(player: Player, onDismiss: @escaping () -> Void) {
        self.player = player
        self.onDismiss = onDismiss
        _selectedLevel = State(initialValue: player.level)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if confirmed {
                levelPickerScreen
            } else {
                warningScreen
            }
        }
    }

    // MARK: Warning screen

    private var warningScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("gojo_15")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .scaleEffect(appeared ? 1 : 0.88)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.5, bounce: 0.25), value: appeared)

            Spacer()

            VStack(spacing: 18) {
                Text("NAH, I'D WIN.")
                    .font(AppTheme.T.heading(28))
                    .foregroundStyle(AppTheme.C.snow)
                    .kerning(4)
                    .neonGlow(color: AppTheme.C.cyan, radius: 8)
                    .multilineTextAlignment(.center)

                Text("But would you? Gojo trained for real.\nDon't fake your level. Don't lie to yourself.\nDon't lie to your friends.\n\nGojo would be genuinely disappointed\nif you used this to cheat.")
                    .font(AppTheme.T.mono(13))
                    .foregroundStyle(AppTheme.C.ash)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("This is for data recovery ONLY.")
                    .font(AppTheme.T.mono(11))
                    .foregroundStyle(AppTheme.C.gold)
                    .kerning(1)
                    .neonGlow(color: AppTheme.C.gold, radius: 4)

                VStack(spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { confirmed = true }
                    } label: {
                        Text("I UNDERSTAND — PROCEED")
                            .font(AppTheme.T.heading(13))
                            .foregroundStyle(AppTheme.C.void)
                            .kerning(2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.C.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .neonGlow(color: AppTheme.C.gold, radius: 5)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDismiss) {
                        Text("Never mind")
                            .font(AppTheme.T.body(14))
                            .foregroundStyle(AppTheme.C.smoke)
                    }
                    .buttonStyle(.plain)
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
            .padding(.horizontal, 28)
            .padding(.bottom, 52)
        }
        .onAppear { appeared = true }
    }

    // MARK: Level picker screen

    private var levelPickerScreen: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(AppTheme.T.body(15))
                        .foregroundStyle(AppTheme.C.smoke)
                }
                Spacer()
                Text("SET LEVEL")
                    .font(AppTheme.T.heading(14))
                    .foregroundStyle(AppTheme.C.snow)
                    .kerning(3)
                Spacer()
                Button {
                    applyLevel()
                } label: {
                    Text("Apply")
                        .font(AppTheme.T.body(15))
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.C.gold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 20)

            Divider().background(AppTheme.C.rim)

            // Current info
            VStack(spacing: 6) {
                Text("CURRENT LEVEL: \(player.level)")
                    .font(AppTheme.T.mono(11))
                    .foregroundStyle(AppTheme.C.smoke)
                    .kerning(2)
                Text("NEW LEVEL: \(selectedLevel)")
                    .font(AppTheme.T.mono(20))
                    .foregroundStyle(AppTheme.C.gold)
                    .fontWeight(.bold)
                    .neonGlow(color: AppTheme.C.gold, radius: 5)
                    .monospacedDigit()
                Text("≈ \(LevelCurve.cumulativeXP(forLevel: selectedLevel)) total XP")
                    .font(AppTheme.T.mono(11))
                    .foregroundStyle(AppTheme.C.cyanDim)
                    .monospacedDigit()
            }
            .padding(.vertical, 24)

            // Picker wheel
            Picker("Level", selection: $selectedLevel) {
                ForEach(1...200, id: \.self) { lvl in
                    Text("Level \(lvl)")
                        .font(AppTheme.T.mono(16))
                        .foregroundStyle(AppTheme.C.ash)
                        .tag(lvl)
                }
            }
            .pickerStyle(.wheel)
            .colorScheme(.dark)
            .frame(maxWidth: .infinity)

            Spacer()
        }
    }

    private func applyLevel() {
        player.totalXP   = LevelCurve.cumulativeXP(forLevel: selectedLevel)
        player.level     = selectedLevel
        player.rankTier  = RankTier.tier(for: selectedLevel)
        try? context.save()
        onDismiss()
    }
}
