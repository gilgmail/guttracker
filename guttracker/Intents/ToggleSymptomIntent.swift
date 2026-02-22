import AppIntents
import SwiftData
import WidgetKit

struct ToggleSymptomIntent: AppIntent {
    static var title: LocalizedStringResource = "記錄症狀"
    static var description: IntentDescription = "切換今日症狀狀態"

    @Parameter(title: "Symptom Type")
    var symptomRaw: String

    init() {
        self.symptomRaw = ""
    }

    init(symptomType: SymptomType) {
        self.symptomRaw = symptomType.rawValue
    }

    func perform() async throws -> some IntentResult {
        guard let symptomType = SymptomType(rawValue: symptomRaw) else {
            return .result()
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

        // Toggle: 0 → 1, >0 → 0
        let current = getSeverity(entry: entry, type: symptomType)
        let next = current > 0 ? 0 : 1
        setSeverity(entry: entry, type: symptomType, value: next)
        entry.updatedAt = .now

        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: Constants.widgetKind)

        return .result()
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
