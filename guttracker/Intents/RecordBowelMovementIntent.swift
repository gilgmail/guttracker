import AppIntents
import SwiftData
import WidgetKit

enum BristolTypeEntity: String, AppEnum {
    case type1, type2, type3, type4, type5, type6, type7

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Bristol 類型"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .type1: "1", .type2: "2", .type3: "3", .type4: "4",
        .type5: "5", .type6: "6", .type7: "7",
    ]

    var intValue: Int {
        switch self {
        case .type1: return 1; case .type2: return 2; case .type3: return 3
        case .type4: return 4; case .type5: return 5; case .type6: return 6
        case .type7: return 7
        }
    }

    init(int: Int) {
        switch int {
        case 1: self = .type1; case 2: self = .type2; case 3: self = .type3
        case 5: self = .type5; case 6: self = .type6; case 7: self = .type7
        default: self = .type4
        }
    }
}

struct RecordBowelMovementIntent: AppIntent {
    static var title: LocalizedStringResource = "記錄排便"
    static var description: IntentDescription = "快速記錄排便 Bristol 類型"
    static var openAppWhenRun = false

    @Parameter(title: "Bristol 類型", default: BristolTypeEntity.type4)
    var bristolType: BristolTypeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("記錄 Bristol \(\.$bristolType) 型排便")
    }

    init() {}

    init(bristolType: Int) {
        self.bristolType = BristolTypeEntity(int: bristolType)
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = SharedContainer.modelContainer
        let context = ModelContext(container)

        let bm = BowelMovement(bristolType: bristolType.intValue)
        context.insert(bm)
        try context.save()

        WidgetCenter.shared.reloadTimelines(ofKind: Constants.widgetKind)

        return .result(dialog: "已記錄 Bristol \(bristolType.intValue) 型排便")
    }
}
