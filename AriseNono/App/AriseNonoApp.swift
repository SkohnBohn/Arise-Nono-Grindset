import SwiftUI
import SwiftData

@main
struct AriseNonoApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(
                    for: [WorkoutEntry.self, Player.self, Quest.self, QuickActionEntry.self],
                    isAutosaveEnabled: true
                )
                .preferredColorScheme(.dark)
        }
    }
}
