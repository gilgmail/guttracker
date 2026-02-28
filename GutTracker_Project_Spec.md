# GutTracker — IBD 症狀追蹤 iOS App 專案規格書

**版本**: v1.0 MVP
**日期**: 2026-02-14
**目標用戶**: IBD（克隆氏症 / 潰瘍性結腸炎）患者
**技術棧**: Swift 5.9+ / SwiftUI / SwiftData / HealthKit / WidgetKit
**Note**: LINE Bot 已移除，Widget 作為核心快速互動入口

---

## 1. 產品定位

### 核心價值
一個專為 IBD 患者設計的**排便與症狀追蹤** App，以 3 秒快速記錄為核心體驗，搭配 HealthKit 雙向同步與 LINE Bot 隨時記錄。

### 競品分析

| App | 優勢 | 缺點 | 我們的差異 |
|-----|------|------|-----------|
| CareClinic Poop Tracker | 功能齊全 | 訂閱制 $40-60/年、介面臃腫 | 免費、極簡 UI |
| Bowelle | IBS 專用、Apple Health 支援 | 無 IBD 特化、無中文 | IBD 專屬 + 台灣在地化 |
| myIBD Care | IBD 專用、醫療問卷 | 無 HealthKit 整合 | HealthKit 深度整合 |
| OUTPUTS | 極簡排便追蹤 | 功能太少 | 完整症狀 + 用藥 + AI 分析 |

### 差異化策略
1. **3 秒記錄** — 一鍵 Bristol 圖形選擇，不需文字輸入
2. **HealthKit 原生** — 寫入/讀取症狀資料，與 Apple Health 完全整合
3. **iOS Widget** — 桌面快速記錄 + 今日統計
4. **LINE Bot** — 用聊天就能記錄，適合不想開 App 的場景
5. **台灣在地化** — 繁體中文、台灣 IBD 用藥資料庫

---

## 2. 系統架構

```
┌─────────────────────────────────────────────────┐
│                  iOS App (SwiftUI)               │
│                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ 排便記錄  │  │ 症狀追蹤  │  │  用藥紀錄    │   │
│  └─────┬────┘  └─────┬────┘  └──────┬───────┘   │
│        │             │              │             │
│  ┌─────┴─────────────┴──────────────┴──────┐     │
│  │          SwiftData (本地儲存)             │     │
│  └─────────────────┬───────────────────────┘     │
│                    │                              │
│  ┌────────────────┐│┌─────────────────────┐      │
│  │  HealthKit     ││ │  WidgetKit          │      │
│  │  (雙向同步)    │││  (桌面 Widget)       │      │
│  └────────────────┘│└─────────────────────┘      │
│                    │                              │
│  ┌─────────────────┴──────────────────────┐      │
│  │       CloudKit (iCloud 同步)            │      │
│  └─────────────────────────────────────────┘      │
└─────────────────────────────────────────────────┘
                     │
                     │ HTTPS API
                     ▼
┌─────────────────────────────────────────────────┐
│              Backend (輕量 Server)                │
│                                                   │
│  ┌──────────────┐    ┌──────────────────┐        │
│  │ LINE Bot      │    │  Push Notification │        │
│  │ Webhook       │    │  Service (APNs)    │        │
│  └──────────────┘    └──────────────────┘        │
└─────────────────────────────────────────────────┘
```

### 技術選擇理由

| 選項 | 選擇 | 理由 |
|------|------|------|
| UI Framework | SwiftUI | 原生效能、Widget 共用、iOS 17+ |
| 資料層 | SwiftData | Apple 原生 ORM、CloudKit 整合簡單 |
| 雲端同步 | CloudKit | 免費、免後端、隱私合規 |
| 後端 | Cloudflare Workers | LINE Bot webhook 用、極低成本 |
| 分析引擎 | 本地計算 | 排便/症狀關聯分析不需 AI API |

---

## 3. 資料模型 (SwiftData)

### 3.1 BowelMovement（排便記錄）

```swift
@Model
final class BowelMovement {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    
    // Bristol Stool Scale (1-7)
    var bristolType: Int = 4
    
    // 特徵標記
    var hasBlood: Bool = false
    var hasMucus: Bool = false
    var urgency: Int = 0          // 0=無, 1=輕微, 2=中等, 3=緊急
    var completeness: Int = 2     // 0=不完全, 1=部分, 2=完全
    var straining: Int = 0        // 0=無, 1=輕微, 2=中等, 3=嚴重
    var painLevel: Int = 0        // 0-10
    var durationMinutes: Int = 0
    
    // 量 (相對)
    var volume: Int = 2           // 1=少, 2=正常, 3=多
    
    // 顏色
    var color: String = "brown"   // brown, darkBrown, yellow, green, black, red
    
    // 備註
    var notes: String = ""
    
    // HealthKit 同步
    var healthKitSynced: Bool = false
    var healthKitUUID: String?
    
    // 時間戳
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
```

### 3.2 SymptomEntry（症狀記錄）

```swift
@Model
final class SymptomEntry {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    
    // 腸胃症狀 (severity 0-3: 無/輕/中/重)
    var abdominalPain: Int = 0
    var bloating: Int = 0
    var gas: Int = 0
    var nausea: Int = 0
    var cramping: Int = 0
    var bowelSounds: Int = 0      // 腸鳴
    
    // 全身症狀
    var fatigue: Int = 0
    var fever: Bool = false
    var temperature: Double?       // 體溫 °C
    var jointPain: Int = 0
    
    // 情緒/壓力
    var stressLevel: Int = 0      // 0-3
    var mood: Int = 2             // 1=很差, 2=差, 3=普通, 4=好, 5=很好
    var sleepQuality: Int = 0     // 0-3
    
    // 備註
    var notes: String = ""
    
    // HealthKit 同步
    var healthKitSynced: Bool = false
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
```

### 3.3 MedicationLog（用藥紀錄）

```swift
@Model
final class MedicationLog {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    
    var medicationName: String = ""
    var category: String = ""      // aminosalicylate, immunomodulator, biologic, steroid, other
    var dosage: String = ""        // "400mg"
    var unit: String = "mg"
    var taken: Bool = true
    var skippedReason: String?
    
    var notes: String = ""
    var createdAt: Date = Date()
}
```

### 3.4 Medication（藥物資料庫）

```swift
@Model
final class Medication {
    var id: UUID = UUID()
    var name: String = ""
    var nameEN: String = ""
    var category: String = ""
    var defaultDosage: String = ""
    var frequency: String = ""     // "daily", "twice_daily", "weekly", "biweekly"
    var isActive: Bool = true
    
    // 提醒
    var reminderEnabled: Bool = false
    var reminderTimes: [Date] = []
}
```

### 3.5 台灣常見 IBD 藥物預設資料

```swift
let defaultMedications: [(name: String, nameEN: String, category: String, dosage: String, freq: String)] = [
    // 5-ASA 類
    ("美沙拉明", "Mesalamine/Pentasa", "aminosalicylate", "500mg", "twice_daily"),
    ("柳氮磺胺吡啶", "Sulfasalazine", "aminosalicylate", "500mg", "twice_daily"),
    ("美沙拉嗪", "Mesalazine/Asacol", "aminosalicylate", "400mg", "three_daily"),
    
    // 免疫調節劑
    ("硫唑嘌呤", "Azathioprine/Imuran", "immunomodulator", "50mg", "daily"),
    ("6-巰嘌呤", "6-Mercaptopurine", "immunomodulator", "50mg", "daily"),
    ("甲氨蝶呤", "Methotrexate", "immunomodulator", "25mg", "weekly"),
    
    // 生物製劑
    ("英夫利昔單抗", "Infliximab/Remicade", "biologic", "5mg/kg", "biweekly"),
    ("阿達木單抗", "Adalimumab/Humira", "biologic", "40mg", "biweekly"),
    ("維多珠單抗", "Vedolizumab/Entyvio", "biologic", "300mg", "monthly"),
    ("烏司奴單抗", "Ustekinumab/Stelara", "biologic", "90mg", "bimonthly"),
    
    // 類固醇
    ("潑尼松龍", "Prednisolone", "steroid", "5mg", "daily"),
    ("布地奈德", "Budesonide/Entocort", "steroid", "3mg", "three_daily"),
    
    // 其他
    ("益生菌", "Probiotics", "supplement", "1顆", "daily"),
    ("鐵劑", "Iron supplement", "supplement", "1顆", "daily"),
]
```

---

## 4. HealthKit 整合設計

### 4.1 可同步的 HealthKit 資料型別

```swift
// ── 寫入 HealthKit（App → Health）──
let writeTypes: Set<HKSampleType> = [
    // 症狀 (HKCategoryType)
    HKCategoryType(.abdominalCramps),
    HKCategoryType(.bloating),
    HKCategoryType(.constipation),
    HKCategoryType(.diarrhea),
    HKCategoryType(.nausea),
    HKCategoryType(.vomiting),
    HKCategoryType(.fatigue),
    HKCategoryType(.fever),
    
    // 排便相關 (沒有直接 Bristol type，用 metadata 標記)
    // Apple Health 不直接支援排便記錄
    // 方案：寫入 diarrhea / constipation 搭配 metadata
]

// ── 讀取 HealthKit（Health → App）──
let readTypes: Set<HKObjectType> = [
    // 活動
    HKQuantityType(.stepCount),
    HKQuantityType(.activeEnergyBurned),
    
    // 睡眠
    HKCategoryType(.sleepAnalysis),
    
    // 心率
    HKQuantityType(.heartRate),
    HKQuantityType(.restingHeartRate),
    
    // 體重
    HKQuantityType(.bodyMass),
    
    // 其他 App 寫入的症狀
    HKCategoryType(.abdominalCramps),
    HKCategoryType(.bloating),
    HKCategoryType(.diarrhea),
    HKCategoryType(.constipation),
]
```

### 4.2 HealthKit 同步 Service

```swift
import HealthKit

actor HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()
    
    // MARK: - 授權
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        try await store.requestAuthorization(
            toShare: Self.writeTypes,
            read: Self.readTypes
        )
    }
    
    // MARK: - 寫入症狀到 HealthKit
    func syncSymptom(
        type: HKCategoryTypeIdentifier,
        severity: HKCategoryValueSeverity,
        start: Date,
        end: Date? = nil
    ) async throws {
        let categoryType = HKCategoryType(type)
        let sample = HKCategorySample(
            type: categoryType,
            value: severity.rawValue,
            start: start,
            end: end ?? start.addingTimeInterval(60),
            metadata: [
                HKMetadataKeyWasUserEntered: true,
                "AppSource": "GutTracker"
            ]
        )
        try await store.save(sample)
    }
    
    // MARK: - 排便記錄 → HealthKit
    func syncBowelMovement(_ bm: BowelMovement) async throws {
        // Bristol 1-2 → constipation
        if bm.bristolType <= 2 {
            try await syncSymptom(
                type: .constipation,
                severity: bm.bristolType == 1 ? .severe : .moderate,
                start: bm.timestamp
            )
        }
        // Bristol 6-7 → diarrhea
        else if bm.bristolType >= 6 {
            try await syncSymptom(
                type: .diarrhea,
                severity: bm.bristolType == 7 ? .severe : .moderate,
                start: bm.timestamp
            )
        }
        
        // 腹痛
        if bm.painLevel > 3 {
            let severity: HKCategoryValueSeverity = bm.painLevel > 7 ? .severe :
                                                    bm.painLevel > 5 ? .moderate : .mild
            try await syncSymptom(
                type: .abdominalCramps,
                severity: severity,
                start: bm.timestamp
            )
        }
    }
    
    // MARK: - 讀取睡眠資料
    func fetchSleepData(for date: Date) async throws -> (hours: Double, quality: Int) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay.addingTimeInterval(-43200), // 前一天中午開始
            end: endOfDay,
            options: .strictStartDate
        )
        
        let sleepType = HKCategoryType(.sleepAnalysis)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        
        let samples = try await descriptor.result(for: store)
        // 計算 asleep 時段加總
        let asleepMinutes = samples
            .filter { $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                      $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                      $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
            .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 60.0 }
        
        let hours = asleepMinutes / 60.0
        let quality = hours >= 7 ? 3 : hours >= 6 ? 2 : hours >= 5 ? 1 : 0
        return (hours, quality)
    }
    
    // MARK: - 讀取步數
    func fetchSteps(for date: Date) async throws -> Int {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)
        
        let stepType = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay, end: endOfDay
        )
        
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum
        )
        
        let result = try await descriptor.result(for: store)
        return Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
    }
}
```

---

## 5. iOS Widget 設計 (WidgetKit)

### 5.1 Widget 類型

**Small Widget (2x2)**:
```
┌─────────────────┐
│  今日排便 3 次    │
│  ●●●○○          │
│  Bristol avg: 5  │
│  ⚠️ 血便 1次     │
└─────────────────┘
```

**Medium Widget (4x2)**:
```
┌──────────────────────────────────┐
│  💩 今日排便 3次    😊 症狀: 輕微  │
│  Bristol: ●④ ●⑤ ●⑥             │
│  ───────────────────────────     │
│  💊 Pentasa ✅  Imuran ✅        │
│  🔥 連續記錄 12 天               │
└──────────────────────────────────┘
```

### 5.2 Widget 互動（iOS 17+）

```swift
struct QuickLogIntent: AppIntent {
    static var title: LocalizedStringResource = "快速記錄排便"
    
    @Parameter(title: "Bristol Type")
    var bristolType: Int
    
    func perform() async throws -> some IntentResult {
        let bm = BowelMovement()
        bm.bristolType = bristolType
        bm.timestamp = Date()
        // 儲存到 SwiftData (App Group shared container)
        try ModelContext(sharedModelContainer).insert(bm)
        return .result()
    }
}

struct GutTrackerWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "GutTrackerWidget",
            intent: QuickLogIntent.self,
            provider: GutTrackerTimelineProvider()
        ) { entry in
            GutTrackerWidgetView(entry: entry)
        }
        .configurationDisplayName("腸胃追蹤")
        .description("快速記錄排便與查看今日統計")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

---

## 6. Widget 深度設計 (WidgetKit — 核心互動入口)

Widget 是用戶每天使用頻率最高的介面，設計原則：**一看就懂、一點就記**。

### 6.1 三種 Widget 尺寸

**Small (2×2) — 純顯示**
```
┌──────────────────┐
│ GutTracker       │
│                  │
│   💩 3次         │
│   Bristol ④⑤⑤   │
│                  │
│ 😊 症狀良好      │
│ 💊 2/3          │
└──────────────────┘
```

**Medium (4×2) — 顯示 + Bristol 快速記錄**
```
┌──────────────────────────────────┐
│ GutTracker         😊 良好       │
│                                  │
│ 💩 3次  avg④  │ 💊 Pentasa ✅   │
│ ①②③④⑤⑥⑦      │    Imuran  ⬜   │
│ [點擊記錄]     │    益生菌  ✅   │
│                                  │
│ 😣腹痛(輕)  🎈腹脹(無)          │
└──────────────────────────────────┘
```

**Large (4×4) — 完整今日面板**
```
┌──────────────────────────────────┐
│ GutTracker    2/14 五    😊 良好  │
│──────────────────────────────────│
│                                  │
│ 💩 排便 3次    Bristol avg: 4.3  │
│ ①②③[④]⑤⑥⑦  ← 點擊即記錄       │
│                                  │
│ 14:32 Type⑤ 正常                │
│ 12:15 Type④ 正常                │
│ 08:40 Type④ 正常                │
│──────────────────────────────────│
│ 🤒 症狀: 😣腹痛(輕)             │
│──────────────────────────────────│
│ 💊 Pentasa ✅ Imuran ⬜ 益生菌✅ │
└──────────────────────────────────┘
```

### 6.2 Interactive Widget 實作 (iOS 17+)

```swift
// ── App Intent：Bristol 一鍵記錄 ──
struct RecordBowelMovementIntent: AppIntent {
    static var title: LocalizedStringResource = "記錄排便"
    static var description = IntentDescription("快速記錄排便 Bristol 類型")
    
    @Parameter(title: "Bristol Type", default: 4)
    var bristolType: Int
    
    func perform() async throws -> some IntentResult {
        // 寫入 App Group 共享的 SwiftData container
        let container = try ModelContainer(
            for: BowelMovement.self,
            configurations: .init(
                groupContainer: .identifier("group.com.gil.guttracker")
            )
        )
        let context = ModelContext(container)
        
        let record = BowelMovement()
        record.bristolType = bristolType
        record.timestamp = Date()
        context.insert(record)
        try context.save()
        
        // 同步到 HealthKit
        if bristolType <= 2 || bristolType >= 6 {
            try? await HealthKitService.shared.syncBowelMovement(record)
        }
        
        return .result()
    }
}

// ── App Intent：用藥打勾 ──
struct ToggleMedicationIntent: AppIntent {
    static var title: LocalizedStringResource = "記錄用藥"
    
    @Parameter(title: "Medication ID")
    var medicationId: String
    
    func perform() async throws -> some IntentResult {
        let container = try ModelContainer(
            for: MedicationLog.self,
            configurations: .init(
                groupContainer: .identifier("group.com.gil.guttracker")
            )
        )
        let context = ModelContext(container)
        
        let log = MedicationLog()
        log.medicationName = medicationId
        log.timestamp = Date()
        log.taken = true
        context.insert(log)
        try context.save()
        
        return .result()
    }
}
```

### 6.3 Widget Timeline Provider

```swift
struct GutTrackerTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = GutTrackerEntry
    typealias Intent = ConfigurationAppIntent
    
    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let container = try! ModelContainer(
            for: BowelMovement.self, SymptomEntry.self, MedicationLog.self,
            configurations: .init(
                groupContainer: .identifier("group.com.gil.guttracker")
            )
        )
        let modelContext = ModelContext(container)
        
        let today = Calendar.current.startOfDay(for: Date())
        
        // Fetch today's bowel movements
        let bmDescriptor = FetchDescriptor<BowelMovement>(
            predicate: #Predicate { $0.timestamp >= today },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let bowelMovements = (try? modelContext.fetch(bmDescriptor)) ?? []
        
        // Fetch today's symptoms
        let symDescriptor = FetchDescriptor<SymptomEntry>(
            predicate: #Predicate { $0.timestamp >= today },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let symptoms = (try? modelContext.fetch(symDescriptor)) ?? []
        
        // Fetch today's medication logs
        let medDescriptor = FetchDescriptor<MedicationLog>(
            predicate: #Predicate { $0.timestamp >= today }
        )
        let medLogs = (try? modelContext.fetch(medDescriptor)) ?? []
        
        let entry = GutTrackerEntry(
            date: Date(),
            bowelMovements: bowelMovements,
            symptoms: symptoms.first,
            medicationsTaken: medLogs.map { $0.medicationName },
            totalMedications: 3 // from user settings
        )
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}
```

### 6.4 Widget View（Medium 尺寸）

```swift
struct GutTrackerMediumView: View {
    let entry: GutTrackerEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // 左半：排便記錄
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("💩").font(.caption)
                    Text("\(entry.bowelMovements.count)次")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Spacer()
                    Text("avg \(entry.avgBristol, specifier: "%.1f")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // Bristol 一鍵記錄按鈕
                HStack(spacing: 3) {
                    ForEach(1...7, id: \.self) { type in
                        Button(intent: RecordBowelMovementIntent(bristolType: type)) {
                            Text(bristolEmoji(type))
                                .font(.system(size: 14))
                                .frame(width: 28, height: 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // 最近記錄
                if let last = entry.bowelMovements.first {
                    Text("\(last.timestamp.formatted(.dateTime.hour().minute())) Type\(last.bristolType)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            // 右半：用藥
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("💊").font(.caption)
                    Text("\(entry.medicationsTaken.count)/\(entry.totalMedications)")
                        .font(.system(size: 14, weight: .semibold))
                }
                
                // 用藥清單（簡化）
                ForEach(["Pentasa", "Imuran", "益生菌"], id: \.self) { med in
                    let taken = entry.medicationsTaken.contains(med)
                    HStack(spacing: 4) {
                        Image(systemName: taken ? "checkmark.circle.fill" : "circle")
                            .font(.caption2)
                            .foregroundStyle(taken ? .green : .secondary)
                        Text(med)
                            .font(.caption2)
                            .foregroundStyle(taken ? .secondary : .primary)
                    }
                }
            }
        }
        .padding(14)
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}
```

---

## 7. App 畫面設計

### 7.1 Tab 結構

```
┌────────────────────────────────┐
│  [記錄]  [日曆]  [統計]  [設定]  │
└────────────────────────────────┘
```

### 7.2 記錄頁（主畫面）

```
┌──────────────────────────────┐
│  2月14日 星期五     ☀️ 26°C   │
│                              │
│  ┌────────────────────────┐  │
│  │  💩 排便記錄            │  │
│  │                        │  │
│  │  Bristol Scale:         │  │
│  │  ① ② ③ [④] ⑤ ⑥ ⑦     │  │
│  │                        │  │
│  │  ☐ 血便  ☐ 黏液  ☐ 急迫 │  │
│  │  疼痛: ○○○○●○○○○○      │  │
│  │                        │  │
│  │  [記錄排便]             │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │  🤒 症狀快速記錄         │  │
│  │                        │  │
│  │  [腹痛] [腹脹] [腸鳴]    │  │
│  │  [噁心] [疲倦] [發燒]    │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │  💊 今日用藥             │  │
│  │                        │  │
│  │  Pentasa 500mg    [✅]   │  │
│  │  Imuran 50mg      [⬜]   │  │
│  └────────────────────────┘  │
│                              │
│  今日: 排便 2次 | 症狀 輕微   │
└──────────────────────────────┘
```

### 7.3 日曆頁

每日以顏色標記嚴重度，點擊展開當日詳情。

```
┌──────────────────────────────┐
│      2026年2月               │
│  一 二 三 四 五 六 日         │
│  🟢 🟢 🟡 🟢 🟢 🔴 🟡        │
│  🟢 🟢 🟢 🟡 [🟢] ·  ·       │
│                              │
│  2/14 詳情:                  │
│  💩 3次 (Bristol 4,5,5)      │
│  🤒 腹脹(輕), 腸鳴(輕)       │
│  💊 Pentasa ✅ Imuran ✅      │
│  😴 睡眠 7.2h | 🚶 4,521步  │
└──────────────────────────────┘
```

### 7.4 統計頁

```
┌──────────────────────────────┐
│  📊 週統計  [7天][30天][90天]  │
│                              │
│  排便頻率趨勢                 │
│  ▁▃▅▇▅▃▁▃▅▇                 │
│  平均 2.8次/天               │
│                              │
│  Bristol 分布                │
│  Type 4: ████████░░ 40%      │
│  Type 5: ██████░░░░ 30%      │
│  Type 6: ████░░░░░░ 20%      │
│  Type 3: ██░░░░░░░░ 10%      │
│                              │
│  血便記錄: 2次 (本週)         │
│  平均疼痛: 2.3/10            │
│                              │
│  症狀趨勢                    │
│  ▁▁▃▅▃▁▁ (改善中 ✅)         │
│                              │
│  [匯出 PDF 報告]             │
└──────────────────────────────┘
```

---

## 8. Xcode 專案結構

```
GutTracker/
├── GutTracker.xcodeproj
├── GutTracker/
│   ├── App/
│   │   ├── GutTrackerApp.swift          # @main entry
│   │   └── AppState.swift               # 全域狀態管理
│   │
│   ├── Models/
│   │   ├── BowelMovement.swift          # SwiftData model
│   │   ├── SymptomEntry.swift
│   │   ├── MedicationLog.swift
│   │   ├── Medication.swift
│   │   └── DailySummary.swift           # 每日彙總 (computed)
│   │
│   ├── Views/
│   │   ├── MainTabView.swift
│   │   ├── Record/
│   │   │   ├── RecordView.swift         # 主記錄頁
│   │   │   ├── BristolScalePicker.swift # Bristol 圖形選擇器
│   │   │   ├── SymptomQuickEntry.swift  # 症狀快速輸入
│   │   │   └── MedicationCheckList.swift
│   │   ├── Calendar/
│   │   │   ├── CalendarView.swift
│   │   │   └── DayDetailView.swift
│   │   ├── Stats/
│   │   │   ├── StatsView.swift
│   │   │   ├── BowelFrequencyChart.swift
│   │   │   ├── BristolDistributionChart.swift
│   │   │   └── SymptomTrendChart.swift
│   │   └── Settings/
│   │       ├── SettingsView.swift
│   │       ├── MedicationSetup.swift
│   │       ├── HealthKitSettings.swift
│   │       ├── LINEBotSetup.swift
│   │       └── ExportView.swift
│   │
│   ├── Services/
│   │   ├── HealthKitService.swift       # HealthKit 雙向同步
│   │   ├── NotificationService.swift    # 用藥提醒
│   │   ├── ExportService.swift          # PDF 匯出
│   │   └── AnalyticsEngine.swift        # 本地統計分析
│   │
│   ├── Utilities/
│   │   ├── BristolScale.swift           # Bristol 7 型別定義
│   │   ├── DateExtensions.swift
│   │   ├── ColorTheme.swift
│   │   └── Constants.swift
│   │
│   └── Resources/
│       ├── Assets.xcassets
│       ├── BristolImages/               # Bristol 1-7 圖示
│       └── Localizable.strings          # 繁體中文
│
├── GutTrackerWidget/
│   ├── GutTrackerWidget.swift           # Widget bundle
│   ├── Views/
│   │   ├── SmallWidgetView.swift        # 純顯示（排便次數+狀態）
│   │   ├── MediumWidgetView.swift       # Bristol 一鍵記錄 + 用藥
│   │   └── LargeWidgetView.swift        # 完整今日面板
│   ├── TimelineProvider.swift           # 資料提供者
│   ├── Intents/
│   │   ├── RecordBowelMovementIntent.swift  # Bristol 記錄 Intent
│   │   └── ToggleMedicationIntent.swift     # 用藥打勾 Intent
│   └── Assets.xcassets
│
├── Shared/                              # App Group 共享
│   ├── Models/                          # SwiftData models (共用)
│   └── SharedContainer.swift            # App Group container config
│
├── GutTrackerTests/
│   ├── BowelMovementTests.swift
│   ├── HealthKitServiceTests.swift
│   └── AnalyticsEngineTests.swift
│
└── GutTrackerTests/
    ├── BowelMovementTests.swift
    ├── HealthKitServiceTests.swift
    └── AnalyticsEngineTests.swift
```

---

## 9. 開發排程（6 週）

### Phase 1: MVP Core（Week 1-2）✅ 完成
- [x] Xcode 專案建立 + App Group 配置
- [x] SwiftData Models（BowelMovement, SymptomEntry, MedicationLog, Medication）
- [x] Bristol Scale Picker UI（圖形化 7 型選擇）
- [x] 排便記錄 CRUD + 詳細欄位（血便/黏液/急迫/疼痛）
- [x] 症狀快速記錄 UI（一鍵 severity 選擇）
- [x] 用藥 Checklist + 預設台灣 IBD 藥物
- [x] 主 Tab 導航（記錄/日曆/統計/設定）
- [x] AnalyticsEngine 本地統計分析引擎
- [x] SharedContainer App Group fallback（模擬器相容）

### Phase 2: 數據 & 分析（Week 3）✅ 完成
- [x] 日曆頁（顏色標記嚴重度 + 每日詳情展開）
- [x] 統計頁框架（StatsView）
- [x] Swift Charts 圖表（排便頻率趨勢圖、Bristol 分布圖、症狀趨勢圖）
- [x] PDF 報告匯出（給醫生用）

### Phase 3: Widget（Week 4 — 高優先）✅ 完成
- [x] App Group 共享 SwiftData container
- [x] Small Widget（今日統計純顯示）
- [x] Medium Widget（Bristol 一鍵記錄 + 用藥狀態）
- [x] Large Widget（完整今日面板 + 記錄列表）
- [x] RecordBowelMovementIntent（Interactive Widget）
- [x] ToggleMedicationIntent（用藥打勾 Intent）
- [x] Widget Timeline 15 分鐘自動更新

### Phase 4: HealthKit（Week 5）✅ 完成
- [x] HealthKit 授權流程 UI
- [x] 排便 → HealthKit 症狀同步（Bristol→diarrhea/constipation）
- [x] 症狀 → HealthKit 同步（abdominalCramps, bloating, nausea...）
- [x] 讀取睡眠/步數/心率資料
- [x] 在日詳情中顯示 Health 資料

### Phase 5: 完善（Week 6）✅ 完成
- [x] CloudKit 同步（iCloud 備份）
- [x] 用藥提醒通知（Local Notification）
- [x] 每日健康評分通知（0-100 分，含排便/症狀/用藥分析）
- [x] 藥物編輯頁面（頻率、提醒時間設定）
- [x] UI 動畫打磨（入場動畫、確認動畫、圖表過場）
- [x] 即時健康評分顯示於導覽列
- [x] 健康評分優化（趨勢比較、症狀負擔加總、Bristol 獎勵制、睡眠/情緒因子）
- [ ] App Icon 設計
- [ ] TestFlight 測試

### 健康評分演算法（v2）

每日健康評分 0-100，基於排便、症狀、用藥、Bristol 正常度四維度，從滿分 100 扣減。

#### 1. 排便評分（梯度頻率 + 異常 + 血便 + 疼痛）

| 條件 | 扣分 |
|------|------|
| 0 次排便 | -15 |
| 4-5 次排便 | -8 |
| ≥6 次排便 | -20 |
| 每筆異常 Bristol（≤2 或 ≥6） | -8/筆 |
| 有血便 | -15 |
| 平均疼痛 >3（0-10 量表） | -min(avgPain×2, 15) |

#### 2. 症狀評分（峰值 + 負擔 + 高危 + 趨勢 + 睡眠/情緒）

| 條件 | 加/扣分 |
|------|---------|
| 最高嚴重度（overallSeverity × 5） | 最多 -15 |
| 整體負擔（symptomBurden / 3） | 最多 -5 |
| 發燒 | -5 |
| 症狀改善（vs 前日） | +5 |
| 症狀惡化（vs 前日） | -5 |
| 睡眠品質差（≥2） | -3 |
| 情緒良好（≥4） | +2 |
| 症狀未記錄（有排便記錄時） | -5 |

- `overallSeverity`：所有症狀嚴重度的最大值（0-3）
- `symptomBurden`：所有症狀嚴重度加總（捕捉多重輕微症狀負擔）

#### 3. 用藥完成度

| 條件 | 扣分 |
|------|------|
| 完成度 < 100% | -(1-完成度) × 20，最多 -20 |
| 完全未服藥 | 顯示「未服藥」提示 |

#### 4. Bristol 正常度（獎勵制）

| 條件 | 加分 |
|------|------|
| 全部排便皆 Type 3-5 | +5 |

> 改為獎勵制以避免與 Section 1 異常 Bristol 扣分重複計算。

#### 評分等級

| 分數 | 等級 | 顯示 |
|------|------|------|
| 80-100 | 非常好 | 🌟 |
| 60-79 | 良好 | 😊 |
| 40-59 | 一般 | 😐 |
| 0-39 | 需注意 | ⚠️ |

---

## 10. 環境需求

| 項目 | 需求 |
|------|------|
| Xcode | 17.0+（iOS 26 SDK）|
| iOS Target | 26.0+（Liquid Glass TabView API）|
| Swift | 5.9+ |
| Apple Developer Account | 需要（HealthKit + WidgetKit + App Group） |

---

## 11. 與原 diet_dialy 的關係

| 面向 | diet_dialy (Web) | GutTracker (iOS) |
|------|-------------------|------------------|
| 定位 | 全功能飲食日誌 + AI 分析 | 輕量排便/症狀追蹤 |
| 技術棧 | Next.js + Supabase | Swift + SwiftData |
| 資料源 | Supabase PostgreSQL | 本地 SwiftData + CloudKit |
| 共通點 | 可共用 Supabase 食物資料庫 | 未來可透過 API 串接 |
| 優先級 | 維護模式 | 主力開發 |

**建議**: GutTracker 作為獨立專案先行開發，MVP 完成後再評估是否要和 diet_dialy 整合。
