import HealthKit
import SwiftData

actor HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    // MARK: - Types

    static let writeTypes: Set<HKSampleType> = [
        HKCategoryType(.abdominalCramps),
        HKCategoryType(.bloating),
        HKCategoryType(.constipation),
        HKCategoryType(.diarrhea),
        HKCategoryType(.nausea),
        HKCategoryType(.vomiting),
        HKCategoryType(.fatigue),
        HKCategoryType(.fever),
    ]

    static let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKCategoryType(.sleepAnalysis),
        HKQuantityType(.heartRate),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.bodyMass),
        // Also read back our written symptom types
        HKCategoryType(.abdominalCramps),
        HKCategoryType(.bloating),
        HKCategoryType(.diarrhea),
        HKCategoryType(.constipation),
    ]

    // MARK: - Availability & Authorization

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthKitError.notAvailable }
        try await store.requestAuthorization(toShare: Self.writeTypes, read: Self.readTypes)
    }

    // MARK: - Write: Bowel Movement → HealthKit

    func syncBowelMovement(_ bm: BowelMovement) async throws -> String? {
        var savedIDs: [String] = []

        // Bristol 1-2 → constipation
        if bm.bristolType <= 2 {
            let severity: HKCategoryValueSeverity = bm.bristolType == 1 ? .severe : .moderate
            let id = try await writeSymptom(.constipation, severity: severity, date: bm.timestamp,
                                            metadata: ["BristolType": bm.bristolType])
            savedIDs.append(id)
        }
        // Bristol 6-7 → diarrhea
        else if bm.bristolType >= 6 {
            let severity: HKCategoryValueSeverity = bm.bristolType == 7 ? .severe : .moderate
            let id = try await writeSymptom(.diarrhea, severity: severity, date: bm.timestamp,
                                            metadata: ["BristolType": bm.bristolType])
            savedIDs.append(id)
        }

        // Pain → abdominal cramps
        if bm.painLevel > 3 {
            let severity: HKCategoryValueSeverity = bm.painLevel > 7 ? .severe :
                                                     bm.painLevel > 5 ? .moderate : .mild
            let id = try await writeSymptom(.abdominalCramps, severity: severity, date: bm.timestamp)
            savedIDs.append(id)
        }

        return savedIDs.first
    }

    // MARK: - Write: Symptoms → HealthKit

    func syncSymptomEntry(_ entry: SymptomEntry) async throws {
        let date = entry.timestamp

        if entry.abdominalPain > 0 || entry.cramping > 0 {
            let sev = max(entry.abdominalPain, entry.cramping)
            try await writeSymptom(.abdominalCramps, severity: intToSeverity(sev), date: date)
        }
        if entry.bloating > 0 {
            try await writeSymptom(.bloating, severity: intToSeverity(entry.bloating), date: date)
        }
        if entry.nausea > 0 {
            try await writeSymptom(.nausea, severity: intToSeverity(entry.nausea), date: date)
        }
        if entry.fatigue > 0 {
            try await writeSymptom(.fatigue, severity: intToSeverity(entry.fatigue), date: date)
        }
        if entry.fever {
            try await writeSymptom(.fever, severity: .moderate, date: date)
        }
    }

    // MARK: - Read: Sleep

    func fetchSleepHours(for date: Date) async throws -> Double {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay.addingTimeInterval(-43200), // noon previous day
            end: endOfDay,
            options: .strictStartDate
        )

        let sleepType = HKCategoryType(.sleepAnalysis)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )

        let samples = try await descriptor.result(for: store)
        let asleepSeconds = samples
            .filter {
                $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
            }
            .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

        return asleepSeconds / 3600.0
    }

    // MARK: - Read: Steps

    func fetchSteps(for date: Date) async throws -> Int {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)

        let stepType = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum
        )

        let result = try await descriptor.result(for: store)
        return Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
    }

    // MARK: - Read: Resting Heart Rate

    func fetchRestingHeartRate(for date: Date) async throws -> Int? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)

        let hrType = HKQuantityType(.restingHeartRate)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )

        let samples = try await descriptor.result(for: store)
        guard let sample = samples.first as? HKQuantitySample else { return nil }
        return Int(sample.quantity.doubleValue(for: .count().unitDivided(by: .minute())))
    }

    // MARK: - Private Helpers

    @discardableResult
    private func writeSymptom(
        _ type: HKCategoryTypeIdentifier,
        severity: HKCategoryValueSeverity,
        date: Date,
        metadata: [String: Any] = [:]
    ) async throws -> String {
        let categoryType = HKCategoryType(type)
        var meta: [String: Any] = [
            HKMetadataKeyWasUserEntered: true,
            "AppSource": "GutTracker"
        ]
        for (k, v) in metadata { meta[k] = v }

        let sample = HKCategorySample(
            type: categoryType,
            value: severity.rawValue,
            start: date,
            end: date.addingTimeInterval(60),
            metadata: meta
        )
        try await store.save(sample)
        return sample.uuid.uuidString
    }

    private func intToSeverity(_ value: Int) -> HKCategoryValueSeverity {
        switch value {
        case 1: return .mild
        case 2: return .moderate
        case 3: return .severe
        default: return .unspecified
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "此裝置不支援 HealthKit"
        }
    }
}
