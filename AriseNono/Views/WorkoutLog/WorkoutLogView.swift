import SwiftUI
import SwiftData

struct WorkoutLogView: View {
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var workouts: [WorkoutEntry]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var editingEntry: WorkoutEntry? = nil

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
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            editingEntry = entry
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(AppTheme.C.cyan)
                                    }
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
            .sheet(item: $editingEntry) { entry in
                EditWorkoutSheet(entry: entry)
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

    private var blockSummary: String {
        entry.sets
            .sorted { $0.setNumber < $1.setNumber }
            .map { s -> String in
                let mins = (s.durationSec ?? 0) / 60
                guard mins > 0 else { return s.exerciseName }
                let dur = mins < 60 ? "\(mins)m" : (mins % 60 == 0 ? "\(mins/60)h" : "\(mins/60)h \(mins%60)m")
                return "\(s.exerciseName) \(dur)"
            }
            .joined(separator: "  ·  ")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(dateFormatter.string(from: entry.date))
                    .font(AppTheme.T.body(14))
                    .foregroundStyle(AppTheme.C.ash)
                if !blockSummary.isEmpty {
                    Text(blockSummary)
                        .font(AppTheme.T.mono(11))
                        .foregroundStyle(AppTheme.C.smoke)
                }
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(AppTheme.T.body(12))
                        .foregroundStyle(AppTheme.C.smoke.opacity(0.7))
                        .lineLimit(1)
                }
            }
            Spacer()
            Text("+\(entry.xpAwarded) XP")
                .font(AppTheme.T.mono(13))
                .foregroundStyle(AppTheme.C.gold)
                .neonGlow(color: AppTheme.C.gold, radius: 3)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .hudPanel(cut: 10, corners: [.topRight, .bottomLeft])
    }
}
