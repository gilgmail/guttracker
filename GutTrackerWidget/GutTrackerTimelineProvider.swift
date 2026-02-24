import WidgetKit
import SwiftData

struct GutTrackerTimelineProvider: TimelineProvider {
    typealias Entry = GutTrackerEntry

    func placeholder(in context: Context) -> GutTrackerEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (GutTrackerEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        completion(fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GutTrackerEntry>) -> Void) {
        let entry = fetchEntry()
        let refreshMinutes = Constants.widgetRefreshIntervalMinutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: refreshMinutes, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Smart Bristol Types

    /// 從歷史記錄計算最常用的 top-4 Bristol 類型。
    /// 新用戶無記錄時回傳 [3, 4, 5, 6]（最常見的 IBD 範圍）。
    private static func computeSmartBristolTypes(from bms: [BowelMovement]) -> [Int] {
        guard !bms.isEmpty else { return [3, 4, 5, 6] }
        var freq = [Int: Int]()
        for bm in bms { freq[bm.bristolType, default: 0] += 1 }
        let top4 = freq.sorted { $0.value > $1.value }.prefix(4).map(\.key).sorted()
        return top4.isEmpty ? [3, 4, 5, 6] : top4
    }

    // MARK: - Data Fetching

    private func fetchEntry() -> GutTrackerEntry {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: SharedContainer.schema,
                configurations: [SharedContainer.modelConfiguration]
            )
        } catch {
            return .empty
        }

        let context = ModelContext(container)
        let today = Calendar.current.startOfDay(for: .now)

        // Fetch 今日排便
        let bmDescriptor = FetchDescriptor<BowelMovement>(
            predicate: #Predicate { $0.timestamp >= today },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let bowelMovements = (try? context.fetch(bmDescriptor)) ?? []

        // Fetch 今日症狀
        let symDescriptor = FetchDescriptor<SymptomEntry>(
            predicate: #Predicate { $0.timestamp >= today },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let symptoms = (try? context.fetch(symDescriptor)) ?? []

        // Fetch 今日用藥
        let medLogDescriptor = FetchDescriptor<MedicationLog>(
            predicate: #Predicate { $0.timestamp >= today }
        )
        let medLogs = (try? context.fetch(medLogDescriptor)) ?? []

        // Fetch active 藥物
        let medDescriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let activeMeds = (try? context.fetch(medDescriptor)) ?? []

        // 讀取 App Group UserDefaults 中使用者自訂的 widget 按鈕清單
        let appGroupDefaults = UserDefaults(suiteName: Constants.appGroupIdentifier)

        // Bristol 類型：優先使用設定，否則從 30 天歷史自動計算
        let userBristolTypes: [Int] = {
            guard
                let raw = appGroupDefaults?.string(forKey: Constants.widgetBristolTypesKey),
                !raw.isEmpty
            else { return [] }
            return raw.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }()

        let smartBristolTypes: [Int]
        if !userBristolTypes.isEmpty {
            smartBristolTypes = userBristolTypes
        } else {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
            let histDescriptor = FetchDescriptor<BowelMovement>(
                predicate: #Predicate { $0.timestamp >= thirtyDaysAgo }
            )
            let histBMs = (try? context.fetch(histDescriptor)) ?? []
            smartBristolTypes = Self.computeSmartBristolTypes(from: histBMs)
        }

        // 症狀類型：優先使用設定，否則預設 4 種
        let widgetSymptomTypes: [String] = {
            guard
                let raw = appGroupDefaults?.string(forKey: Constants.widgetSymptomTypesKey),
                !raw.isEmpty
            else { return ["abdominalPain", "bloating", "nausea", "fatigue"] }
            let parsed = raw.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            return parsed.isEmpty ? ["abdominalPain", "bloating", "nausea", "fatigue"] : parsed
        }()

        // 組裝排便資料
        let bowelCount = bowelMovements.count
        let bristolTypes = bowelMovements.map(\.bristolType)
        let avgBristol = bristolTypes.isEmpty ? 0 : Double(bristolTypes.reduce(0, +)) / Double(bristolTypes.count)
        let hasBlood = bowelMovements.contains { $0.hasBlood }

        let recentRecords: [GutTrackerEntry.RecentRecord] = Array(bowelMovements.prefix(3)).map { bm in
            GutTrackerEntry.RecentRecord(
                time: bm.timestamp.timeString,
                bristolType: bm.bristolType,
                risk: bm.riskCategory
            )
        }

        // 組裝症狀
        let latestSymptom = symptoms.first
        let severity = latestSymptom?.overallSeverity ?? 0
        let statusEmoji: String
        switch severity {
        case 0: statusEmoji = "😊 良好"
        case 1: statusEmoji = "😐 輕微"
        case 2: statusEmoji = "😣 中等"
        default: statusEmoji = "🚨 嚴重"
        }
        let activeSymptomList = latestSymptom?.activeSymptomList ?? []
        let activeSymptomNames: [String] = activeSymptomList.map { type, _ in
            type.displayName
        }
        let activeSymptomTypes: [String] = activeSymptomList.map { type, _ in
            type.rawValue
        }
        let hasMucus = bowelMovements.contains { $0.hasMucus }

        // 組裝用藥
        let takenNames = Set(medLogs.map(\.medicationName))
        let medications: [GutTrackerEntry.MedStatus] = activeMeds.prefix(5).map { med in
            GutTrackerEntry.MedStatus(
                name: med.name,
                taken: takenNames.contains(med.name),
                category: med.category,
                dosage: med.defaultDosage
            )
        }

        return GutTrackerEntry(
            date: .now,
            bowelCount: bowelCount,
            avgBristol: avgBristol,
            bristolTypes: bristolTypes,
            smartBristolTypes: smartBristolTypes,
            recentRecords: recentRecords,
            hasBlood: hasBlood,
            symptomStatus: statusEmoji,
            symptomSeverity: severity,
            activeSymptomNames: activeSymptomNames,
            activeSymptomTypes: activeSymptomTypes,
            widgetSymptomTypes: widgetSymptomTypes,
            hasMucus: hasMucus,
            medications: medications,
            medsTaken: takenNames.intersection(Set(activeMeds.map(\.name))).count,
            medsTotal: activeMeds.count
        )
    }
}
