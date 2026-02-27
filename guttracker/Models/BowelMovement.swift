import Foundation
import SwiftData

/// 排便記錄 - 核心資料模型
/// Bristol Stool Scale: 1(硬塊) → 7(水狀)
@Model
final class BowelMovement {
    var id: UUID = UUID()
    var timestamp: Date = Date.now

    // ── Bristol Stool Scale (1-7) ──
    var bristolType: Int = 4

    // ── 特徵標記 ──
    var hasBlood: Bool = false
    var hasMucus: Bool = false
    var urgency: Int = 0          // 0=無, 1=輕微, 2=中等, 3=緊急
    var completeness: Int = 2     // 0=不完全, 1=部分, 2=完全
    var straining: Int = 0        // 0=無, 1=輕微, 2=中等, 3=嚴重
    var painLevel: Int = 0        // 0-10
    var durationMinutes: Int = 0

    // ── 外觀 ──
    var volume: Int = 2           // 1=少, 2=正常, 3=多
    var color: BowelColor = BowelColor.brown

    // ── 備註 ──
    var notes: String = ""

    // ── HealthKit 同步 ──
    var healthKitSynced: Bool = false
    var healthKitUUID: String?

    // ── 時間戳 ──
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    
    init(
        bristolType: Int = 4,
        timestamp: Date = .now,
        hasBlood: Bool = false,
        hasMucus: Bool = false,
        urgency: Int = 0,
        completeness: Int = 2,
        straining: Int = 0,
        painLevel: Int = 0,
        durationMinutes: Int = 0,
        volume: Int = 2,
        color: BowelColor = .brown,
        notes: String = ""
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.bristolType = bristolType
        self.hasBlood = hasBlood
        self.hasMucus = hasMucus
        self.urgency = urgency
        self.completeness = completeness
        self.straining = straining
        self.painLevel = painLevel
        self.durationMinutes = durationMinutes
        self.volume = volume
        self.color = color
        self.notes = notes
        self.healthKitSynced = false
        self.healthKitUUID = nil
        self.createdAt = .now
        self.updatedAt = .now
    }
}

// MARK: - Computed Properties

extension BowelMovement {
    /// Bristol 風險分類
    var riskCategory: BristolRisk {
        switch bristolType {
        case 1...2: return .constipation
        case 3...5: return .normal
        case 6...7: return .diarrhea
        default: return .normal
        }
    }
    
    /// 是否有警示症狀
    var hasWarningSign: Bool {
        hasBlood || painLevel >= 7 || urgency >= 3
    }
    
    /// Bristol 類型的描述資訊
    var bristolInfo: BristolScale.Info {
        BristolScale.info(for: bristolType)
    }
}

// MARK: - Enums

enum BowelColor: String, Codable, CaseIterable {
    case brown = "brown"
    case darkBrown = "darkBrown"
    case yellow = "yellow"
    case green = "green"
    case black = "black"
    case red = "red"
    case clay = "clay"          // 灰白色
    
    var displayName: String {
        switch self {
        case .brown: return String(localized: "棕色")
        case .darkBrown: return String(localized: "深棕")
        case .yellow: return String(localized: "黃色")
        case .green: return String(localized: "綠色")
        case .black: return String(localized: "黑色")
        case .red: return String(localized: "紅色")
        case .clay: return String(localized: "灰白")
        }
    }
    
    var warningLevel: Int {
        switch self {
        case .brown, .darkBrown: return 0
        case .yellow, .green: return 1
        case .black, .red, .clay: return 2  // 需就醫
        }
    }
}

enum BristolRisk: String, Codable {
    case constipation
    case normal
    case diarrhea
    
    var displayName: String {
        switch self {
        case .constipation: return String(localized: "便秘傾向")
        case .normal: return String(localized: "正常")
        case .diarrhea: return String(localized: "腹瀉傾向")
        }
    }
}
