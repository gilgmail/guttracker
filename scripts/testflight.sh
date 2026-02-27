#!/bin/bash
# GutTracker — Archive + 上傳 TestFlight
#
# 前置作業：
#   1. App Store Connect 建立 App 記錄 (bundle ID: com.gilko.guttracker)
#   2. API Key .p8 檔案放在 ~/.private_keys/
#
# 用法：
#   bash scripts/testflight.sh              # Archive + 上傳
#   bash scripts/testflight.sh --clean      # 清除後重新 archive
#   bash scripts/testflight.sh --archive-only  # 只 archive 不上傳

set -euo pipefail

# ── 配置 ──
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="guttracker"
TEAM_ID="686AGNJMGN"
BUNDLE_ID="com.gilko.guttracker"
API_KEY_ID="JXC6QNX5FQ"
API_ISSUER_ID="6be6ba42-685b-4f49-80b3-10109ba35ede"
API_KEY_PATH="$HOME/.private_keys/AuthKey_${API_KEY_ID}.p8"
ARCHIVE_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$ARCHIVE_DIR/guttracker.xcarchive"
EXPORT_PATH="$ARCHIVE_DIR/export"
LOG_DIR="$PROJECT_DIR/scripts/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_LOG="$LOG_DIR/archive_${TIMESTAMP}.log"

# ── 顏色 ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

mkdir -p "$LOG_DIR" "$ARCHIVE_DIR"

# ── 參數 ──
CLEAN=false
ARCHIVE_ONLY=false
for arg in "$@"; do
    case $arg in
        --clean) CLEAN=true ;;
        --archive-only) ARCHIVE_ONLY=true ;;
        --help|-h)
            echo "Usage: $0 [--clean] [--archive-only]"
            echo "  --clean         清除 DerivedData 後重新 archive"
            echo "  --archive-only  只 archive 不上傳 TestFlight"
            exit 0
            ;;
    esac
done

cd "$PROJECT_DIR"

# ── 讀取版本號 ──
VERSION=$(grep -m1 'MARKETING_VERSION' guttracker.xcodeproj/project.pbxproj | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' || echo "unknown")
BUILD_NUM=$(grep -m1 'CURRENT_PROJECT_VERSION' guttracker.xcodeproj/project.pbxproj | grep -oE '[0-9]+' || echo "1")

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  GutTracker → TestFlight${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Version: ${CYAN}${VERSION} (${BUILD_NUM})${NC}"
echo -e "  Team:    ${CYAN}${TEAM_ID}${NC}"
echo -e "  Time:    ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# ── Clean（可選）──
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}[清除]${NC} 刪除 DerivedData + 舊 archive..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/guttracker-*
    rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
    echo -e "${GREEN}[清除]${NC} 完成"
    echo ""
fi

# ── Archive ──
echo -e "${CYAN}[Archive]${NC} 開始 archive..."
rm -rf "$ARCHIVE_PATH"

BUILD_START=$(date +%s)

xcodebuild \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    archive \
    2>&1 | tee "$ARCHIVE_LOG" | while IFS= read -r line; do
    if echo "$line" | grep -q "CompileSwift normal"; then
        file=$(echo "$line" | grep -oE '[^ ]+\.swift' | head -1 | xargs basename 2>/dev/null || true)
        if [ -n "$file" ]; then
            printf "\r  ${CYAN}⚙${NC}  %-45s" "$file"
        fi
    fi
    if echo "$line" | grep -q "ARCHIVE SUCCEEDED\|BUILD FAILED\|ARCHIVE FAILED"; then
        echo ""
    fi
done

BUILD_END=$(date +%s)
DURATION=$((BUILD_END - BUILD_START))

if grep -q "ARCHIVE SUCCEEDED" "$ARCHIVE_LOG"; then
    echo -e "${GREEN}${BOLD}━━━ ARCHIVE SUCCEEDED ━━━${NC}  (${DURATION}s)"
else
    echo -e "${RED}${BOLD}━━━ ARCHIVE FAILED ━━━${NC}  (${DURATION}s)"
    echo ""
    grep "error:" "$ARCHIVE_LOG" | grep -oE '[^/]+\.swift:[0-9]+:[0-9]+: error: .*' | sort -u | while read -r err; do
        echo -e "  ${RED}✗${NC} $err"
    done
    echo -e "  Log: ${ARCHIVE_LOG}"
    exit 1
fi

# ── 確認 archive ──
if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}[錯誤]${NC} Archive 檔案不存在: $ARCHIVE_PATH"
    exit 1
fi
echo -e "${CYAN}[資訊]${NC} Archive: $ARCHIVE_PATH"
echo ""

if [ "$ARCHIVE_ONLY" = true ]; then
    echo -e "${GREEN}${BOLD}✓ Archive 完成（--archive-only 模式，跳過上傳）${NC}"
    echo ""
    exit 0
fi

# ── 建立 ExportOptions.plist ──
EXPORT_PLIST="$ARCHIVE_DIR/ExportOptions.plist"
cat > "$EXPORT_PLIST" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>destination</key>
    <string>upload</string>
</dict>
</plist>
PLIST

# ── 上傳 TestFlight ──
echo -e "${CYAN}[上傳]${NC} 正在上傳到 App Store Connect..."
echo -e "  （首次上傳可能需要幾分鐘）"
echo ""

UPLOAD_START=$(date +%s)

xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_PLIST" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$API_KEY_PATH" \
    -authenticationKeyID "$API_KEY_ID" \
    -authenticationKeyIssuerID "$API_ISSUER_ID" \
    2>&1 | tee -a "$ARCHIVE_LOG"

UPLOAD_END=$(date +%s)
UPLOAD_DURATION=$((UPLOAD_END - UPLOAD_START))

if grep -q "EXPORT SUCCEEDED\|Upload succeeded" "$ARCHIVE_LOG"; then
    echo ""
    echo -e "${GREEN}${BOLD}━━━ UPLOAD SUCCEEDED ━━━${NC}  (${UPLOAD_DURATION}s)"
    echo ""
    echo -e "  下一步："
    echo -e "  1. 到 ${CYAN}App Store Connect${NC} → TestFlight"
    echo -e "  2. 等待 Apple 處理（約 10-30 分鐘）"
    echo -e "  3. 處理完成後，新增測試人員"
    echo ""
    echo -e "${GREEN}${BOLD}✓ TestFlight 上傳完成${NC}"
else
    echo ""
    echo -e "${RED}${BOLD}━━━ UPLOAD FAILED ━━━${NC}"
    echo -e "  Log: ${ARCHIVE_LOG}"
    exit 1
fi

echo ""
