import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Query private var workouts: [WorkoutEntry]

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.C.void)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor   = UIColor(AppTheme.C.smoke)
        itemAppearance.selected.iconColor = UIColor(AppTheme.C.cyan)
        itemAppearance.normal.titleTextAttributes  = [.foregroundColor: UIColor(AppTheme.C.smoke)]
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.C.cyan)]
        appearance.stackedLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance  = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }

            WorkoutLogView()
                .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }

            QuestListView()
                .tabItem { Label("Quests", systemImage: "shield.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(AppTheme.C.cyan)
        .task {
            appState.initializeTodayXP(from: workouts)
        }
    }
}

// MARK: - Daily Gojo background

struct GojoDailyBackground: View {
    @Environment(AppState.self) private var appState

    private static func imageName(count: Int = 11) -> String {
        // One image per calendar day, cycling through all available images
        let days = Int(Date().timeIntervalSince1970 / 86400)
        return "bg_\((days % count) + 1)"
    }

    var body: some View {
        Image(Self.imageName())
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .opacity(appState.todayBgOpacity)
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.8), value: appState.todayBgOpacity)
    }
}
