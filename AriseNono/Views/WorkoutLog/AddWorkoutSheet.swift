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

                        // Add second workout button
                        if blocks.count < 2 {
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
                        }

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
        dismiss()
    }
}

// MARK: - Workout block card

struct WorkoutBlockCard: View {
    @Binding var block: WorkoutBlock
    let durations: [Int]
    let canRemove: Bool
    let onRemove: () -> Void

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

            // Duration label + pills
            Text("DURATION")
                .font(AppTheme.T.mono(9))
                .foregroundStyle(AppTheme.C.smoke)
                .kerning(2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(durations, id: \.self) { d in
                        durationPill(d, selected: block.durationMin == d) {
                            block.durationMin = d
                        }
                    }
                }
            }
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

    @ViewBuilder
    private func durationPill(_ minutes: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(durationLabel(minutes))
                .font(AppTheme.T.mono(11))
                .foregroundStyle(selected ? AppTheme.C.void : AppTheme.C.smoke)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? AppTheme.C.cyan : AppTheme.C.steel)
        }
        .buttonStyle(.plain)
        .neonGlow(color: AppTheme.C.cyan, radius: selected ? 4 : 0)
    }

    private func durationLabel(_ min: Int) -> String {
        if min < 60 { return "\(min)m" }
        let h = min / 60, m = min % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}
