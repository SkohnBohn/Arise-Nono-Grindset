import SwiftUI
import SwiftData

struct WorkoutLogView: View {
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var workouts: [WorkoutEntry]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                ScanlineOverlay()

                if workouts.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(workouts) { entry in
                                WorkoutEntryRow(entry: entry)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            context.delete(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("WORKOUT LOG")
                        .font(AppTheme.T.heading(15))
                        .foregroundStyle(AppTheme.C.snow)
                        .kerning(3)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.C.cyan)
                            .neonGlow(color: AppTheme.C.cyan, radius: 4)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddWorkoutSheet()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.C.cyanDim)
            Text("NO SESSIONS LOGGED")
                .font(AppTheme.T.heading(16))
                .foregroundStyle(AppTheme.C.smoke)
                .kerning(3)
            Text("Tap + to log your first session.")
                .font(AppTheme.T.body(14))
                .foregroundStyle(AppTheme.C.smoke)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WorkoutEntryRow: View {
    let entry: WorkoutEntry
    @State private var expanded = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateFormatter.string(from: entry.date))
                            .font(AppTheme.T.body(14))
                            .foregroundStyle(AppTheme.C.ash)
                        Text(entry.muscleGroups.map(\.displayName).sorted().joined(separator: " · "))
                            .font(AppTheme.T.mono(11))
                            .foregroundStyle(AppTheme.C.smoke)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+\(entry.xpAwarded) XP")
                            .font(AppTheme.T.mono(12))
                            .foregroundStyle(AppTheme.C.gold)
                        Text("\(entry.totalSets) sets")
                            .font(AppTheme.T.mono(11))
                            .foregroundStyle(AppTheme.C.smoke)
                    }
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.C.cyanDim)
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Expanded set list
            if expanded {
                Divider().background(AppTheme.C.rim)
                ForEach(entry.sets.sorted(by: { $0.setNumber < $1.setNumber })) { s in
                    setRow(s)
                }
            }
        }
        .hudPanel(cut: 10, corners: [.topRight, .bottomLeft])
    }

    @ViewBuilder
    private func setRow(_ s: ExerciseSet) -> some View {
        HStack {
            Text("Set \(s.setNumber)")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.smoke)
                .frame(width: 38, alignment: .leading)
            Text(s.exerciseName)
                .font(AppTheme.T.body(13))
                .foregroundStyle(AppTheme.C.ash)
            Spacer()
            if s.muscleGroup == .cardio, let d = s.durationSec {
                Text("\(d)s")
                    .font(AppTheme.T.mono(12))
                    .foregroundStyle(AppTheme.C.cyan)
            } else {
                if let r = s.reps, let w = s.weightKg {
                    Text("\(r) × \(String(format: "%.1f", w))kg")
                        .font(AppTheme.T.mono(12))
                        .foregroundStyle(AppTheme.C.cyan)
                } else if let r = s.reps {
                    Text("\(r) reps")
                        .font(AppTheme.T.mono(12))
                        .foregroundStyle(AppTheme.C.cyan)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }
}
