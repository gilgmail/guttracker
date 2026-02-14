# GutTracker — IBD 症狀追蹤 iOS App

Swift 原生 iOS App，專為 IBD（克隆氏症 / 潰瘍性結腸炎）患者設計。

## 功能

- 💩 **排便記錄** — Bristol Stool Scale 一鍵記錄，支援血便/黏液/急迫等標記
- 🤒 **症狀追蹤** — 腹痛/腹脹/腸鳴等 9 種症狀，severity 0-3
- 💊 **用藥管理** — 預設台灣常見 IBD 藥物，每日打卡追蹤
- 📊 **統計分析** — 排便頻率、Bristol 分布、症狀趨勢（Phase 2）
- ❤️ **HealthKit 同步** — 排便/症狀資料雙向同步到 Apple Health（Phase 4）
- 📱 **iOS Widget** — 桌面快速記錄 + 今日統計（Phase 3）

## 技術棧

- Swift 5.9+ / SwiftUI
- SwiftData（本地持久化）
- WidgetKit（互動式 Widget）
- HealthKit（健康資料整合）
- CloudKit（iCloud 同步，Phase 5）

## Xcode 設定步驟

### 1. 建立 Xcode 專案

```
Xcode → File → New → Project → iOS App
Product Name: GutTracker
Team: 你的 Apple Developer Team
Organization Identifier: com.gil
Interface: SwiftUI
Storage: SwiftData  ← 重要
```

### 2. 加入 Capabilities

在 Target → Signing & Capabilities 加入：

- **App Groups** → `group.com.gil.guttracker`
- **HealthKit** （Phase 4 時加入）

### 3. 複製程式碼

將此專案的檔案結構複製到 Xcode 專案中：

```
GutTracker/
├── App/
│   └── GutTrackerApp.swift       → 取代 Xcode 自動生成的 App 檔案
├── Models/                        → 從 Shared/Models/ 複製
│   ├── BowelMovement.swift
│   ├── SymptomEntry.swift
│   └── MedicationLog.swift
├── Views/
│   ├── MainTabView.swift
│   ├── Record/
│   │   ├── RecordView.swift
│   │   ├── SymptomQuickEntry.swift
│   │   └── BowelDetailSheet.swift
│   ├── Calendar/CalendarView.swift
│   ├── Stats/StatsView.swift
│   └── Settings/SettingsView.swift
├── Utilities/
│   ├── BristolScale.swift
│   ├── DateExtensions.swift
│   └── Constants.swift
└── Shared/
    └── SharedContainer.swift
```

### 4. 加入 Widget Extension（Phase 3）

```
File → New → Target → Widget Extension
Product Name: GutTrackerWidget
☑️ Include Configuration App Intent
```

確保 Widget Target 也加入 App Groups capability。

### 5. 執行

- 選擇 iPhone 模擬器或實機
- Build & Run (⌘R)

## 專案結構

```
Shared/Models/        ← SwiftData models（App + Widget 共用）
GutTracker/Views/     ← SwiftUI 畫面
GutTracker/Utilities/ ← 工具類（Bristol 定義、日期擴展）
GutTracker/Services/  ← HealthKit、通知等服務層（Phase 4+）
```

## 開發進度

- [x] Phase 1: MVP Core（SwiftData + 排便/症狀/用藥記錄）
- [ ] Phase 2: 日曆 + 統計圖表 + PDF 匯出
- [ ] Phase 3: Interactive Widget（Bristol 一鍵記錄）
- [ ] Phase 4: HealthKit 雙向同步
- [ ] Phase 5: CloudKit + 用藥提醒 + UI 打磨

## License

Private project — Gil's personal IBD tracker.
