#!/bin/bash
# GutTracker iOS Test Script
# 執行 unit tests，顯示進度並記錄結果

set -euo pipefail

# ── 配置 ──
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="guttracker.xcodeproj"
SCHEME="guttracker"
SDK="iphonesimulator"
SIM_NAME="iPhone 17 Pro"
LOG_DIR="$PROJECT_DIR/scripts/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEST_LOG="$LOG_DIR/test_${TIMESTAMP}.log"
RESULT_LOG="$LOG_DIR/test_result_${TIMESTAMP}.log"

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
FILTER=""
VERBOSE=false
INCLUDE_UI=false
for arg in "$@"; do
    case $arg in
        --verbose) VERBOSE=true ;;
        --ui) INCLUDE_UI=true ;;
        --filter=*) FILTER="${arg#*=}" ;;
        --help|-h)
            echo "Usage: $0 [--verbose] [--ui] [--filter=TestClassName]"
            echo "  --verbose             顯示完整測試輸出"
            echo "  --ui                  包含 UI tests（預設只跑 unit tests）"
            echo "  --filter=ClassName    只跑指定的測試 class"
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
echo -e "${BOLD}  GutTracker Tests${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Scheme:      ${CYAN}$SCHEME${NC}"
echo -e "  Simulator:   ${CYAN}$SIM_NAME ($SIM_UDID)${NC}"
echo -e "  Time:        ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
if [ -n "$FILTER" ]; then
    echo -e "  Filter:      ${CYAN}$FILTER${NC}"
fi
echo ""

# ── 建構測試指令 ──
TEST_CMD=(
    xcodebuild
    -project "$PROJECT"
    -scheme "$SCHEME"
    -sdk "$SDK"
    -destination "$DESTINATION"
    -parallel-testing-enabled NO
    -disable-concurrent-destination-testing
    test
)

if [ -n "$FILTER" ]; then
    TEST_CMD+=(-only-testing:"guttrackerTests/$FILTER")
elif [ "$INCLUDE_UI" = false ]; then
    TEST_CMD+=(-only-testing:"guttrackerTests")
fi

# ── 執行測試 ──
echo -e "${CYAN}[測試]${NC} 編譯並執行測試中..."
TEST_START=$(date +%s)

"${TEST_CMD[@]}" 2>&1 | tee "$TEST_LOG" | {

    # 計數器
    pass_count=0
    fail_count=0
    skip_count=0
    current_suite=""
    building=true

    while IFS= read -r line; do
        # 編譯階段（簡化顯示）
        if $building; then
            if echo "$line" | grep -q "CompileSwift normal"; then
                file=$(echo "$line" | grep -oE '[^ ]+\.swift' | head -1 | xargs basename 2>/dev/null || true)
                if [ -n "$file" ]; then
                    printf "\r${CYAN}[編譯]${NC} %-50s" "$file"
                fi
            fi
            if echo "$line" | grep -q "Test session started"; then
                building=false
                echo ""
                echo ""
                echo -e "${CYAN}[測試]${NC} 測試開始執行"
                echo -e "${CYAN}─────────────────────────────────────${NC}"
            fi
            if echo "$line" | grep -q "BUILD FAILED"; then
                echo ""
                echo ""
                echo -e "${RED}${BOLD}━━━ BUILD FAILED ━━━${NC}"
                echo -e "  編譯失敗，無法執行測試"
                echo -e "  Log: ${TEST_LOG}"
                echo ""
                grep "error:" "$TEST_LOG" | grep -oE '[^/]+\.swift:[0-9]+:[0-9]+: error: .*' | sort -u | while read -r err; do
                    echo -e "  ${RED}✗${NC} $err"
                done
            fi
            continue
        fi

        # Test Suite 開始
        if echo "$line" | grep -q "Test Suite.*started"; then
            suite=$(echo "$line" | grep -oE "'[^']+'" | tr -d "'" | head -1)
            if [ -n "$suite" ] && [ "$suite" != "All tests" ] && [ "$suite" != "Selected tests" ]; then
                current_suite="$suite"
                echo ""
                echo -e "${BOLD}  $suite${NC}"
            fi
        fi

        # 測試通過
        if echo "$line" | grep -q "Test Case.*passed"; then
            pass_count=$((pass_count + 1))
            test_name=$(echo "$line" | grep -oE "'-\[.*\]'" | tr -d "'" | sed 's/-\[.*\s//' | sed 's/\]//')
            duration=$(echo "$line" | grep -oE '\([0-9]+\.[0-9]+ seconds\)')
            echo -e "    ${GREEN}✓${NC} $test_name ${CYAN}$duration${NC}"
            echo "PASS: $test_name $duration" >> "$RESULT_LOG"
        fi

        # 測試失敗
        if echo "$line" | grep -q "Test Case.*failed"; then
            fail_count=$((fail_count + 1))
            test_name=$(echo "$line" | grep -oE "'-\[.*\]'" | tr -d "'" | sed 's/-\[.*\s//' | sed 's/\]//')
            duration=$(echo "$line" | grep -oE '\([0-9]+\.[0-9]+ seconds\)')
            echo -e "    ${RED}✗${NC} $test_name ${CYAN}$duration${NC}"
            echo "FAIL: $test_name $duration" >> "$RESULT_LOG"
        fi

        # 測試跳過
        if echo "$line" | grep -q "Test Case.*skipped"; then
            skip_count=$((skip_count + 1))
            test_name=$(echo "$line" | grep -oE "'-\[.*\]'" | tr -d "'" | sed 's/-\[.*\s//' | sed 's/\]//')
            echo -e "    ${YELLOW}○${NC} $test_name (skipped)"
            echo "SKIP: $test_name" >> "$RESULT_LOG"
        fi

        # 失敗詳情
        if echo "$line" | grep -qE ".*\.swift:[0-9]+.*failed"; then
            if $VERBOSE; then
                echo -e "      ${RED}↳${NC} $line"
            fi
            echo "DETAIL: $line" >> "$RESULT_LOG"
        fi

        # 測試結束
        if echo "$line" | grep -q "TEST.*SUCCEEDED\|TEST.*FAILED\|Executed.*test.*with"; then
            TEST_END=$(date +%s)
            DURATION=$((TEST_END - TEST_START))
            total=$((pass_count + fail_count + skip_count))

            echo ""
            echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

            if [ "$fail_count" -eq 0 ]; then
                echo -e "${GREEN}${BOLD}  ALL TESTS PASSED${NC}"
            else
                echo -e "${RED}${BOLD}  TESTS FAILED${NC}"
            fi

            echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "  ${GREEN}✓ 通過: $pass_count${NC}"
            echo -e "  ${RED}✗ 失敗: $fail_count${NC}"
            if [ "$skip_count" -gt 0 ]; then
                echo -e "  ${YELLOW}○ 跳過: $skip_count${NC}"
            fi
            echo -e "  總計:   $total"
            echo -e "  耗時:   ${DURATION}s"
            echo ""
            echo -e "  Log:    ${TEST_LOG}"
            echo -e "  Result: ${RESULT_LOG}"
            echo ""

            # 寫入摘要
            {
                echo "━━━ Test Summary ━━━"
                echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
                echo "Pass: $pass_count"
                echo "Fail: $fail_count"
                echo "Skip: $skip_count"
                echo "Total: $total"
                echo "Duration: ${DURATION}s"
            } >> "$RESULT_LOG"
        fi
    done
}
