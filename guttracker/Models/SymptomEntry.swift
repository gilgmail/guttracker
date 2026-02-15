import Foundation
import SwiftData

/// 症狀記錄 - IBD 腸胃 + 全身症狀
/// severity: 0=無, 1=輕, 2=中, 3=重
@Model
final class SymptomEntry {
    var id: UUID = UUID()
    var timestamp: Date = Date.now

    // ── 腸胃症狀 (0-3) ──
    var abdominalPain: Int = 0
    var bloating: Int = 0
    var gas: Int = 0
    var nausea: Int = 0
    var cramping: Int = 0
    var bowelSounds: Int = 0       // 腸鳴

    // ── 全身症狀 ──
    var fatigue: Int = 0           // 0-3
    var fever: Bool = false
    var temperature: Double?   // °C
    var jointPain: Int = 0         // 0-3

    // ── 情緒/壓力 ──
    var stressLevel: Int = 0       // 0-3
    var mood: Int = 3              // 1=很差 2=差 3=普通 4=好 5=很好
    var sleepQuality: Int = 0      // 0-3

    // ── 備註 ──
    var notes: String = ""

    // ── HealthKit 同步 ──
    var healthKitSynced: Bool = false

    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    
    init(timestamp: Date = .now) {
        self.id = UUID()
        self.timestamp = timestamp
        self.abdominalPain = 0
        self.bloating = 0
        self.gas = 0
        self.nausea = 0
        self.cramping = 0
        self.bowelSounds = 0
        self.fatigue = 0
        self.fever = false
        self.temperature = nil
        self.jointPain = 0
        self.stressLevel = 0
        self.mood = 3
        self.sleepQuality = 0
        self.notes = ""
        self.healthKitSynced = false
        self.createdAt = .now
        self.updatedAt = .now
    }
}

// MARK: - Computed Properties

extension SymptomEntry {
    /// 所有腸胃症狀的最高嚴重度
    var maxGISeverity: Int {
        max(abdominalPain, bloating, gas, nausea, cramping, bowelSounds)
    }
    
    /// 整體嚴重度
    var overallSeverity: Int {
        max(maxGISeverity, fatigue, jointPain, fever ? 2 : 0)
    }
    
    /// 有活躍症狀
    var hasActiveSymptoms: Bool {
        overallSeverity > 0
    }
    
    /// 活躍症狀清單
    var activeSymptomList: [(SymptomType, Int)] {
        var list: [(SymptomType, Int)] = []
        if abdominalPain > 0 { list.append((.abdominalPain, abdominalPain)) }
        if bloating > 0 { list.append((.bloating, bloating)) }
        if gas > 0 { list.append((.gas, gas)) }
        if nausea > 0 { list.append((.nausea, nausea)) }
        if cramping > 0 { list.append((.cramping, cramping)) }
        if bowelSounds > 0 { list.append((.bowelSounds, bowelSounds)) }
        if fatigue > 0 { list.append((.fatigue, fatigue)) }
        if jointPain > 0 { list.append((.jointPain, jointPain)) }
        if fever { list.append((.fever, 2)) }
        return list.sorted { $0.1 > $1.1 }
    }
    
    /// 整體狀態
    var overallStatus: OverallStatus {
        switch overallSeverity {
        case 0: return .good
        case 1: return .mild
        case 2: return .moderate
        case 3: return .severe
        default: return .good
        }
    }
}

// MARK: - Supporting Types

enum SymptomType: String, CaseIterable, Identifiable {
    case abdominalPain
    case bloating
    case gas
    case nausea
    case cramping
    case bowelSounds
    case fatigue
    case fever
    case jointPain

    var id: String { rawValue }

    static var commonSymptoms: [SymptomType] {
        [.abdominalPain, .bloating, .nausea, .fatigue, .cramping]
    }

    static var secondarySymptoms: [SymptomType] {
        [.gas, .bowelSounds, .fever, .jointPain]
    }
    
    var displayName: String {
        switch self {
        case .abdominalPain: return "腹痛"
        case .bloating: return "腹脹"
        case .gas: return "脹氣"
        case .nausea: return "噁心"
        case .cramping: return "絞痛"
        case .bowelSounds: return "腸鳴"
        case .fatigue: return "疲倦"
        case .fever: return "發燒"
        case .jointPain: return "關節痛"
        }
    }
    
    var emoji: String {
        switch self {
        case .abdominalPain: return "😣"
        case .bloating: return "🎈"
        case .gas: return "💨"
        case .nausea: return "🤢"
        case .cramping: return "⚡"
        case .bowelSounds: return "🔊"
        case .fatigue: return "😩"
        case .fever: return "🤒"
        case .jointPain: return "🦴"
        }
    }
    
    /// 對應的 HealthKit category type identifier
    var healthKitIdentifier: String? {
        switch self {
        case .abdominalPain: return "HKCategoryTypeIdentifierAbdominalCramps"
        case .bloating: return "HKCategoryTypeIdentifierBloating"
        case .nausea: return "HKCategoryTypeIdentifierNausea"
        case .fatigue: return "HKCategoryTypeIdentifierFatigue"
        case .fever: return "HKCategoryTypeIdentifierFever"
        case .cramping: return "HKCategoryTypeIdentifierAbdominalCramps"
        default: return nil
        }
    }
}

enum OverallStatus {
    case good, mild, moderate, severe
    
    var displayName: String {
        switch self {
        case .good: return "良好"
        case .mild: return "輕微"
        case .moderate: return "中等"
        case .severe: return "嚴重"
        }
    }
    
    var emoji: String {
        switch self {
        case .good: return "😊"
        case .mild: return "🙂"
        case .moderate: return "😐"
        case .severe: return "😰"
        }
    }
    
    var colorName: String {
        switch self {
        case .good: return "statusGood"
        case .mild: return "statusMild"
        case .moderate: return "statusModerate"
        case .severe: return "statusSevere"
        }
    }
}

let severityLabels = ["無", "輕", "中", "重"]
