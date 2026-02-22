import SwiftUI
import SwiftData

@main
struct GutTrackerApp: App {

    @AppStorage("appTheme", store: UserDefaults(suiteName: Constants.appGroupIdentifier))
    private var selectedTheme: String = AppTheme.cream.rawValue

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

    private var theme: AppTheme {
        AppTheme(rawValue: selectedTheme) ?? .cream
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.appTheme, theme)
                .preferredColorScheme(theme.colorScheme)
                .onAppear {
                    NotificationService.shared.rescheduleAll(container: sharedModelContainer)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
