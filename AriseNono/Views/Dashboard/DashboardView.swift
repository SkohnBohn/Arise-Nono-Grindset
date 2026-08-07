import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context

    @Query private var players: [Player]
    @Query(sort: \Quest.expiresAt) private var allQuests: [Quest]

    private var player: Player? { players.first }
    private var dailyQuests: [Quest] { allQuests.filter { $0.type == .daily && $0.isActive } }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.C.void.ignoresSafeArea()
                ScanlineOverlay()

                ScrollView {
                    VStack(spacing: 16) {
                        if let player {
                            PlayerCardView(player: player)
                        }

                        QuestStripView(quests: Array(dailyQuests.prefix(3)))
                    }
                    .padding(16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ARISE")
                        .font(AppTheme.T.heading(18))
                        .foregroundStyle(AppTheme.C.cyan)
                        .kerning(6)
                        .neonGlow(color: AppTheme.C.cyan, radius: 6)
                }
            }
        }
    }
}
