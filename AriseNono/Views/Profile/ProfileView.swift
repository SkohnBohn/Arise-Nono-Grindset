import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var players: [Player]
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var workouts: [WorkoutEntry]
    @Query(sort: \QuickActionEntry.date, order: .reverse) private var quickActions: [QuickActionEntry]
    @Environment(\.modelContext) private var context
    @State private var showingGoals = false

    private var player: Player? { players.first }
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                GojoDailyBackground()
                ScanlineOverlay()

                ScrollView {
                    VStack(spacing: 16) {
                        if let player {
                            rankBadgeSection(player)
                            statsGrid(player)
                            auraBreakdown(player)
                            heatmapSection
                            weeklyGoalsSection(player)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PROFILE")
                        .font(AppTheme.T.heading(15))
                        .foregroundStyle(AppTheme.C.snow)
                        .kerning(3)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingGoals = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(AppTheme.C.smoke)
                    }
                }
            }
            .sheet(isPresented: $showingGoals) {
                if let player { AdjustGoalsSheet(player: player) }
            }
        }
    }

    // MARK: - Rank Badge

    @ViewBuilder
    private func rankBadgeSection(_ player: Player) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(AppTheme.C.rank(player.rankTier), lineWidth: 3)
                    .frame(width: 90, height: 90)
                    .neonGlow(color: AppTheme.C.rank(player.rankTier), radius: 12)
                Image("profilePicture")
                    .resizable().scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
            }
            Text(player.name.uppercased())
                .font(AppTheme.T.heading(22))
                .foregroundStyle(AppTheme.C.snow)
                .kerning(2)
            Text(player.rankTier.displayName.uppercased())
                .font(AppTheme.T.mono(12))
                .foregroundStyle(AppTheme.C.rank(player.rankTier))
                .kerning(4)
                .neonGlow(color: AppTheme.C.rank(player.rankTier), radius: 5)
            XPBarView(fraction: player.levelFraction)
                .frame(width: 200)
            Text("Level \(player.level) — \(player.xpProgressInLevel) / \(player.xpForNextLevel) XP")
                .font(AppTheme.T.mono(11))
                .foregroundStyle(AppTheme.C.smoke)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .hudPanel(cut: 16, corners: [.topRight, .bottomLeft])
    }

    // MARK: - Stats Grid

    @ViewBuilder
    private func statsGrid(_ player: Player) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            statCard("Total XP",    value: "\(player.totalXP)",               accent: AppTheme.C.gold)
            statCard("Sessions",    value: "\(workouts.count)",                accent: AppTheme.C.cyan)
            statCard("Best Streak", value: "\(player.longestStreak)d",        accent: AppTheme.C.mag)
            statCard("Cur. Streak", value: "\(player.currentStreak)d",        accent: AppTheme.C.cyan)
            statCard("Freezes",     value: "\(player.streakFreezeBalance)",    accent: AppTheme.C.smoke)
            statCard("Aura",        value: String(format: "%.0f", player.auraScore), accent: AppTheme.C.mag)
        }
    }

    @ViewBuilder
    private func statCard(_ label: String, value: String, accent: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.T.mono(20))
                .foregroundStyle(accent)
                .fontWeight(.bold)
                .neonGlow(color: accent, radius: 4)
                .monospacedDigit()
            Text(label.uppercased())
                .font(AppTheme.T.mono(8))
                .foregroundStyle(AppTheme.C.smoke)
                .kerning(1)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .hudPanel(cut: 6, corners: .topRight)
    }

    // MARK: - Aura Breakdown

    @ViewBuilder
    private func auraBreakdown(_ player: Player) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AURA BREAKDOWN")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.mag)
                .kerning(2)

            auraBar("Consistency", fraction: min(Double(player.currentStreak) / 30.0, 1), color: AppTheme.C.cyan)
            auraBar("Variety",     fraction: varietyFraction, color: AppTheme.C.mag)

            Text("Overall Aura: \(Int(player.auraScore)) / 1000")
                .font(AppTheme.T.mono(13))
                .foregroundStyle(AppTheme.C.ash)
        }
        .padding(14)
        .hudPanel(cut: 10, corners: [.topRight, .bottomLeft], border: AppTheme.C.magDim)
    }

    @ViewBuilder
    private func auraBar(_ label: String, fraction: Double, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(label.uppercased())
                .font(AppTheme.T.mono(9))
                .foregroundStyle(AppTheme.C.smoke)
                .frame(width: 88, alignment: .leading)
                .kerning(1)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(AppTheme.C.rim).frame(height: 4)
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * fraction, height: 4)
                        .neonGlow(color: color, radius: 3)
                }
            }
            .frame(height: 4)
            Text("\(Int(fraction * 100))%")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.smoke)
                .frame(width: 32, alignment: .trailing)
                .monospacedDigit()
        }
    }

    private var varietyFraction: Double {
        let cutoff = calendar.date(byAdding: .day, value: -14, to: .now)!
        let groups = Set(workouts.filter { $0.date >= cutoff }.flatMap { $0.sets.map(\.muscleGroup) })
        return Double(groups.count) / 7.0
    }

    // MARK: - Activity Heatmap

    private var heatmapDays: [Date] {
        (0..<30).map { offset in
            let d = calendar.date(byAdding: .day, value: -(29 - offset), to: .now)!
            return calendar.startOfDay(for: d)
        }
    }

    private func activities(for day: Date) -> [ActivityType] {
        var types = Set<ActivityType>()

        for w in workouts {
            guard calendar.isDate(w.date, inSameDayAs: day) else { continue }
            for s in w.sets {
                if s.exerciseName == "Strength" { types.insert(.strength) }
                if s.exerciseName == "Cardio"   { types.insert(.cardio) }
            }
        }

        for q in quickActions {
            guard calendar.isDate(q.date, inSameDayAs: day),
                  let t = q.activityType else { continue }
            types.insert(t)
        }

        return ActivityType.allCases.filter { types.contains($0) }
    }

    @ViewBuilder
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("30-DAY ACTIVITY")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.cyan)
                .kerning(2)

            // Legend
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ActivityType.allCases) { type in
                        HStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(type.color)
                                .frame(width: 10, height: 10)
                            Text(type.shortLabel)
                                .font(AppTheme.T.mono(9))
                                .foregroundStyle(AppTheme.C.smoke)
                        }
                    }
                }
            }

            // Grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                spacing: 4
            ) {
                ForEach(heatmapDays, id: \.self) { day in
                    heatCell(for: day)
                }
            }
        }
        .padding(14)
        .hudPanel(cut: 10, corners: [.topRight, .bottomLeft])
    }

    @ViewBuilder
    private func heatCell(for day: Date) -> some View {
        let acts = activities(for: day)
        let dayNum = calendar.component(.day, from: day)

        ZStack {
            if acts.isEmpty {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.C.rim)
            } else {
                HStack(spacing: 0) {
                    ForEach(acts) { type in
                        type.color
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text("\(dayNum)")
                .font(.system(size: 8, weight: acts.isEmpty ? .regular : .bold, design: .monospaced))
                .foregroundStyle(acts.isEmpty ? AppTheme.C.smoke.opacity(0.45) : AppTheme.C.void.opacity(0.75))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Weekly Goals

    private var weekStart: Date {
        calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
    }

    private func activeDaysThisWeek(for type: ActivityType) -> Int {
        var days = Set<String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        switch type {
        case .strength, .cardio:
            for w in workouts {
                guard w.date >= weekStart else { continue }
                let hasType = w.sets.contains {
                    (type == .strength && $0.exerciseName == "Strength") ||
                    (type == .cardio   && $0.exerciseName == "Cardio")
                }
                if hasType { days.insert(formatter.string(from: w.date)) }
            }
        default:
            for q in quickActions {
                guard q.date >= weekStart, q.activityType == type else { continue }
                days.insert(formatter.string(from: q.date))
            }
        }

        return days.count
    }

    @ViewBuilder
    private func weeklyGoalsSection(_ player: Player) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WEEKLY GOALS")
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.gold)
                .kerning(2)

            ForEach(ActivityType.allCases) { type in
                let actual = activeDaysThisWeek(for: type)
                let goal   = player.goal(for: type)
                goalProgressRow(type: type, actual: actual, goal: goal)
            }
        }
        .padding(14)
        .hudPanel(cut: 10, corners: [.topRight, .bottomLeft], border: AppTheme.C.gold.opacity(0.3))
    }

    @ViewBuilder
    private func goalProgressRow(type: ActivityType, actual: Int, goal: Int) -> some View {
        let fraction: Double = goal > 0 ? min(Double(actual) / Double(goal), 1.0) : 0
        let met = actual >= goal && goal > 0

        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Circle()
                    .fill(type.color)
                    .frame(width: 7, height: 7)
                    .neonGlow(color: type.color, radius: 2)
                Text(type.label)
                    .font(AppTheme.T.mono(10))
                    .foregroundStyle(AppTheme.C.ash)
                    .kerning(0.8)
                Spacer()
                Text("\(actual) / \(goal)d")
                    .font(AppTheme.T.mono(11))
                    .foregroundStyle(met ? type.color : AppTheme.C.smoke)
                    .monospacedDigit()
                if met {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(type.color)
                        .neonGlow(color: type.color, radius: 3)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppTheme.C.rim)
                        .frame(height: 3)
                    Rectangle()
                        .fill(type.color)
                        .frame(width: geo.size.width * fraction, height: 3)
                        .neonGlow(color: type.color, radius: 2)
                }
            }
            .frame(height: 3)
        }
    }
}
