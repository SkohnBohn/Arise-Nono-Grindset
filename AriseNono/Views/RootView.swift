import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlow {
                    hasCompletedOnboarding = true
                }
            }

            if let moment = appState.activeMoment {
                MomentOverlay(moment: moment)
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.activeMoment != nil)
        .background(AppTheme.C.void.ignoresSafeArea())
    }
}

struct MomentOverlay: View {
    @Environment(AppState.self) private var appState
    let moment: AppState.MomentType

    var body: some View {
        Group {
            switch moment {
            case .levelUp(let level):
                LevelUpCard(level: level) { appState.dismissMoment() }
            case .rankUp(let rank):
                RankUpCard(rank: rank) { appState.dismissMoment() }
            case .streakMilestone(let days):
                StreakMilestoneCard(days: days) { appState.dismissMoment() }
            }
        }
    }
}
