import Foundation
import SwiftData

/// App Group 共享 ModelContainer 配置
/// App 和 Widget Extension 共用同一個 SwiftData store
/// 主 App 額外啟用 CloudKit 同步
enum SharedContainer {
    static let appGroupIdentifier = "group.com.gil.guttracker"

    static let schema = Schema([
        BowelMovement.self,
        SymptomEntry.self,
        MedicationLog.self,
        Medication.self,
    ])

    /// 主 App 用：App Group + CloudKit 同步
    static var appModelConfiguration: ModelConfiguration {
        let hasAppGroup = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) != nil

        if hasAppGroup {
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(appGroupIdentifier),
                cloudKitDatabase: .automatic
            )
        } else {
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
        }
    }

    /// Widget 用：App Group only（Widget 不支援 CloudKit）
    static var widgetModelConfiguration: ModelConfiguration {
        let hasAppGroup = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) != nil

        if hasAppGroup {
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(appGroupIdentifier),
                cloudKitDatabase: .none
            )
        } else {
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
        }
    }

    /// 向後相容 — Widget 和 Intent 使用
    static var modelConfiguration: ModelConfiguration {
        widgetModelConfiguration
    }

    static var modelContainer: ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [widgetModelConfiguration])
        } catch {
            fatalError("無法建立共享 ModelContainer: \(error)")
        }
    }
}
