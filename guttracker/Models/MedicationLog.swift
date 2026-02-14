import Foundation
import SwiftData

/// 用藥紀錄 - 單次服藥記錄
@Model
final class MedicationLog {
    var id: UUID
    var timestamp: Date
    var medicationId: UUID?
    var medicationName: String
    var category: MedCategory
    var dosage: String
    var taken: Bool
    var skippedReason: String?
    var notes: String
    var createdAt: Date
    
    init(
        medicationName: String,
        category: MedCategory = .other,
        dosage: String = "",
        taken: Bool = true,
        timestamp: Date = .now
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.medicationName = medicationName
        self.category = category
        self.dosage = dosage
        self.taken = taken
        self.skippedReason = nil
        self.notes = ""
        self.createdAt = .now
    }
}

/// 藥物定義 - 使用者的藥物清單
@Model
final class Medication {
    var id: UUID
    var name: String
    var nameEN: String
    var category: MedCategory
    var defaultDosage: String
    var frequency: MedFrequency
    var isActive: Bool
    var sortOrder: Int
    
    // 提醒
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    
    var createdAt: Date
    
    init(
        name: String,
        nameEN: String = "",
        category: MedCategory = .other,
        defaultDosage: String = "",
        frequency: MedFrequency = .daily,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.nameEN = nameEN
        self.category = category
        self.defaultDosage = defaultDosage
        self.frequency = frequency
        self.isActive = true
        self.sortOrder = sortOrder
        self.reminderEnabled = false
        self.reminderHour = 8
        self.reminderMinute = 0
        self.createdAt = .now
    }
}

// MARK: - Enums

enum MedCategory: String, Codable, CaseIterable {
    case aminosalicylate  // 5-ASA
    case immunomodulator  // 免疫調節劑
    case biologic         // 生物製劑
    case steroid          // 類固醇
    case supplement       // 營養補充
    case other
    
    var displayName: String {
        switch self {
        case .aminosalicylate: return "5-ASA"
        case .immunomodulator: return "免疫調節"
        case .biologic: return "生物製劑"
        case .steroid: return "類固醇"
        case .supplement: return "營養補充"
        case .other: return "其他"
        }
    }
    
    var colorName: String {
        switch self {
        case .aminosalicylate: return "med5ASA"
        case .immunomodulator: return "medImmuno"
        case .biologic: return "medBiologic"
        case .steroid: return "medSteroid"
        case .supplement: return "medSupplement"
        case .other: return "medOther"
        }
    }
}

enum MedFrequency: String, Codable, CaseIterable {
    case daily
    case twiceDaily = "twice_daily"
    case threeDaily = "three_daily"
    case weekly
    case biweekly
    case monthly
    case asNeeded = "as_needed"
    
    var displayName: String {
        switch self {
        case .daily: return "每日一次"
        case .twiceDaily: return "每日兩次"
        case .threeDaily: return "每日三次"
        case .weekly: return "每週一次"
        case .biweekly: return "每兩週一次"
        case .monthly: return "每月一次"
        case .asNeeded: return "需要時"
        }
    }
}

// MARK: - 台灣常見 IBD 藥物預設資料

struct DefaultMedications {
    static let all: [(name: String, nameEN: String, category: MedCategory, dosage: String, frequency: MedFrequency)] = [
        // 5-ASA 類
        ("Pentasa", "Mesalamine", .aminosalicylate, "500mg", .twiceDaily),
        ("Asacol", "Mesalazine", .aminosalicylate, "400mg", .threeDaily),
        ("Sulfasalazine", "柳氮磺胺吡啶", .aminosalicylate, "500mg", .twiceDaily),
        
        // 免疫調節劑
        ("Imuran", "Azathioprine", .immunomodulator, "50mg", .daily),
        ("6-MP", "6-Mercaptopurine", .immunomodulator, "50mg", .daily),
        
        // 生物製劑
        ("Remicade", "Infliximab", .biologic, "5mg/kg", .biweekly),
        ("Humira", "Adalimumab", .biologic, "40mg", .biweekly),
        ("Entyvio", "Vedolizumab", .biologic, "300mg", .monthly),
        ("Stelara", "Ustekinumab", .biologic, "90mg", .monthly),
        
        // 類固醇
        ("Prednisolone", "潑尼松龍", .steroid, "5mg", .daily),
        ("Entocort", "Budesonide", .steroid, "3mg", .threeDaily),
        
        // 補充
        ("益生菌", "Probiotics", .supplement, "1顆", .daily),
        ("鐵劑", "Iron supplement", .supplement, "1顆", .daily),
        ("維生素D", "Vitamin D", .supplement, "1000IU", .daily),
    ]
    
    static func createMedication(at index: Int) -> Medication {
        let data = all[index]
        return Medication(
            name: data.name,
            nameEN: data.nameEN,
            category: data.category,
            defaultDosage: data.dosage,
            frequency: data.frequency,
            sortOrder: index
        )
    }
}
