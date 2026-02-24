import AppIntents
import SwiftData
import WidgetKit

struct ToggleMedicationIntent: AppIntent {
    static var title: LocalizedStringResource = "記錄用藥"
    static var description: IntentDescription = "切換今日用藥狀態"
    static var openAppWhenRun = false

    @Parameter(title: "Medication Name")
    var medicationName: String

    @Parameter(title: "Category")
    var categoryRaw: String

    @Parameter(title: "Dosage")
    var dosage: String

    static var parameterSummary: some ParameterSummary {
        Summary("記錄用藥 \(\.$medicationName)")
    }

    init() {
        self.medicationName = ""
        self.categoryRaw = MedCategory.other.rawValue
        self.dosage = ""
    }

    init(medicationName: String, category: MedCategory, dosage: String) {
        self.medicationName = medicationName
        self.categoryRaw = category.rawValue
        self.dosage = dosage
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = SharedContainer.modelContainer
        let context = ModelContext(container)

        let today = Calendar.current.startOfDay(for: .now)
        let name = medicationName

        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: #Predicate { $0.timestamp >= today && $0.medicationName == name }
        )
        let existing = try context.fetch(descriptor)

        let action: String
        if let log = existing.first {
            context.delete(log)
            action = "已取消"
        } else {
            let category = MedCategory(rawValue: categoryRaw) ?? .other
            let log = MedicationLog(
                medicationName: medicationName,
                category: category,
                dosage: dosage
            )
            context.insert(log)
            action = "已記錄"
        }

        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: Constants.widgetKind)

        return .result(dialog: "\(action)：\(medicationName)")
    }
}
