import SwiftUI
import SwiftData

struct WorkoutBlock: Identifiable {
    var id = UUID()
    var isStrength: Bool = true
    var durationMin: Int = 30
}

struct AddWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query private var players: [Player]

    @State private var date: Date = .now
    @State private var notes: String = ""
    @State private var blocks: [WorkoutBlock] = [WorkoutBlock()]
    @State private var showingReward = false
    @State private var rewardImageName = "gojo_1"
    @State private var rewardXP = 0

    private let durations = [5, 10, 15, 20, 30, 45, 60, 75, 90, 120]
    private var streak: Int { players.first?.currentStreak ?? 0 }

    private var previewXP: Int {
        blocks.reduce(0) {
            $0 + XPEngine.computeXP(isStrength: $1.isStrength, durationMinutes: $1.durationMin, streak: streak)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {

                        // Date / time
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(AppTheme.C.cyanDim)
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .colorScheme(.dark)
                            Spacer()
                        }
                        .padding(12)
                        .hudPanel()

                        // Workout blocks
                        ForEach($blocks) { $block in
                            WorkoutBlockCard(
                                block: $block,
                                durations: durations,
                                canRemove: blocks.count > 1
                            ) {
                                blocks.removeAll { $0.id == block.id }
                            }
                        }

                        // Add workout button — always visible
                        Button {
                            blocks.append(WorkoutBlock())
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                Text("ADD WORKOUT")
                                    .kerning(1.5)
                            }
                            .font(AppTheme.T.heading(13))
                            .foregroundStyle(AppTheme.C.cyan)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                        }
                        .buttonStyle(.plain)
                        .hudPanel(cut: 6, corners: .all, border: AppTheme.C.cyanDim)

                        // XP preview
                        HStack {
                            Text("XP PREVIEW")
                                .font(AppTheme.T.mono(10))
                                .foregroundStyle(AppTheme.C.smoke)
                                .kerning(2)
                            Spacer()
                            Text("+\(previewXP) XP")
                                .font(AppTheme.T.mono(20))
                                .foregroundStyle(AppTheme.C.gold)
                                .fontWeight(.bold)
                                .neonGlow(color: AppTheme.C.gold, radius: 5)
                                .monospacedDigit()
                        }
                        .padding(12)
                        .hudPanel(cut: 8, corners: .topRight, border: AppTheme.C.gold.opacity(0.3))

                        // Notes
                        TextField("Session notes (optional)", text: $notes, axis: .vertical)
                            .font(AppTheme.T.body(13))
                            .foregroundStyle(AppTheme.C.ash)
                            .lineLimit(3...6)
                            .padding(12)
                            .hudPanel()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("LOG SESSION")
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
            .fullScreenCover(isPresented: $showingReward, onDismiss: { dismiss() }) {
                GojoRewardView(imageName: rewardImageName, xpEarned: rewardXP) {
                    showingReward = false
                }
            }
        }
    }

    private func save() {
        let totalDuration = blocks.reduce(0) { $0 + $1.durationMin }
        let entry = WorkoutEntry(date: date, notes: notes, durationMin: totalDuration)
        context.insert(entry)

        var sets: [ExerciseSet] = []
        for (i, block) in blocks.enumerated() {
            let s = ExerciseSet(
                exerciseName: block.isStrength ? "Strength" : "Cardio",
                muscleGroup: block.isStrength ? .core : .cardio,
                setNumber: i + 1,
                reps: nil, weightKg: nil,
                durationSec: block.durationMin * 60
            )
            s.entry = entry
            context.insert(s)
            sets.append(s)
        }
        entry.sets = sets
        entry.xpAwarded = previewXP

        if let player = players.first {
            appState.updateStreak(for: player, context: context)
            appState.awardXP(previewXP, to: player, context: context)
        }

        try? context.save()

        // Compute today's total workout minutes for image bias
        let todayStart = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<WorkoutEntry>(
            predicate: #Predicate { $0.date >= todayStart }
        )
        let todayTotal = (try? context.fetch(descriptor))?.reduce(0) { $0 + $1.durationMin } ?? totalDuration

        rewardXP = previewXP
        rewardImageName = GojoRewardView.pickImage(todayMinutes: todayTotal)
        showingReward = true
    }
}

// MARK: - Gojo Reward View

struct GojoRewardView: View {
    let imageName: String
    let xpEarned: Int
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top label
                Text("SESSION COMPLETE")
                    .font(AppTheme.T.mono(11))
                    .foregroundStyle(AppTheme.C.cyan)
                    .kerning(4)
                    .neonGlow(color: AppTheme.C.cyan, radius: 4)
                    .padding(.top, 56)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)

                Spacer()

                // Gojo image
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: appeared)

                Spacer()

                // XP + button
                VStack(spacing: 14) {
                    Text("+\(xpEarned) XP")
                        .font(AppTheme.T.mono(40))
                        .foregroundStyle(AppTheme.C.gold)
                        .fontWeight(.bold)
                        .neonGlow(color: AppTheme.C.gold, radius: 10)
                        .monospacedDigit()

                    Button(action: onDismiss) {
                        Text("KEEP GRINDING")
                            .font(AppTheme.T.heading(15))
                            .foregroundStyle(AppTheme.C.void)
                            .kerning(3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.C.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .neonGlow(color: AppTheme.C.cyan, radius: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 32)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
                .padding(.bottom, 52)
            }
        }
        .onTapGesture { onDismiss() }
        .onAppear { appeared = true }
    }

    // Weighted image selection: more workout minutes today → bias toward higher-ranked images
    static func pickImage(todayMinutes: Int, count: Int = 15) -> String {
        // Peak image index (0-based) shifts from ~3 at 0 min to ~13 at 90+ min
        let fraction = min(Double(todayMinutes), 90.0) / 90.0
        let peak = 3.0 + fraction * 10.0
        let sigma = 3.0

        var weights = (0..<count).map { i -> Double in
            let diff = Double(i) - peak
            return exp(-(diff * diff) / (2.0 * sigma * sigma))
        }
        let sum = weights.reduce(0.0, +)
        weights = weights.map { $0 / sum }

        let roll = Double.random(in: 0.0..<1.0)
        var cumulative = 0.0
        for (i, w) in weights.enumerated() {
            cumulative += w
            if roll < cumulative { return "gojo_\(i + 1)" }
        }
        return "gojo_\(count)"
    }
}

// MARK: - Workout block card

struct WorkoutBlockCard: View {
    @Binding var block: WorkoutBlock
    let durations: [Int]
    let canRemove: Bool
    let onRemove: () -> Void

    @State private var durationOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("WORKOUT")
                    .font(AppTheme.T.mono(9))
                    .foregroundStyle(AppTheme.C.smoke)
                    .kerning(2)
                Spacer()
                if canRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.C.smoke)
                    }
                }
            }

            // Type toggle
            HStack(spacing: 0) {
                typeButton("STRENGTH", icon: "dumbbell.fill", selected: block.isStrength) {
                    block.isStrength = true
                }
                typeButton("CARDIO", icon: "figure.run", selected: !block.isStrength) {
                    block.isStrength = false
                }
            }
            .overlay(Rectangle().stroke(AppTheme.C.rim, lineWidth: 1))

            // Duration dropdown toggle
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { durationOpen.toggle() }
                } label: {
                    HStack {
                        Text("DURATION")
                            .font(AppTheme.T.mono(9))
                            .foregroundStyle(AppTheme.C.smoke)
                            .kerning(2)
                        Spacer()
                        Text(durationLabel(block.durationMin))
                            .font(AppTheme.T.mono(13))
                            .foregroundStyle(AppTheme.C.cyan)
                        Image(systemName: durationOpen ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.C.cyanDim)
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppTheme.C.steel)
                }
                .buttonStyle(.plain)

                if durationOpen {
                    Divider().background(AppTheme.C.rim)
                    VStack(spacing: 0) {
                        ForEach(durations, id: \.self) { d in
                            Button {
                                block.durationMin = d
                                withAnimation(.easeInOut(duration: 0.15)) { durationOpen = false }
                            } label: {
                                HStack {
                                    Text(durationLabel(d))
                                        .font(AppTheme.T.mono(13))
                                        .foregroundStyle(block.durationMin == d ? AppTheme.C.cyan : AppTheme.C.ash)
                                    Spacer()
                                    if block.durationMin == d {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(AppTheme.C.cyan)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(block.durationMin == d ? AppTheme.C.cyan.opacity(0.08) : Color.clear)
                            }
                            .buttonStyle(.plain)
                            if d != durations.last {
                                Divider().background(AppTheme.C.rim)
                            }
                        }
                    }
                }
            }
            .overlay(Rectangle().stroke(AppTheme.C.rim, lineWidth: 1))
        }
        .padding(14)
        .hudPanel(cut: 10, corners: [.topRight, .bottomLeft])
    }

    @ViewBuilder
    private func typeButton(_ label: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13))
                Text(label).font(AppTheme.T.heading(13)).kerning(1)
            }
            .foregroundStyle(selected ? AppTheme.C.void : AppTheme.C.smoke)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? AppTheme.C.cyan : Color.clear)
        }
        .buttonStyle(.plain)
        .neonGlow(color: AppTheme.C.cyan, radius: selected ? 5 : 0)
    }

    private func durationLabel(_ min: Int) -> String {
        if min < 60 { return "\(min) min" }
        let h = min / 60, m = min % 60
        return m > 0 ? "\(h)h \(m)min" : "\(h)h"
    }
}
