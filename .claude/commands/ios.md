---
name: ios
description: "iOS app 開發快捷指令：build、run、screenshot、test"
---

# /ios - iOS 開發快捷指令

## Usage
```
/ios build          # 編譯專案
/ios run            # 編譯 + 安裝 + 啟動模擬器
/ios screenshot     # 截圖模擬器目前畫面
/ios test           # 跑 unit tests
/ios clean          # 清除 DerivedData 重新編譯
/ios log            # 查看 app console 輸出
/ios crash          # 查看最近的 crash report
/ios status         # 模擬器狀態 + app 是否運行中
```

## 參數說明
- `$ARGUMENTS` 會接收使用者輸入的子命令（如 `build`、`run`、`screenshot` 等）

## Behavioral Flow

根據 `$ARGUMENTS` 執行對應操作：

### `build` (預設，無參數時)
1. 執行 `xcodebuild -project guttracker.xcodeproj -scheme guttracker -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
2. 只顯示 BUILD SUCCEEDED/FAILED 和錯誤訊息
3. 如有錯誤，分析錯誤原因並建議修復

### `run`
1. 先執行 build
2. 如果模擬器未啟動，執行 `xcrun simctl boot "iPhone 17 Pro"` 和 `open -a Simulator`
3. 終止舊 app：`xcrun simctl terminate booted com.gilko.guttracker`
4. 安裝：`xcrun simctl install booted <DerivedData 中的 .app 路徑>`
5. 啟動：`xcrun simctl launch booted com.gilko.guttracker`
6. 等待 3 秒後自動截圖確認畫面

### `screenshot`
1. 執行 `xcrun simctl io booted screenshot /tmp/guttracker_screenshot.png`
2. 用 Read 工具顯示截圖

### `test`
1. 執行 `xcodebuild -project guttracker.xcodeproj -scheme guttracker -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test`
2. 彙整測試結果

### `clean`
1. 找到 DerivedData 路徑並刪除：`rm -rf ~/Library/Developer/Xcode/DerivedData/guttracker-*`
2. 重新執行 build

### `log`
1. 啟動 app 並用 `xcrun simctl launch --console-pty booted com.gilko.guttracker` 捕捉 console 輸出
2. 顯示最近的 log 內容

### `crash`
1. 查找最新 crash report：`ls -lt ~/Library/Logs/DiagnosticReports/ | grep guttracker`
2. 讀取並分析 crash report，找出 crash 原因和對應的程式碼位置

### `status`
1. 檢查模擬器是否啟動：`xcrun simctl list devices booted`
2. 檢查 app 是否運行中：`xcrun simctl spawn booted launchctl list | grep guttracker`
3. 顯示目前狀態摘要

## 重要配置
- **Project**: `guttracker.xcodeproj`
- **Scheme**: `guttracker`
- **Bundle ID**: `com.gilko.guttracker`
- **Simulator**: `iPhone 17 Pro`
- **SDK**: `iphonesimulator`
