import SwiftUI
import SwiftData

struct AddMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var players: [Player]

    @State private var name: String = ""
    @State private var calories: String = ""
    @State private var proteinG: String = ""
    @State private var carbsG: String = ""
    @State private var fatG: String = ""
    @State private var fiberG: String = ""
    @State private var addedSugarG: String = ""
    @State private var loggedAt: Date = .now

    // Today's entry — passed in or fetched
    var todayEntry: NutritionEntry

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        TextField("Meal name", text: $name)
                            .font(AppTheme.T.heading(18))
                            .foregroundStyle(AppTheme.C.snow)
                            .padding(14)
                            .hudPanel()

                        DatePicker("Time", selection: $loggedAt, displayedComponents: .hourAndMinute)
                            .foregroundStyle(AppTheme.C.ash)
                            .colorScheme(.dark)
                            .padding(12)
                            .hudPanel()

                        macroGrid

                        // Blueprint presets
                        VStack(alignment: .leading, spacing: 8) {
                            Text("QUICK ADD")
                                .font(AppTheme.T.mono(9))
                                .foregroundStyle(AppTheme.C.smoke)
                                .kerning(2)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(MealPreset.blueprintPresets) { preset in
                                        presetChip(preset)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.C.smoke)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .foregroundStyle(AppTheme.C.cyan)
                        .fontWeight(.bold)
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private var macroGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            macroField("Calories (kcal)", binding: $calories)
            macroField("Protein (g)", binding: $proteinG)
            macroField("Carbs (g)", binding: $carbsG)
            macroField("Fat (g)", binding: $fatG)
            macroField("Fiber (g)", binding: $fiberG)
            macroField("Added Sugar (g)", binding: $addedSugarG)
        }
    }

    @ViewBuilder
    private func macroField(_ label: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(AppTheme.T.mono(8))
                .foregroundStyle(AppTheme.C.smoke)
                .kerning(1)
            TextField("0", text: binding)
                .keyboardType(.decimalPad)
                .font(AppTheme.T.mono(16))
                .foregroundStyle(AppTheme.C.cyan)
        }
        .padding(10)
        .hudPanel(cut: 6, corners: .topRight)
    }

    @ViewBuilder
    private func presetChip(_ preset: MealPreset) -> some View {
        Button {
            applyPreset(preset)
        } label: {
            Text(preset.name)
                .font(AppTheme.T.mono(11))
                .foregroundStyle(AppTheme.C.ash)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .hudPanel(cut: 4, corners: .topRight, border: AppTheme.C.rim)
        }
        .buttonStyle(.plain)
    }

    private func applyPreset(_ preset: MealPreset) {
        name = preset.name
        calories = "\(preset.calories)"
        proteinG = "\(preset.proteinG)"
        carbsG = "\(preset.carbsG)"
        fatG = "\(preset.fatG)"
        fiberG = "\(preset.fiberG)"
        addedSugarG = "0"
    }

    private func save() {
        let meal = MealItem(
            name: name,
            calories: Int(calories) ?? 0,
            proteinG: Double(proteinG) ?? 0,
            carbsG: Double(carbsG) ?? 0,
            fatG: Double(fatG) ?? 0,
            fiberG: Double(fiberG) ?? 0,
            addedSugarG: Double(addedSugarG) ?? 0,
            loggedAt: loggedAt
        )
        meal.entry = todayEntry
        context.insert(meal)
        todayEntry.meals.append(meal)
        todayEntry.recompute(from: todayEntry.meals)

        if let player = players.first {
            let goals = NutritionGoals(
                calories: player.goalCalories,
                proteinG: player.goalProteinG,
                fiberG: player.goalFiberG,
                maxSugarG: player.goalMaxSugarG,
                eatingWindowHours: player.goalEatingWindowH
            )
            let dayData = NutritionDayData(
                totalCalories: todayEntry.totalCalories,
                totalProteinG: todayEntry.totalProteinG,
                totalFiberG: todayEntry.totalFiberG,
                addedSugarG: todayEntry.addedSugarG,
                eatingWindowHours: todayEntry.eatingWindowHours
            )
            todayEntry.adherenceScore = NutritionScorer.adherenceScore(day: dayData, goals: goals)
        }

        try? context.save()
        dismiss()
    }
}

struct MealPreset: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double

    static let blueprintPresets: [MealPreset] = [
        MealPreset(name: "Collagen Peptides", calories: 70,  proteinG: 18, carbsG: 0,  fatG: 0,  fiberG: 0),
        MealPreset(name: "Lentils 100g",       calories: 116, proteinG: 9,  carbsG: 20, fatG: 0.4, fiberG: 8),
        MealPreset(name: "Salmon 150g",        calories: 280, proteinG: 40, carbsG: 0,  fatG: 14,  fiberG: 0),
        MealPreset(name: "Berries 150g",       calories: 75,  proteinG: 1,  carbsG: 18, fatG: 0.5, fiberG: 5),
        MealPreset(name: "Extra Virgin Olive Oil 15ml", calories: 120, proteinG: 0, carbsG: 0, fatG: 14, fiberG: 0),
        MealPreset(name: "Walnuts 30g",        calories: 196, proteinG: 4.6, carbsG: 4, fatG: 19.5, fiberG: 2),
        MealPreset(name: "Sweet Potato 200g",  calories: 172, proteinG: 3.2, carbsG: 40, fatG: 0.2, fiberG: 5.9),
    ]
}
