import AppIntents
import SwiftData
import WidgetKit

struct RecordBowelMovementIntent: AppIntent {
    static var title: LocalizedStringResource = "記錄排便"
    static var description: IntentDescription = "快速記錄排便 Bristol 類型"
    static var openAppWhenRun = false

    @Parameter(title: "Bristol Type", default: 4)
    var bristolType: Int

    static var parameterSummary: some ParameterSummary {
        Summary("記錄 \(\.$bristolType) 型排便")
    }

    init() {}

    init(bristolType: Int) {
        self.bristolType = bristolType
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = SharedContainer.modelContainer
        let context = ModelContext(container)

        let bm = BowelMovement(bristolType: bristolType)
        context.insert(bm)
        try context.save()

        WidgetCenter.shared.reloadTimelines(ofKind: Constants.widgetKind)

        return .result(dialog: "已記錄 Bristol \(bristolType) 型排便")
    }
}
