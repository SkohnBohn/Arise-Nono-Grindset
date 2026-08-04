import SwiftUI

struct QuestStripView: View {
    let quests: [Quest]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Daily Quests")

            if quests.isEmpty {
                Text("No active quests — check back tomorrow.")
                    .font(AppTheme.T.mono(12))
                    .foregroundStyle(AppTheme.C.smoke)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hudPanel()
            } else {
                ForEach(quests) { quest in
                    QuestStripRow(quest: quest)
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppTheme.T.mono(10))
            .foregroundStyle(AppTheme.C.cyan)
            .kerning(2)
    }
}

struct QuestStripRow: View {
    let quest: Quest

    var body: some View {
        HStack(spacing: 12) {
            // Category dot
            Circle()
                .fill(AppTheme.C.questCategory(quest.category))
                .frame(width: 6, height: 6)
                .neonGlow(color: AppTheme.C.questCategory(quest.category), radius: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(quest.title)
                    .font(AppTheme.T.body(13))
                    .foregroundStyle(quest.isCompleted ? AppTheme.C.smoke : AppTheme.C.ash)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(AppTheme.C.rim).frame(height: 2)
                        Rectangle()
                            .fill(AppTheme.C.questCategory(quest.category))
                            .frame(width: geo.size.width * quest.progressFraction, height: 2)
                    }
                }
                .frame(height: 2)
            }

            Spacer()

            if quest.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.C.cyan)
                    .neonGlow(color: AppTheme.C.cyan, radius: 4)
            } else {
                Text("+\(quest.xpReward) XP")
                    .font(AppTheme.T.mono(10))
                    .foregroundStyle(AppTheme.C.gold)
                    .kerning(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .hudPanel(cut: 6, corners: [.topRight, .bottomLeft],
                  border: quest.isCompleted ? AppTheme.C.rim : AppTheme.C.cyanDim)
    }
}
