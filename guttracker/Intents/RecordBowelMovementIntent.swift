import AppIntents
import SwiftData
import WidgetKit

struct RecordBowelMovementIntent: AppIntent {
    static var title: LocalizedStringResource = "記錄排便"
    static var description: IntentDescription = "快速記錄排便 Bristol 類型"

    @Parameter(title: "Bristol Type", default: 4)
    var bristolType: Int

    init() {}

    init(bristolType: Int) {
        self.bristolType = bristolType
    }

    func perform() async throws -> some IntentResult {
        let container = SharedContainer.modelContainer
        let context = ModelContext(container)

        let bm = BowelMovement(bristolType: bristolType)
        context.insert(bm)
        try context.save()

        WidgetCenter.shared.reloadTimelines(ofKind: Constants.widgetKind)

        return .result()
    }
}
