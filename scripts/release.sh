#!/bin/bash
# GutTracker — Release 版編譯並安裝到 Gil-Golden (iPhone 16 Pro)

set -euo pipefail

# ── 配置 ──
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="guttracker"
DEVICE_NAME="Gil-Golden"
DEVICE_ID="A23495EF-156D-5726-8391-01E2B18B8B90"
XCODE_DEVICE_ID="00008140-00146D6A2610801C"
BUNDLE_ID="com.gilko.guttracker"
LOG_DIR="$PROJECT_DIR/scripts/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_LOG="$LOG_DIR/release_${TIMESTAMP}.log"

# ── 顏色 ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

mkdir -p "$LOG_DIR"

# ── 參數 ──
CLEAN=false
LAUNCH=false
for arg in "$@"; do
    case $arg in
        --clean) CLEAN=true ;;
        --launch) LAUNCH=true ;;
        --help|-h)
            echo "Usage: $0 [--clean] [--launch]"
            echo "  --clean    清除 DerivedData 後重新編譯"
            echo "  --launch   安裝後啟動 app"
            exit 0
            ;;
    esac
done

cd "$PROJECT_DIR"

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  GutTracker RELEASE → $DEVICE_NAME${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Scheme:  ${CYAN}$SCHEME${NC}"
echo -e "  Config:  ${YELLOW}Release${NC}"
echo -e "  Device:  ${CYAN}$DEVICE_NAME${NC}"
echo -e "  Time:    ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# ── 檢查裝置連線 ──
echo -e "${CYAN}[裝置]${NC} 檢查 $DEVICE_NAME 連線..."
DEVICE_LIST=$(xcrun devicectl list devices 2>&1 || true)
if ! echo "$DEVICE_LIST" | grep -q "$DEVICE_NAME.*connected"; then
    echo -e "${RED}[錯誤]${NC} $DEVICE_NAME 未連線"
    echo -e "  請確認 iPhone 已透過 USB 或 WiFi 連接"
    exit 1
fi
echo -e "${GREEN}[裝置]${NC} $DEVICE_NAME 已連線"
echo ""

# ── Clean（可選）──
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}[清除]${NC} 刪除 DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/guttracker-*
    echo -e "${GREEN}[清除]${NC} 完成"
    echo ""
fi

# ── 編譯 Release ──
echo -e "${CYAN}[編譯]${NC} 開始 Release 編譯..."
BUILD_START=$(date +%s)

xcodebuild \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "platform=iOS,id=$XCODE_DEVICE_ID" \
    build \
    2>&1 | tee "$BUILD_LOG" | while IFS= read -r line; do
    if echo "$line" | grep -q "CompileSwift normal"; then
        file=$(echo "$line" | grep -oE '[^ ]+\.swift' | head -1 | xargs basename 2>/dev/null || true)
        if [ -n "$file" ]; then
            printf "\r  ${CYAN}⚙${NC}  %-45s" "$file"
        fi
    fi
    if echo "$line" | grep -q "BUILD SUCCEEDED\|BUILD FAILED"; then
        echo ""
    fi
done

BUILD_END=$(date +%s)
DURATION=$((BUILD_END - BUILD_START))

# 檢查結果
if grep -q "BUILD FAILED" "$BUILD_LOG"; then
    echo -e "${RED}${BOLD}━━━ BUILD FAILED ━━━${NC}  (${DURATION}s)"
    echo ""
    grep "error:" "$BUILD_LOG" | grep -oE '[^/]+\.swift:[0-9]+:[0-9]+: error: .*' | sort -u | while read -r err; do
        echo -e "  ${RED}✗${NC} $err"
    done
    echo ""
    echo -e "  Log: ${BUILD_LOG}"
    exit 1
fi

echo -e "${GREEN}${BOLD}━━━ RELEASE BUILD SUCCEEDED ━━━${NC}  (${DURATION}s)"
echo ""

# ── 找到 Release .app ──
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/guttracker-*/Build/Products/Release-iphoneos -name "guttracker.app" -maxdepth 1 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
    echo -e "${RED}[錯誤]${NC} 找不到 Release 編譯產出的 .app"
    exit 1
fi
echo -e "${CYAN}[資訊]${NC} App: $APP_PATH"

# ── 安裝 ──
echo -e "${CYAN}[安裝]${NC} 安裝到 $DEVICE_NAME..."
INSTALL_OUTPUT=$(xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH" 2>&1)

if echo "$INSTALL_OUTPUT" | grep -q "App installed"; then
    echo -e "${GREEN}[安裝]${NC} 安裝成功！"
else
    echo -e "${RED}[錯誤]${NC} 安裝失敗"
    echo "$INSTALL_OUTPUT"
    exit 1
fi

# ── 啟動（可選）──
if [ "$LAUNCH" = true ]; then
    echo ""
    echo -e "${CYAN}[啟動]${NC} 啟動 app..."
    if xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null; then
        echo -e "${GREEN}[啟動]${NC} 已啟動"
    else
        echo -e "${YELLOW}[啟動]${NC} 無法啟動（裝置可能鎖定中，請手動開啟 app）"
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}✓ Release 部署完成${NC}"
echo ""
