import SwiftUI

struct QuestRowView: View {
    let quest: Quest

    private var accent: Color { AppTheme.C.questCategory(quest.category) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Type badge
                Text(quest.type == .daily ? "DAILY" : "WEEKLY")
                    .font(AppTheme.T.mono(8))
                    .foregroundStyle(quest.type == .daily ? AppTheme.C.cyan : AppTheme.C.mag)
                    .kerning(1.5)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Rectangle()
                            .fill((quest.type == .daily ? AppTheme.C.cyan : AppTheme.C.mag).opacity(0.1))
                    )
                    .overlay(
                        Rectangle().stroke(
                            (quest.type == .daily ? AppTheme.C.cyanDim : AppTheme.C.magDim),
                            lineWidth: 1
                        )
                    )

                Spacer()

                // XP reward
                if quest.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.C.cyan)
                        .neonGlow(color: AppTheme.C.cyan, radius: 4)
                } else if quest.isExpired {
                    Text("EXPIRED")
                        .font(AppTheme.T.mono(9))
                        .foregroundStyle(AppTheme.C.danger)
                        .kerning(1)
                } else {
                    Text("+\(quest.xpReward) XP")
                        .font(AppTheme.T.mono(11))
                        .foregroundStyle(AppTheme.C.gold)
                }
            }

            Text(quest.title)
                .font(AppTheme.T.heading(15))
                .foregroundStyle(quest.isCompleted ? AppTheme.C.smoke : AppTheme.C.snow)

            Text(quest.questDescription)
                .font(AppTheme.T.body(12))
                .foregroundStyle(AppTheme.C.smoke)

            // Progress bar
            if !quest.isCompleted && !quest.isExpired {
                HStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(AppTheme.C.rim).frame(height: 3)
                            Rectangle()
                                .fill(accent)
                                .frame(width: geo.size.width * quest.progressFraction, height: 3)
                                .neonGlow(color: accent, radius: 3)
                        }
                    }
                    .frame(height: 3)

                    Text("\(Int(quest.currentValue))/\(Int(quest.targetValue))")
                        .font(AppTheme.T.mono(10))
                        .foregroundStyle(AppTheme.C.smoke)
                        .fontVariantNumeric(.tabularNums)
                }
            }
        }
        .padding(14)
        .hudPanel(cut: 10, corners: [.topRight, .bottomLeft],
                  border: quest.isCompleted ? AppTheme.C.rim : accent.opacity(0.4))
        .opacity(quest.isExpired ? 0.5 : 1.0)
    }
}
