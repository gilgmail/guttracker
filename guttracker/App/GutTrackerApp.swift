import SwiftUI
import SwiftData

@main
struct GutTrackerApp: App {

    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: SharedContainer.schema,
                configurations: [SharedContainer.appModelConfiguration]
            )
        } catch {
            fatalError("無法建立 ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    NotificationService.shared.rescheduleAll(container: sharedModelContainer)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
