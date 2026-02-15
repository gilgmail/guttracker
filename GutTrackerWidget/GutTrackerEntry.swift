import WidgetKit

struct GutTrackerEntry: TimelineEntry {
    let date: Date

    // 排便
    let bowelCount: Int
    let avgBristol: Double
    let bristolTypes: [Int]
    let recentRecords: [RecentRecord]
    let hasBlood: Bool

    // 症狀
    let symptomStatus: String
    let symptomSeverity: Int

    // 用藥
    let medications: [MedStatus]
    let medsTaken: Int
    let medsTotal: Int

    struct RecentRecord {
        let time: String
        let bristolType: Int
        let risk: BristolRisk
    }

    struct MedStatus {
        let name: String
        let taken: Bool
        let category: MedCategory
        let dosage: String
    }

    static var placeholder: GutTrackerEntry {
        GutTrackerEntry(
            date: .now,
            bowelCount: 2,
            avgBristol: 4.0,
            bristolTypes: [4, 5],
            recentRecords: [
                RecentRecord(time: "08:30", bristolType: 4, risk: .normal),
                RecentRecord(time: "14:15", bristolType: 5, risk: .normal),
            ],
            hasBlood: false,
            symptomStatus: "😊 良好",
            symptomSeverity: 0,
            medications: [
                MedStatus(name: "Pentasa", taken: true, category: .aminosalicylate, dosage: "500mg"),
                MedStatus(name: "Imuran", taken: false, category: .immunomodulator, dosage: "50mg"),
                MedStatus(name: "益生菌", taken: true, category: .supplement, dosage: "1顆"),
            ],
            medsTaken: 2,
            medsTotal: 3
        )
    }

    static var empty: GutTrackerEntry {
        GutTrackerEntry(
            date: .now,
            bowelCount: 0,
            avgBristol: 0,
            bristolTypes: [],
            recentRecords: [],
            hasBlood: false,
            symptomStatus: "😊 良好",
            symptomSeverity: 0,
            medications: [],
            medsTaken: 0,
            medsTotal: 0
        )
    }
}
