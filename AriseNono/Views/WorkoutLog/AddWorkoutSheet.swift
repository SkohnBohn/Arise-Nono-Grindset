import SwiftUI
import SwiftData

struct AddWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query private var players: [Player]
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var allWorkouts: [WorkoutEntry]

    @State private var date: Date = .now
    @State private var notes: String = ""
    @State private var durationMin: Int = 45
    @State private var rows: [SetRow] = [SetRow()]

    struct SetRow: Identifiable {
        var id = UUID()
        var exerciseName: String = ""
        var muscleGroup: MuscleGroup = .chest
        var reps: String = ""
        var weightKg: String = ""
        var durationSec: String = ""
        var isCardio: Bool { muscleGroup == .cardio }
    }

    private var previewXP: Int {
        guard !rows.isEmpty else { return 0 }
        let snapshot = WorkoutSnapshot(
            sets: rows.compactMap { r in
                guard !r.exerciseName.isEmpty else { return nil }
                return WorkoutSnapshot.SetSnapshot(
                    muscleGroup: r.muscleGroup,
                    reps: Int(r.reps),
                    weightKg: Double(r.weightKg),
                    durationSec: Int(r.durationSec)
                )
            },
            durationMinutes: durationMin,
            streak: players.first?.currentStreak ?? 0,
            priorMuscleGroupsThisWeek: priorGroupsThisWeek()
        )
        return XPEngine.computeXP(for: snapshot)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Date + duration
                        HStack(spacing: 12) {
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .colorScheme(.dark)

                            Stepper("\(durationMin) min", value: $durationMin, in: 1...300)
                                .foregroundStyle(AppTheme.C.ash)
                                .font(AppTheme.T.mono(13))
                        }
                        .padding(12)
                        .hudPanel()

                        // Set rows
                        ForEach($rows) { $row in
                            SetRowView(row: $row) {
                                rows.removeAll { $0.id == row.id }
                            }
                        }

                        Button {
                            rows.append(SetRow())
                        } label: {
                            Label("Add Set", systemImage: "plus")
                                .font(AppTheme.T.heading(13))
                                .foregroundStyle(AppTheme.C.cyan)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                        }
                        .hudPanel(cut: 6, corners: .all, border: AppTheme.C.cyanDim)

                        // Notes
                        TextField("Session notes (optional)", text: $notes, axis: .vertical)
                            .font(AppTheme.T.body(13))
                            .foregroundStyle(AppTheme.C.ash)
                            .padding(12)
                            .hudPanel()

                        // XP preview
                        HStack {
                            Text("XP Preview")
                                .font(AppTheme.T.mono(11))
                                .foregroundStyle(AppTheme.C.smoke)
                            Spacer()
                            Text("+\(previewXP) XP")
                                .font(AppTheme.T.mono(18))
                                .foregroundStyle(AppTheme.C.gold)
                                .fontWeight(.bold)
                                .neonGlow(color: AppTheme.C.gold, radius: 5)
                        }
                        .padding(12)
                        .hudPanel(cut: 8, corners: .topRight, border: AppTheme.C.gold.opacity(0.4))
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
        guard !rows.isEmpty else { return }
        let entry = WorkoutEntry(date: date, notes: notes, durationMin: durationMin)
        context.insert(entry)

        let setModels: [ExerciseSet] = rows.compactMap { r in
            guard !r.exerciseName.isEmpty else { return nil }
            return ExerciseSet(
                exerciseName: r.exerciseName,
                muscleGroup: r.muscleGroup,
                setNumber: rows.firstIndex(where: { $0.id == r.id }).map { $0 + 1 } ?? 1,
                reps: Int(r.reps),
                weightKg: Double(r.weightKg),
                durationSec: Int(r.durationSec)
            )
        }

        for s in setModels {
            s.entry = entry
            context.insert(s)
        }
        entry.sets = setModels

        let xp = previewXP
        entry.xpAwarded = xp

        if let player = players.first {
            let oldXP = player.totalXP
            appState.updateStreak(for: player, context: context)
            appState.awardXP(xp, to: player, context: context)
            _ = oldXP
        }

        try? context.save()
        dismiss()
    }

    private func priorGroupsThisWeek() -> Set<MuscleGroup> {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now)!
        return Set(
            allWorkouts
                .filter { $0.date >= weekAgo }
                .flatMap { $0.sets.map(\.muscleGroup) }
        )
    }
}

struct SetRowView: View {
    @Binding var row: AddWorkoutSheet.SetRow
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                TextField("Exercise name", text: $row.exerciseName)
                    .font(AppTheme.T.body(14))
                    .foregroundStyle(AppTheme.C.ash)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.C.smoke)
                }
            }

            Picker("Muscle group", selection: $row.muscleGroup) {
                ForEach(MuscleGroup.allCases) { g in
                    Text(g.displayName).tag(g)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.C.cyan)

            HStack(spacing: 8) {
                if row.isCardio {
                    numField("Duration (sec)", text: $row.durationSec)
                } else {
                    numField("Reps", text: $row.reps)
                    numField("Weight (kg)", text: $row.weightKg)
                }
            }
        }
        .padding(12)
        .hudPanel(cut: 8, corners: [.topRight, .bottomLeft])
    }

    @ViewBuilder
    private func numField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(AppTheme.T.mono(8))
                .foregroundStyle(AppTheme.C.smoke)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .font(AppTheme.T.mono(14))
                .foregroundStyle(AppTheme.C.cyan)
                .padding(6)
                .background(AppTheme.C.steel)
        }
    }
}
