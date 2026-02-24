import SwiftUI
import SwiftData
import WidgetKit

@main
struct GutTrackerApp: App {

    @Environment(\.scenePhase) private var scenePhase

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
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
