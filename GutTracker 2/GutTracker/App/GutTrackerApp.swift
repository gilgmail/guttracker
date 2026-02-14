import SwiftUI
import SwiftData

@main
struct GutTrackerApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BowelMovement.self,
            SymptomEntry.self,
            MedicationLog.self,
            Medication.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            // App Group 共享，讓 Widget Extension 也能存取
            groupContainer: .identifier("group.com.gil.guttracker")
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("無法建立 ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
