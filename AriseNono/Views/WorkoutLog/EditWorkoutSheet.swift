import SwiftUI
import SwiftData

struct EditWorkoutSheet: View {
    let entry: WorkoutEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var date: Date
    @State private var notes: String
    @State private var blocks: [WorkoutBlock]

    private let durations = [5, 10, 15, 20, 30, 45, 60, 75, 90, 120]

    init(entry: WorkoutEntry) {
        self.entry = entry
        _date  = State(initialValue: entry.date)
        _notes = State(initialValue: entry.notes)

        let restored = entry.sets
            .sorted { $0.setNumber < $1.setNumber }
            .compactMap { s -> WorkoutBlock? in
                let mins = (s.durationSec ?? 0) / 60
                guard mins > 0 else { return nil }
                return WorkoutBlock(isStrength: s.exerciseName != "Cardio", durationMin: mins)
            }
        _blocks = State(initialValue: restored.isEmpty ? [WorkoutBlock()] : restored)
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

                        // Add more workouts
                        Button {
                            blocks.append(WorkoutBlock())
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                Text("ADD WORKOUT").kerning(1.5)
                            }
                            .font(AppTheme.T.heading(13))
                            .foregroundStyle(AppTheme.C.cyan)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                        }
                        .buttonStyle(.plain)
                        .hudPanel(cut: 6, corners: .all, border: AppTheme.C.cyanDim)

                        // XP notice
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(AppTheme.C.cyanDim)
                            Text("XP already awarded stays unchanged.")
                                .font(AppTheme.T.mono(10))
                                .foregroundStyle(AppTheme.C.smoke)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .hudPanel(cut: 0, corners: .all, border: AppTheme.C.cyanDim.opacity(0.4))

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
                    Text("EDIT SESSION")
                        .font(AppTheme.T.heading(14))
                        .foregroundStyle(AppTheme.C.snow)
                        .kerning(3)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.C.smoke)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") { save() }
                        .foregroundStyle(AppTheme.C.cyan)
                        .fontWeight(.bold)
                }
            }
        }
    }

    private func save() {
        entry.date = date
        entry.notes = notes
        entry.durationMin = blocks.reduce(0) { $0 + $1.durationMin }

        // Replace sets, leave xpAwarded untouched
        for s in entry.sets { context.delete(s) }

        var newSets: [ExerciseSet] = []
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
            newSets.append(s)
        }
        entry.sets = newSets

        try? context.save()
        dismiss()
    }
}
