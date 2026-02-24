import AppIntents
import SwiftData
import WidgetKit

enum SymptomTypeEntity: String, AppEnum {
    case abdominalPain, bloating, nausea, fatigue, cramping, gas, fever, jointPain, bowelSounds

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "症狀類型"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .abdominalPain: "腹痛",
        .bloating: "腹脹",
        .nausea: "噁心",
        .fatigue: "疲倦",
        .cramping: "絞痛",
        .gas: "脹氣",
        .fever: "發燒",
        .jointPain: "關節痛",
        .bowelSounds: "腸鳴",
    ]
}

struct ToggleSymptomIntent: AppIntent {
    static var title: LocalizedStringResource = "記錄症狀"
    static var description: IntentDescription = "切換今日症狀狀態"
    static var openAppWhenRun = false

    @Parameter(title: "症狀類型")
    var symptomType: SymptomTypeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("記錄 \(\.$symptomType)")
    }

    init() {
        self.symptomType = .abdominalPain
    }

    init(symptomType: SymptomTypeEntity) {
        self.symptomType = symptomType
    }

    init(symptomType: SymptomType) {
        self.symptomType = SymptomTypeEntity(rawValue: symptomType.rawValue) ?? .abdominalPain
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let modelSymptomType = SymptomType(rawValue: symptomType.rawValue) else {
            return .result(dialog: "無法識別症狀類型")
        }

        let container = SharedContainer.modelContainer
        let context = ModelContext(container)

        let today = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<SymptomEntry>(
            predicate: #Predicate { $0.timestamp >= today },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let existing = try context.fetch(descriptor)

        let entry: SymptomEntry
        if let found = existing.first {
            entry = found
        } else {
            entry = SymptomEntry()
            context.insert(entry)
        }

        let current = getSeverity(entry: entry, type: modelSymptomType)
        let next = current > 0 ? 0 : 1
        setSeverity(entry: entry, type: modelSymptomType, value: next)
        entry.updatedAt = .now

        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: Constants.widgetKind)

        let actionText = next > 0 ? "已記錄" : "已取消"
        return .result(dialog: "\(actionText)：\(modelSymptomType.displayName)")
    }

    private func getSeverity(entry: SymptomEntry, type: SymptomType) -> Int {
        switch type {
        case .abdominalPain: return entry.abdominalPain
        case .bloating: return entry.bloating
        case .gas: return entry.gas
        case .nausea: return entry.nausea
        case .cramping: return entry.cramping
        case .bowelSounds: return entry.bowelSounds
        case .fatigue: return entry.fatigue
        case .fever: return entry.fever ? 2 : 0
        case .jointPain: return entry.jointPain
        }
    }

    private func setSeverity(entry: SymptomEntry, type: SymptomType, value: Int) {
        switch type {
        case .abdominalPain: entry.abdominalPain = value
        case .bloating: entry.bloating = value
        case .gas: entry.gas = value
        case .nausea: entry.nausea = value
        case .cramping: entry.cramping = value
        case .bowelSounds: entry.bowelSounds = value
        case .fatigue: entry.fatigue = value
        case .fever: entry.fever = value > 0
        case .jointPain: entry.jointPain = value
        }
    }
}
