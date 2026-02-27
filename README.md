# GutTracker — IBD 症狀追蹤

> 專為 IBD（克隆氏症 / 潰瘍性結腸炎）患者設計的 iOS App，核心體驗：**3 秒快速記錄**。

[![Platform](https://img.shields.io/badge/platform-iOS%2026%2B-blue)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://swift.org)
[![TestFlight](https://img.shields.io/badge/TestFlight-v1.0.3-green)](https://testflight.apple.com)

---

## 功能概覽

### 核心記錄
- **Bristol Stool Scale** — 圖形化 7 型一鍵選擇，支援血便／黏液／急迫／疼痛標記
- **症狀追蹤** — 9 種 GI／全身症狀（腹痛、腹脹、脹氣、噁心、絞痛、腸鳴、疲倦、發燒、關節痛），嚴重度 0–3
- **用藥管理** — 預設 13 種台灣 IBD 常見藥物（Pentasa、Humira、Remicade 等），每日打卡

### 分析與檢視
- **統計圖表** — 排便頻率趨勢、Bristol 分布、症狀趨勢（7／30／90 天）
- **日曆檢視** — 月曆嚴重度顏色標記，每日詳情展開含 HealthKit 數據
- **每日健康評分** — 0–100 分（排便 40pts + 症狀 30pts + 用藥 20pts + Bristol 正常性 10pts）
- **PDF 匯出** — 生成醫療報告供診間使用

### 系統整合
- **HealthKit 雙向同步** — 寫入排便症狀，讀取睡眠／步數／心率
- **iCloud 同步** — CloudKit 自動備份，多裝置同步
- **用藥提醒** — 本地通知，支援自訂頻率與提醒時間
- **Siri 捷徑** — 語音快速記錄排便、症狀

### Widget（桌面快速記錄）
| 尺寸 | 功能 |
|------|------|
| Small | 今日統計（排便次數、Bristol、症狀、用藥進度）|
| Medium | 互動式 Bristol 一鍵記錄 + 用藥打勾 |
| Large | 完整今日面板（Bristol、近期紀錄列表、用藥、血便警示）|

Widget 按鈕可在設定中自訂（Bristol 型態 1–4 個、症狀 1–4 個）。

---

## 技術棧

| 層級 | 技術 |
|------|------|
| UI | SwiftUI（iOS 26 Liquid Glass TabView）|
| 資料 | SwiftData + CloudKit |
| 圖表 | Swift Charts |
| 桌面 | WidgetKit + AppIntents |
| 健康 | HealthKit |
| 語音 | App Intents / Siri |

**無外部套件依賴** — 100% Apple 原生框架。

---

## 架構

```
MVVM + SwiftData

App Group (group.com.gil.guttracker)
├── Main App
│   ├── Models/          BowelMovement, SymptomEntry, MedicationLog, Medication
│   ├── Views/           Record/, Calendar/, Stats/, Settings/
│   ├── Services/        AnalyticsEngine, HealthKitService
│   ├── Intents/         RecordBowelMovementIntent, ToggleMedicationIntent, ToggleSymptomIntent
│   └── Utilities/       BristolScale, Constants, DateExtensions
└── Widget Extension
    └── Views/           SmallWidgetView, MediumWidgetView, LargeWidgetView
```

資料流：`@Query` 響應式讀取 → `modelContext` 寫入 → `WidgetCenter.reloadTimelines()` 更新 Widget。

---

## 環境需求

| 項目 | 需求 |
|------|------|
| Xcode | 26.0+（iOS 26 SDK）|
| iOS | 26.0+ |
| Swift | 5.9+ |
| Apple Developer Account | 需要（HealthKit + WidgetKit + App Group）|

---

## 快速開始

```bash
git clone https://github.com/gilgmail/guttracker.git
cd guttracker
open guttracker.xcodeproj
```

```bash
# 模擬器編譯
xcodebuild -project guttracker.xcodeproj -scheme guttracker \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# 部署到實機（WiFi 或 USB）
./scripts/deploy.sh

# TestFlight 上傳
./scripts/testflight.sh
```

---

## 開發進度

- [x] **Phase 1** — SwiftData 模型、Bristol Picker、排便／症狀／用藥 CRUD、Tab 導航、AnalyticsEngine
- [x] **Phase 2** — 日曆頁、統計 Charts、PDF 匯出
- [x] **Phase 3** — WidgetKit 互動 Widget（Small／Medium／Large、AppIntents）
- [x] **Phase 4** — HealthKit 雙向同步（寫入症狀、讀取睡眠／步數／心率）
- [x] **Phase 5** — CloudKit、用藥提醒、每日健康評分通知、藥物編輯、UI 動畫
- [x] **UI Polish** — 主題色系（米色／深色）、Widget 自訂按鈕、Siri 捷徑
- [x] **TestFlight** — v1.0.3 已上傳

---

## 授權

Private project — Gil's personal IBD tracker for Taiwan market.
