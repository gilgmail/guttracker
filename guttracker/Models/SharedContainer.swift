import Foundation
import SwiftData

/// App Group 共享 ModelContainer 配置
/// App 和 Widget Extension 共用同一個 SwiftData store
enum SharedContainer {
    static let appGroupIdentifier = "group.com.gil.guttracker"
    
    static let schema = Schema([
        BowelMovement.self,
        SymptomEntry.self,
        MedicationLog.self,
        Medication.self,
    ])
    
    static var modelConfiguration: ModelConfiguration {
        let hasAppGroup = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) != nil

        if hasAppGroup {
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(appGroupIdentifier)
            )
        } else {
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
        }
    }
    
    static var modelContainer: ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("無法建立共享 ModelContainer: \(error)")
        }
    }
}
