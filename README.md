# GutTracker — IBD 症狀追蹤 iOS App

Swift 原生 iOS App，專為 IBD（克隆氏症 / 潰瘍性結腸炎）患者設計。

## 功能

- **排便記錄** — Bristol Stool Scale 一鍵記錄，支援血便/黏液/急迫等標記
- **症狀追蹤** — 腹痛/腹脹/腸鳴等 9 種症狀，severity 0-3 快速切換
- **用藥管理** — 預設台灣常見 IBD 藥物，每日打卡追蹤
- **統計分析** — 排便頻率、Bristol 分布、症狀趨勢
- **日曆檢視** — 月曆顏色標記嚴重度，每日詳情展開

## 技術棧

- **Swift 5.9+** / **SwiftUI** — 原生 UI 框架
- **SwiftData** — 本地持久化（iOS 26+）
- **Swift Charts** — 統計圖表
- **WidgetKit** — 互動式 Widget（規劃中）
- **HealthKit** — 健康資料雙向同步（規劃中）

無外部套件依賴，100% Apple 原生框架。

## 環境需求

| 項目 | 需求 |
|------|------|
| Xcode | 17.0+ |
| iOS | 26.0+ |
| Swift | 5.9+ |
| Apple Developer Account | 需要（App Group） |

## 快速開始

```bash
# Clone
git clone <repo-url>
cd guttracker

# 用 Xcode 開啟
open guttracker.xcodeproj

# 或 command line 編譯
xcodebuild -project guttracker.xcodeproj -scheme guttracker \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

選擇 iPhone 模擬器或實機 → Build & Run (Cmd+R)

## 專案結構

```
guttracker/
├── App/
│   └── GutTrackerApp.swift         # @main 入口
├── Models/
│   ├── BowelMovement.swift         # 排便記錄 SwiftData Model
│   ├── SymptomEntry.swift          # 症狀記錄 + SymptomType enum
│   ├── MedicationLog.swift         # 用藥紀錄 + Medication + 預設藥物
│   └── SharedContainer.swift       # App Group 共享 ModelContainer
├── Views/
│   ├── MainTabView.swift           # 4-Tab 導航
│   ├── Record/                     # 記錄頁（主畫面）
│   ├── Calendar/                   # 日曆頁
│   ├── Stats/                      # 統計頁
│   └── Settings/                   # 設定頁
├── Services/
│   └── AnalyticsEngine.swift       # 本地統計分析引擎
└── Utilities/
    ├── BristolScale.swift          # Bristol 1-7 定義 + Picker UI
    ├── Constants.swift             # App 常數
    └── DateExtensions.swift        # 日期工具
```

## 開發進度

- [x] **Phase 1**: MVP Core — SwiftData 模型 + 排便/症狀/用藥 CRUD + Tab 導航
- [ ] **Phase 2**: Swift Charts 圖表 + PDF 匯出（日曆/統計框架已完成）
- [ ] **Phase 3**: Interactive Widget（Bristol 一鍵記錄）
- [ ] **Phase 4**: HealthKit 雙向同步
- [ ] **Phase 5**: CloudKit + 用藥提醒 + UI 打磨

## 授權

Private project — Gil's personal IBD tracker.
