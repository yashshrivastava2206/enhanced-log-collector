#!/bin/bash
################################################################################
# Log Rotation Tests
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOG_SCRIPT="${REPO_DIR}/bin/logCollector.sh"
TEST_OUTPUT="${SCRIPT_DIR}/output/rotation"

# Setup
mkdir -p "$TEST_OUTPUT"
export BASE_LOG_DIR="$TEST_OUTPUT"
export MAX_LOG_SIZE_MB=1  # Small size for testing

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

test_result() {
    if [[ $1 -eq 0 ]]; then
        echo -e "${GREEN}✓ $2${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ $2${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 1: Create log file
for i in {1..100}; do
    "$LOG_SCRIPT" 'test-rotation' 'test.sh' 'INFO' "Message $i with lots of padding to increase size xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" 2>/dev/null
done
[[ -f "${TEST_OUTPUT}/test-rotation/current/test.sh_$(date +%Y-%m-%d).log" ]]
test_result $? "Log file created"

# Test 2: Generate large enough file
LOGFILE="${TEST_OUTPUT}/test-rotation/current/test.sh_$(date +%Y-%m-%d).log"
for i in {1..5000}; do
    echo "Large log entry with padding xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx $i" >> "$LOGFILE"
done

SIZE=$(stat -f%z "$LOGFILE" 2>/dev/null || stat -c%s "$LOGFILE" 2>/dev/null)
SIZE_MB=$((SIZE / 1024 / 1024))
[[ $SIZE_MB -ge 1 ]]
test_result $? "Generated file > 1MB (${SIZE_MB}MB)"

# Test 3: Trigger rotation with new log
"$LOG_SCRIPT" 'test-rotation' 'test.sh' 'INFO' 'After rotation' 2>/dev/null

# Check if files were rotated to archive
sleep 2
ARCHIVE_COUNT=$(find "${TEST_OUTPUT}/test-rotation/archive" -name "*.log" -o -name "*.log.gz" 2>/dev/null | wc -l)
[[ $ARCHIVE_COUNT -gt 0 ]]
test_result $? "Log rotated to archive"

# Cleanup
rm -rf "$TEST_OUTPUT"

echo ""
echo "Rotation Tests: $TESTS_PASSED passed, $TESTS_FAILED failed"
[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
