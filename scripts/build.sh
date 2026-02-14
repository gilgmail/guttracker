#!/bin/bash
# GutTracker iOS Build Script
# 編譯 iOS app，顯示進度，過濾錯誤訊息並記錄

set -euo pipefail

# ── 配置 ──
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="guttracker.xcodeproj"
SCHEME="guttracker"
SDK="iphonesimulator"
SIM_NAME="iPhone 17 Pro"
LOG_DIR="$PROJECT_DIR/scripts/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_LOG="$LOG_DIR/build_${TIMESTAMP}.log"
ERROR_LOG="$LOG_DIR/build_errors_${TIMESTAMP}.log"

# ── 顏色 ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── 建立 log 目錄 ──
mkdir -p "$LOG_DIR"

# ── 參數 ──
CLEAN=false
VERBOSE=false
for arg in "$@"; do
    case $arg in
        --clean) CLEAN=true ;;
        --verbose) VERBOSE=true ;;
        --help|-h)
            echo "Usage: $0 [--clean] [--verbose]"
            echo "  --clean    清除 DerivedData 後重新編譯"
            echo "  --verbose  顯示完整編譯輸出"
            exit 0
            ;;
    esac
done

cd "$PROJECT_DIR"

# ── 模擬器管理（限制同時只有一個）──
get_or_boot_simulator() {
    local booted_udid
    booted_udid=$(xcrun simctl list devices booted -j 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('state') == 'Booted':
            print(d['udid'])
            sys.exit(0)
" 2>/dev/null || true)

    if [ -n "$booted_udid" ]; then
        echo "$booted_udid"
        return 0
    fi

    # 找到目標模擬器 UDID
    local target_udid
    target_udid=$(xcrun simctl list devices available -j 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('name') == '$SIM_NAME' and d.get('isAvailable', False):
            print(d['udid'])
            sys.exit(0)
" 2>/dev/null || true)

    if [ -z "$target_udid" ]; then
        echo ""
        return 1
    fi

    xcrun simctl boot "$target_udid" 2>/dev/null || true
    echo "$target_udid"
}

SIM_UDID=$(get_or_boot_simulator)
if [ -z "$SIM_UDID" ]; then
    echo -e "${RED}[錯誤]${NC} 找不到模擬器: $SIM_NAME"
    exit 1
fi
DESTINATION="id=$SIM_UDID"

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  GutTracker Build${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Scheme:      ${CYAN}$SCHEME${NC}"
echo -e "  Simulator:   ${CYAN}$SIM_NAME ($SIM_UDID)${NC}"
echo -e "  Time:        ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# ── Clean（可選）──
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}[清除]${NC} 刪除 DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/guttracker-*
    echo -e "${GREEN}[清除]${NC} 完成"
    echo ""
fi

# ── 編譯 ──
echo -e "${CYAN}[編譯]${NC} 開始編譯..."
BUILD_START=$(date +%s)

xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -sdk "$SDK" \
    -destination "$DESTINATION" \
    -parallel-testing-enabled NO \
    build \
    2>&1 | tee "$BUILD_LOG" | {

    # 計數器
    compile_count=0
    link_count=0
    error_count=0
    warning_count=0
    current_file=""

    while IFS= read -r line; do
        # 編譯 Swift 檔案
        if echo "$line" | grep -q "CompileSwift normal"; then
            file=$(echo "$line" | grep -oE '[^ ]+\.swift' | head -1 | xargs basename 2>/dev/null || true)
            if [ -n "$file" ] && [ "$file" != "$current_file" ]; then
                current_file="$file"
                compile_count=$((compile_count + 1))
                printf "\r${CYAN}[編譯]${NC} %-40s [%d files]" "$file" "$compile_count"
            fi
        fi

        # 連結
        if echo "$line" | grep -q "^Ld "; then
            link_count=$((link_count + 1))
            printf "\r${CYAN}[連結]${NC} %-40s          \n" "Linking..."
        fi

        # 錯誤
        if echo "$line" | grep -q "error:"; then
            error_count=$((error_count + 1))
            echo "$line" >> "$ERROR_LOG"
            if $VERBOSE; then
                echo ""
                echo -e "${RED}[錯誤]${NC} $line"
            fi
        fi

        # 警告
        if echo "$line" | grep -q "warning:"; then
            warning_count=$((warning_count + 1))
            if $VERBOSE; then
                echo ""
                echo -e "${YELLOW}[警告]${NC} $line"
            fi
        fi

        # BUILD SUCCEEDED / FAILED
        if echo "$line" | grep -q "BUILD SUCCEEDED"; then
            BUILD_END=$(date +%s)
            DURATION=$((BUILD_END - BUILD_START))
            echo ""
            echo ""
            echo -e "${GREEN}${BOLD}━━━ BUILD SUCCEEDED ━━━${NC}"
            echo -e "  編譯檔案: ${compile_count}"
            echo -e "  警告:     ${warning_count}"
            echo -e "  耗時:     ${DURATION}s"
            echo -e "  Log:      ${BUILD_LOG}"
            echo ""
        fi

        if echo "$line" | grep -q "BUILD FAILED"; then
            BUILD_END=$(date +%s)
            DURATION=$((BUILD_END - BUILD_START))
            echo ""
            echo ""
            echo -e "${RED}${BOLD}━━━ BUILD FAILED ━━━${NC}"
            echo -e "  錯誤數: ${error_count}"
            echo -e "  警告數: ${warning_count}"
            echo -e "  耗時:   ${DURATION}s"
            echo ""

            # 顯示錯誤摘要
            if [ -f "$ERROR_LOG" ]; then
                echo -e "${RED}${BOLD}錯誤摘要:${NC}"
                echo -e "${RED}─────────────────────────────────${NC}"
                grep "error:" "$ERROR_LOG" | grep -oE '[^/]+\.swift:[0-9]+:[0-9]+: error: .*' | sort -u | while read -r err; do
                    echo -e "  ${RED}✗${NC} $err"
                done
                echo ""
                echo -e "  完整錯誤 log: ${ERROR_LOG}"
            fi
        fi
    done
}

# ── 清理空的 error log ──
if [ -f "$ERROR_LOG" ] && [ ! -s "$ERROR_LOG" ]; then
    rm -f "$ERROR_LOG"
fi
