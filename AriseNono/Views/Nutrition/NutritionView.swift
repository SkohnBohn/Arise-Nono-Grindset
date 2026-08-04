import SwiftUI
import SwiftData

struct NutritionView: View {
    @Query(sort: \NutritionEntry.date, order: .reverse) private var entries: [NutritionEntry]
    @Query private var players: [Player]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false

    private var player: Player? { players.first }

    private var todayEntry: NutritionEntry? {
        let today = Calendar.current.startOfDay(for: .now)
        return entries.first { Calendar.current.startOfDay(for: $0.date) == today }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                ScanlineOverlay()

                ScrollView {
                    VStack(spacing: 16) {
                        if let entry = todayEntry, let player {
                            NutritionDayPanel(entry: entry, player: player)
                            MealListPanel(entry: entry)
                            MicronutrientPanel(entry: entry)
                        } else if let player {
                            startDayCard(player: player)
                        }

                        // History
                        if entries.count > 1 {
                            historySection
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("NUTRITION")
                        .font(AppTheme.T.heading(15))
                        .foregroundStyle(AppTheme.C.snow)
                        .kerning(3)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        ensureTodayEntry()
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.C.cyan)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                if let entry = todayEntry {
                    AddMealSheet(todayEntry: entry)
                }
            }
        }
    }

    @ViewBuilder
    private func startDayCard(player: Player) -> some View {
        VStack(spacing: 12) {
            Text("NO LOG FOR TODAY")
                .font(AppTheme.T.heading(15))
                .foregroundStyle(AppTheme.C.smoke)
                .kerning(3)
            Text("Tap + to log your first meal and start earning Aura.")
                .font(AppTheme.T.body(13))
                .foregroundStyle(AppTheme.C.smoke)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .hudPanel(cut: 14, corners: [.topRight, .bottomLeft])
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HISTORY")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.cyan)
                .kerning(2)

            ForEach(entries.dropFirst()) { entry in
                NutritionHistoryRow(entry: entry)
            }
        }
    }

    private func ensureTodayEntry() {
        guard todayEntry == nil else { return }
        let entry = NutritionEntry()
        context.insert(entry)
        try? context.save()
    }
}

struct NutritionDayPanel: View {
    let entry: NutritionEntry
    let player: Player

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("TODAY")
                    .font(AppTheme.T.mono(10))
                    .foregroundStyle(AppTheme.C.cyan)
                    .kerning(2)
                Spacer()
                Text("\(Int(entry.adherenceScore * 100))% adherence")
                    .font(AppTheme.T.mono(11))
                    .foregroundStyle(AppTheme.C.gold)
                    .neonGlow(color: AppTheme.C.gold, radius: 3)
            }

            HStack(spacing: 16) {
                macroBar("Protein", current: entry.totalProteinG, goal: player.goalProteinG, unit: "g", color: AppTheme.C.cyan)
                macroBar("Fiber",   current: entry.totalFiberG,   goal: player.goalFiberG,   unit: "g", color: Color(hex: "00FF88"))
                macroBar("Sugar",   current: entry.addedSugarG,   goal: player.goalMaxSugarG, unit: "g", color: AppTheme.C.danger, inverted: true)
                macroBar("Calories", current: Double(entry.totalCalories), goal: Double(player.goalCalories), unit: "kcal", color: AppTheme.C.gold)
            }
        }
        .padding(14)
        .hudPanel(cut: 12, corners: [.topRight, .bottomLeft])
    }

    @ViewBuilder
    private func macroBar(_ label: String, current: Double, goal: Double,
                          unit: String, color: Color, inverted: Bool = false) -> some View {
        let fraction = inverted ? min(current / max(goal, 1), 1) : min(current / max(goal, 1), 1)
        let displayFraction = inverted ? fraction : fraction

        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.C.rim)
                    .frame(width: 6, height: 60)

                RoundedRectangle(cornerRadius: 2)
                    .fill(inverted && current > goal ? AppTheme.C.danger : color)
                    .frame(width: 6, height: 60 * displayFraction)
                    .neonGlow(color: color, radius: 3)
            }
            Text(String(format: "%.0f", current))
                .font(AppTheme.T.mono(10))
                .foregroundStyle(color)
                .fontVariantNumeric(.tabularNums)
            Text(label.uppercased())
                .font(AppTheme.T.mono(7))
                .foregroundStyle(AppTheme.C.smoke)
                .kerning(0.5)
        }
    }
}

struct MealListPanel: View {
    let entry: NutritionEntry

    private let tf: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MEALS")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.cyan)
                .kerning(2)

            if entry.meals.isEmpty {
                Text("No meals logged yet.")
                    .font(AppTheme.T.body(13))
                    .foregroundStyle(AppTheme.C.smoke)
                    .padding(.vertical, 6)
            } else {
                ForEach(entry.meals.sorted(by: { $0.loggedAt < $1.loggedAt })) { meal in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal.name)
                                .font(AppTheme.T.body(13))
                                .foregroundStyle(AppTheme.C.ash)
                            Text("\(meal.calories) kcal · \(String(format: "%.0f", meal.proteinG))g protein")
                                .font(AppTheme.T.mono(10))
                                .foregroundStyle(AppTheme.C.smoke)
                        }
                        Spacer()
                        Text(tf.string(from: meal.loggedAt))
                            .font(AppTheme.T.mono(10))
                            .foregroundStyle(AppTheme.C.smoke)
                    }
                    .padding(.vertical, 6)
                    Divider().background(AppTheme.C.rim)
                }
            }
        }
        .padding(14)
        .hudPanel()
    }
}

struct MicronutrientPanel: View {
    @Bindable var entry: NutritionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MICRONUTRIENTS")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.cyan)
                .kerning(2)

            HStack(spacing: 10) {
                microToggle("Omega-3", on: $entry.hadOmega3)
                microToggle("Vit D", on: $entry.hadVitaminD)
                microToggle("Magnesium", on: $entry.hadMagnesium)
                microToggle("Zinc", on: $entry.hadZinc)
            }
        }
        .padding(14)
        .hudPanel()
    }

    @ViewBuilder
    private func microToggle(_ label: String, on: Binding<Bool>) -> some View {
        Button {
            on.wrappedValue.toggle()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: on.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(on.wrappedValue ? AppTheme.C.cyan : AppTheme.C.rim)
                    .neonGlow(color: AppTheme.C.cyan, radius: on.wrappedValue ? 5 : 0)
                Text(label.uppercased())
                    .font(AppTheme.T.mono(8))
                    .foregroundStyle(on.wrappedValue ? AppTheme.C.ash : AppTheme.C.smoke)
                    .kerning(0.5)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct NutritionHistoryRow: View {
    let entry: NutritionEntry
    private let df: DateFormatter = { let f = DateFormatter(); f.dateStyle = .medium; return f }()

    var body: some View {
        HStack {
            Text(df.string(from: entry.date))
                .font(AppTheme.T.body(13))
                .foregroundStyle(AppTheme.C.ash)
            Spacer()
            Text("\(Int(entry.totalProteinG))g prot")
                .font(AppTheme.T.mono(11))
                .foregroundStyle(AppTheme.C.smoke)
            Text("\(Int(entry.adherenceScore * 100))%")
                .font(AppTheme.T.mono(12))
                .foregroundStyle(AppTheme.C.questCategory(.nutrition))
                .fontVariantNumeric(.tabularNums)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .hudPanel(cut: 6, corners: .topRight)
    }
}
