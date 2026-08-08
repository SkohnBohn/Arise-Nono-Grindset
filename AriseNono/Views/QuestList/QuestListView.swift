import SwiftUI
import SwiftData

struct QuestListView: View {
    @Query(sort: \Quest.expiresAt) private var allQuests: [Quest]
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query private var players: [Player]

    private var dailyActive:   [Quest] { allQuests.filter { $0.type == .daily  && $0.isActive } }
    private var weeklyActive:  [Quest] { allQuests.filter { $0.type == .weekly && $0.isActive } }
    private var completed:     [Quest] { allQuests.filter { $0.isCompleted } }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                GojoDailyBackground()
                ScanlineOverlay()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if dailyActive.isEmpty && weeklyActive.isEmpty {
                            noQuestsView
                        }

                        if !dailyActive.isEmpty {
                            sectionHeader("Daily Quests")
                            ForEach(dailyActive) { quest in
                                QuestRowView(quest: quest)
                            }
                        }

                        if !weeklyActive.isEmpty {
                            sectionHeader("Weekly Quests")
                            ForEach(weeklyActive) { quest in
                                QuestRowView(quest: quest)
                            }
                        }

                        if !completed.isEmpty {
                            sectionHeader("Completed")
                            ForEach(completed.prefix(10)) { quest in
                                QuestRowView(quest: quest)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("QUESTS")
                        .font(AppTheme.T.heading(15))
                        .foregroundStyle(AppTheme.C.snow)
                        .kerning(3)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        generateQuests()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(AppTheme.C.smoke)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        HStack(spacing: 8) {
            Text(text.uppercased())
                .font(AppTheme.T.mono(10))
                .foregroundStyle(AppTheme.C.cyan)
                .kerning(2)
            Rectangle()
                .fill(AppTheme.C.cyanDim)
                .frame(height: 1)
        }
    }

    private var noQuestsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.slash")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.C.smoke)
            Text("No active quests")
                .font(AppTheme.T.heading(15))
                .foregroundStyle(AppTheme.C.smoke)
            Button("Generate Quests") { generateQuests() }
                .font(AppTheme.T.heading(13))
                .foregroundStyle(AppTheme.C.cyan)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }

    private func generateQuests() {
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        let weekEnd  = Calendar.current.date(byAdding: .day, value: 7, to: .now)!

        // IDs that already have a live active quest — never duplicate these
        let activeIDs  = Set(allQuests.filter { $0.isActive }.map(\.templateID))
        let recentIDs  = Set(completed.prefix(6).map(\.templateID))
        let excludeIDs = activeIDs.union(recentIDs)

        // Only generate daily slots that aren't already filled
        let neededDaily  = max(0, 3 - dailyActive.count)
        let neededWeekly = max(0, 2 - weeklyActive.count)

        if neededDaily > 0 {
            let drafts = QuestEngine.generateDailyQuests(
                workoutHistory: [], recentlyCompletedIDs: excludeIDs
            ).prefix(neededDaily)
            for draft in drafts {
                let q = Quest(templateID: draft.templateID, type: draft.type, category: draft.category,
                             title: draft.title, description: draft.description,
                             targetValue: draft.targetValue, xpReward: draft.xpReward,
                             rewardType: draft.rewardType, expiresAt: midnight)
                context.insert(q)
            }
        }

        if neededWeekly > 0 {
            let drafts = QuestEngine.generateWeeklyQuests(recentlyCompletedIDs: excludeIDs)
                .prefix(neededWeekly)
            for draft in drafts {
                let q = Quest(templateID: draft.templateID, type: draft.type, category: draft.category,
                             title: draft.title, description: draft.description,
                             targetValue: draft.targetValue, xpReward: draft.xpReward,
                             rewardType: draft.rewardType, expiresAt: weekEnd)
                context.insert(q)
            }
        }

        try? context.save()
        appState.refreshQuestProgress(player: players.first, context: context)
    }
}
