import SwiftUI

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.C.void)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor  = UIColor(AppTheme.C.smoke)
        itemAppearance.selected.iconColor = UIColor(AppTheme.C.cyan)
        itemAppearance.normal.titleTextAttributes  = [.foregroundColor: UIColor(AppTheme.C.smoke)]
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.C.cyan)]
        appearance.stackedLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance  = appearance
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
    }
}
